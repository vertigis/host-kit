#!/bin/bash

mkdir -p /data

delay=15s
while true; do
  sleep $delay

  if [ $delay = 15s ]; then
    delay=1d
  fi

  if [ -n "$KINIT_KEYTAB_FILE" ]; then
    kinit -k -t "$KINIT_KEYTAB_FILE" "$KINIT_PRINCIPAL" > /dev/null
  fi

  if [ -n "$KINIT_SECRET_FILE" ]; then
    cat "$KINIT_SECRET_FILE" | kinit "$KINIT_PRINCIPAL" > /dev/null
  fi

  url="$CERTSRV_URL/certsrv/certcarc.asp"
  echo "curl: $url"

  curl -fsSL --negotiate "$url" > /tmp/page.html
  text=$(cat /tmp/page.html | pup "option:first-of-type text{}")
  ridx=$(echo "$text" | sed -E "N;s/.*\((\d+)).*/\1/")

  url="$CERTSRV_URL/certsrv/certnew.p7b?ReqID=CACert&Renewal=$ridx&Enc=b64"
  echo "curl: $url"

  curl -fsSL --negotiate "$url" > /tmp/certs.pem
  hash=$(openssl dgst -sha256 /tmp/certs.pem | sed -E 's/^.*? +//')
  echo "hash: $hash"
  openssl pkcs7 -in /tmp/certs.pem -print_certs > /data/certs-$hash.tmp
  mv /data/certs-$hash.tmp /data/certs-$hash.pem
done
