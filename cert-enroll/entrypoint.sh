#!/bin/bash
set -e
trap exit TERM INT

rm -rf /tmp/* /run/dbus/*
ln -sf "$CERT_DIR/cert" /tmp/result
mkdir -p /run/dbus "$CERT_DIR/cert" "$CERT_DIR/certmonger"

export CERTMONGER_CAS_DIR="$CERT_DIR/certmonger/cas"
export CERTMONGER_REQUESTS_DIR="$CERT_DIR/certmonger/requests"

dbus-daemon --system --fork --nopidfile
certmonger -f -S

[ -f "$CERT_DIR/certmonger/.san" ] && san=$(cat $CERT_DIR/certmonger/.san)

if [ "$CERT_SAN" != "$san" ]; then
    args=()
    for san in $CERT_SAN; do
        args+=(-D "$san")
    done

    echo NAME: "$CERT_SUBJECT"
    echo SANS: "${args[@]}"

    rm -rf "$CERT_DIR/cert/certmonger"
    mkdir -p "$CERT_DIR/certmonger"
    echo "$CERT_SAN" > "$CERT_DIR/certmonger/.san"

    getcert add-ca -c "$CERT_CA" -e /ca-helper.sh
    getcert request \
        -c "$CERT_CA" \
        -f "$CERT_DIR/cert/cert.pem" \
        -k "$CERT_DIR/cert/privkey.pem" \
        -N "$CERT_SUBJECT" "${args[@]}" \
        -u digitalSignature \
        -u keyEncipherment \
        -U id-kp-serverAuth
fi

delay=1
while true; do
    sleep $delay &
    wait

    getcert list
    delay=1h
done
