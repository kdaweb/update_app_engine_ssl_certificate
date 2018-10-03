# update_app_engine_ssl_certificate

## Overview
Google App Engine allows for the mapping of custom domains with
SSL certificates; these certificates can be updated using the 'glcloud'
tool.  LetsEncrypt provides free SSL certificates that last three months;
these certificates can be generated / renewed using the 'certbot' tool.
This script connects the two -- given a Google Cloud account and a
domain name, generate / renew the certificate using LetsEncrypt,
RSA encode the private key, and update Google App Engine with the
new certificate.

## Usage
Usage: update_app_engine_ssl_certificate.bash [ -a account] [ -c challenge ] [ -p project ] domain[...]

  -a : Google Cloud service account to use
  -c : LetsEncrypt challenge to use
  -p : Google Cloud project to use

## Examples

```sh
./update_app_engine_ssl_certificate.bash -a username@domain.tld -c google -p my-project-123 domain.tld
```
