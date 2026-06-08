#!/bin/bash
shopt -s nullglob globstar
mkdir -p /data

delay=30s
while true; do
  sleep $delay

  for file in /data/request-*/nickname.txt; do
    name="$(cat "$file")"
    dir="${file%/*}"

    if [ "$name" != "$CERTSRV_CA" ]; then
      continue
    fi

    if [ -f "$dir/response.html" ]; then
      continue
    fi

    if [ -n "$KINIT_KEYTAB_FILE" ]; then
      kinit -k -t "$KINIT_KEYTAB_FILE" "$KINIT_PRINCIPAL" > /dev/null
    fi

    if [ -n "$KINIT_SECRET_FILE" ]; then
      cat "$KINIT_SECRET_FILE" | kinit "$KINIT_PRINCIPAL" > /dev/null
    fi    

    url="$CERTSRV_URL/certsrv/certfnsh.asp"
    echo "curl: $url"

    curl -fsSL --negotiate "$url" \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode "Mode=newreq" \
      --data-urlencode "CertRequest@$dir/csr.pem" \
      --data-urlencode "CertAttrib=CertificateTemplate:WebServer" \
      --data-urlencode "FriendlyType=Saved-Request Certificate $(date -u)" \
      --data-urlencode "ThumbPrint=" \
      --data-urlencode "TargetStoreFlags=0" \
      --data-urlencode "SaveCert=yes" > "$dir/response.html"

    link="$(cat "$dir/response.html" | pup "a attr{href}" | grep "p7b.*b64" | sed -E "s/amp;//")"
    url="$CERTSRV_URL/certsrv/$link"
    echo "curl: $url"
    curl -fsSL --negotiate "$url" > "$dir/cert.pem"
  done
done
