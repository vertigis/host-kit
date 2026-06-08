#!/bin/bash
set -e

passwd_file=~/.admin-password
[ -t 0 ] && read -rsp "Password: " PASSWORD
[ -t 0 ] && echo "$PASSWORD" > "$passwd_file"
[ -t 0 ] && exit 0

[ -f "$passwd_file" ] || makepasswd --chars 32 > "$passwd_file"
[ -z "$PASSWORD" ] && export PASSWORD=$(cat "$passwd_file")

/usr/bin/entrypoint.sh /.code-workspace \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --disable-telemetry \
    --disable-workspace-trust > /dev/null 2> /dev/null &

trap exit INT TERM
wait
