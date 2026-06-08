#!/bin/bash
shopt -s nullglob globstar

delay=30s
while true; do
  cd /
  mkdir -p /data/ca-certificates
  mkdir -p /usr/local/share/ca-certificates  
  rsync -rlc --delete /data/ca-certificates/ /usr/local/share/ca-certificates/

  for file in /opt/*.pem; do
    echo extract-ca-certs: "$file"
    extract-ca-certs < "$file"
  done

  update-ca-certificates 2> /dev/null

  for url in $CHECK_URLS; do
    echo extract-ca-certs: "$url"
    curl -fsSL "$url" | extract-ca-certs
  done

  update-ca-certificates 2> /dev/null

  rm -rf /tmp/certs
  mkdir -p /tmp/certs/ca-certificates
  cd /tmp/certs

  extract-ca-certs . < /etc/ssl/certs/ca-certificates.crt
  cd /tmp/certs
  openssl rehash .
  cp /etc/ssl/certs/ca-certificates.crt .
  rsync -rlc /usr/local/share/ca-certificates/ ca-certificates/
  rsync -rlc --delete --itemize-changes ./ /data/

  sleep $delay
  
  if [ $delay = 30s ]; then
    delay=1d
  fi
done
