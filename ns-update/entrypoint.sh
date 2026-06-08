#!/bin/bash

zone=${DNS_HOST#*.}
last=""

while true; do
    sleep 5

    addrs="$(ip -4 -o addr show dev eth0 | awk '{print $4}' | cut -d/ -f1)"
    now=$(date -u +%F)

    updates=(
        "; $now"
        "server $DNS_SERVER"
        "zone $zone"
        "update delete $DNS_HOST A"
    )

    for addr in $addrs; do
        updates+=("update add $DNS_HOST 300 A $addr")
    done

    updates+=("send")
    current=$(printf "%s\n" "${updates[@]}")

    if [ -z "$addrs" ]; then
        current=""
    fi

    if [ "$current" = "$last" ]; then
        current=""
    fi

    if [ -n "$current" ]; then
        echo "$current"        
        echo "$current" > /tmp/state
        
        if [ -n "$KINIT_KEYTAB_FILE" ]; then
            echo "; kinit"
            kinit -k -t "$KINIT_KEYTAB_FILE" "$KINIT_PRINCIPAL" > /dev/null
            echo "; nsupdate -g"
            nsupdate -g /tmp/state
        fi

        if [ -n "$KINIT_SECRET_FILE" ]; then
            echo "; kinit"
            cat "$KINIT_SECRET_FILE" | kinit "$KINIT_PRINCIPAL" > /dev/null
            echo "; nsupdate -g"
            nsupdate -g /tmp/state
        fi

        if [ -n "$NSUPDATE_KEY_FILE" ]; then
            echo "; nsupdate -k"
            nsupdate -k "$NSUPDATE_KEY_FILE" /tmp/state
        fi

        if [ -n "$NSUPDATE_SECRET_FILE" ]; then
            echo "; nsupdate -y"
            NSUPDATE_SECRET=$(cat "$NSUPDATE_SECRET_FILE")
            nsupdate -y "$NSUPDATE_SECRET" /tmp/state
        fi

        if [ "$?" -ne 0 ]; then
            echo "; fail"
            last=""
        else
            echo "; done"
            last="$current"
        fi
    fi
done
