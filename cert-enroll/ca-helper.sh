#!/bin/bash

die_unconfigured() {
    exit 4
}

die_rejected() {
    exit 2
}

die_unreachable() {
    exit 3
}

issued() {
    rm -rf "$DIR"
    exit 0
}

wait_more() {
    echo 15
    echo $CERTMONGER_CA_COOKIE
    exit 5
}

submit() {
    export CERTMONGER_CA_COOKIE="request-$(pwgen 32 1)"
    export DIR="/data/$CERTMONGER_CA_COOKIE"
    mkdir -p "$DIR"
    echo "$CERTMONGER_CSR" > "$DIR/csr.pem"
    echo "$CERTMONGER_CA_NICKNAME" > "$DIR/nickname.txt"

    wait_more
}

poll() {
    export DIR="/data/$CERTMONGER_CA_COOKIE"

    if [ ! -d "$DIR" ]; then
        die_rejected
    fi

    in_file="$DIR/cert.pem"
    result_file=/tmp/result/fullchain.pem

    if openssl pkcs7 -in "$in_file" -out "$DIR/fullchain.pem" -print_certs 2> /dev/null; then
        cp "$DIR/fullchain.pem" "$result_file"
        cat "$in_file"
        issued
    fi

    if openssl x509 -in "$in_file" -noout 2> /dev/null; then
        cp "$in_file" "$result_file"
        cat "$in_file"
        issued
    fi

    wait_more
}

if [ "$CERTMONGER_OPERATION" = "SUBMIT" ]; then
    submit
fi

if [ "$CERTMONGER_OPERATION" = "POLL" ]; then
    poll
fi

die_unconfigured
