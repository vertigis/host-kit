## Welcome to VertiGIS Studio for Containers

### Simple
Caddy + Studio with manual TLS. Uses a static IP/DNS on the host — no dedicated network interface required.
- [Compose](./simple/docker-compose.yml)
- [Caddyfile](./simple/Caddyfile)

### Recommended
Caddy with a dedicated macvlan network interface, internal CA trust, and automatic certificate management via your organization's ACME server.
- [Compose](./recommended/docker-compose.yml)
- [Caddyfile](./recommended/Caddyfile)

### Advanced
Full stack: DHCP-assigned IP, automatic DNS registration, Windows CERTSRV certificate enrollment, and egress firewall.
- [Compose](./advanced/docker-compose.yml)
- [Caddyfile](./advanced/Caddyfile)
