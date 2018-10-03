#!/bin/bash

## @file
## @author Wes Dean <info@kdaweb.com>
## @brief update SSL certificates on Google App Engine using LetsEncrypt
## @details
## Google App Engine allows for the mapping of custom domains with
## SSL certificates; these certificates can be updated using the 'glcloud'
## tool.  LetsEncrypt provides free SSL certificates that last three months;
## these certificates can be generated / renewed using the 'certbot' tool.
## This script connects the two -- given a Google Cloud account and a
## domain name, generate / renew the certificate using LetsEncrypt,
## RSA encode the private key, and update Google App Engine with the
## new certificate.

CERTBOT="${CERTBOT:-certbot}"
ECHO="${ECHO:-echo}"
GCLOUD="${GCLOUD:-gcloud}"
HEAD="${HEAD:-head}"
JQ="${JQ:-jq}"
LOGGER="${LOGGER:-logger}"
OPENSSL="${OPENSSL:-openssl}"

# defaults
DEFAULT_ACCOUNT=""
DEFAULT_CHALLENGE="route53"
DEFAULT_PROJECT=""
DEFAULT_DISPLAY_HELP="1"

account="${DEFAULT_ACCOUNT}"
challenge="${DEFAULT_CHALLENGE}"
project="${DEFAULT_PROJECT}"
display_help="${DEFAULT_DISPLAY_HELP}"

while getopts "a:c:p:h" option; do
  case $option in
    a ) account="${OPTARG}" ;;
    c ) challenge="${OPTARG}" ;;
    p ) project="${OPTARG}" ;;
    h ) display_help="$TRUE_VALUE" ;;
    * ) warn "Invalid option '${option}'" ; display_help="0" ;;
  esac
done

shift $((OPTIND - 1))

if [ "${display_help}" ] ; then
  ${ECHO} "Usage: $0 [ -a account] [ -c challenge ] [ -p project ] domain[...]"
  ${ECHO} ""
  ${ECHO} "This tool automates the updating of SSL certificates on Google App Engine"
  ${ECHO} "using certificates from LetsEncrypt."
  ${ECHO} ""
  ${ECHO} "-a : Google Cloud service account to use (default: ${DEFAULT_ACCOUNT})"
  ${ECHO} "-c : LetsEncrypt challenge to use (default: ${DEFAULT_CHALLENGE})"
  ${ECHO} "-p : Google Cloud project to use (default: ${DEFAULT_PROJECT})"
  ${ECHO} "-h : this help message"
  ${ECHO} ""
  exit 1
fi

if [ "${account}" == "" ] ; then
	account_string=""
else
	account_string="--account ${account}"
fi

if [ "${project}" == "" ] ; then
	  project_string=""
else
	project_string="--project ${project}"
fi

for domain in "$@" ; do
	# capture certificate id
	certificate_id="$(${GCLOUD} app ssl-certificates list \
	"${project_string}" \
	"${account_string}" \
	--format=json | \
	${JQ} -r ".[] | select(.domainNames[]='${domain}') .id" | ${HEAD} -1)"

  if [ "${certificate_id}" == "" ] ; then
  	${LOGGER} -s "couldn't find certificate id for ${domain}"
  else
		# renew certificate
		${CERTBOT} certonly -n "--${challenge}" -d "${domain}"

		# create RSA-encoded private key
		${OPENSSL} rsa -inform pem -outform pem \
		-in /etc/letsencrypt/live/"${domain}"/privkey.pem \
		-out -in /etc/letsencrypt/live/"${domain}"/rsaprivkey.pem

		# update SSL certificate at App Engine
		${GCLOUD} app ssl-certificates update "${certificate_id}" \
		--certificate /etc/letsencrypt/live/"${domain}"/fullchain.pem \
		--private-key /etc/letsencrypt/live/"${domain}"/rsaprivkey.pem \
	  "${project_string}" \
		"${account_string}"
  fi
done
