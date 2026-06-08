#!/bin/bash
set -e

rm -rf /tmp/* /run/dbus/* /var/run/avahi-daemon/*
mkdir -p /run/dbus

# ingress firewall
iptables -F INPUT
iptables -P INPUT ACCEPT
iptables -A INPUT -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 80  -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -j DROP

# setup dhcpcd
ip addr flush dev eth0
dbus-daemon --system --fork --nopidfile
avahi-daemon --daemonize --no-chroot
exec dhcpcd --nohook resolv.conf -B -L -4 -h "$DHCP_HOSTNAME" eth0
