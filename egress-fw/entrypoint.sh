#!/bin/bash
set -e

iptables -F OUTPUT
iptables -P OUTPUT ACCEPT
iptables -A OUTPUT -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
for cidr in $ALLOW_CIDRS; do
    iptables -A OUTPUT -o eth0 -d "$cidr" -j ACCEPT
done

iptables -A OUTPUT -o eth0 -p tcp -j DROP

sleep infinity &

trap TERM INT
wait
