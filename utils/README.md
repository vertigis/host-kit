# Utility Containers

## config-editor
Useful when you want to manage your container stacks using a browser:
- Edit compose files and configuration.
- Inspect and manage containers as well as files.
- Browse example content from this repository.
- Manage the host Docker Engine from a browser session
- View logs pertaining to containers.

### Usage
```sh
# initial setup
sudo mkdir -p /opt/stacks
mkdir -p host-kit
git clone --depth 1 https://github.com/vertigis/host-kit .

# set the password
docker compose run --rm editor

# start
docker compose up -d

# update: pull repo and images
git pull
docker compose pull
docker compose up -d
```

### Environment Variables

| Variable | Description | Default |
|---|---|---|
| `PASSWORD` | Password for the web interface | Auto-generated (32 random characters) |

### Volumes

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| `/opt/stacks` | host bind | `/opt/stacks` | Gives the browser editor direct read/write access to the compose files and configs managed on the host. Without this, you would have no way to edit or deploy your stacks from the UI. |
| `/var/run/docker.sock` | host socket | `/var/run/docker.sock` | Allows the UI to manage the host Docker Engine — start/stop containers, tail logs, inspect images. Required for any Docker operation from the browser. |
| `home` | named volume | `/root` | Persists the generated admin password, code-server user settings, and installed extensions across container restarts. Without this, every restart regenerates a new random password and loses editor state. |

### Links
- [Launch Editor](https://localhost:8080/)

### Compose Example
```yaml
services:
  editor:
    image: ghcr.io/vertigis/host-kit/config-editor:latest
    ports:
      - 127.0.0.1:8080:8080
    volumes:
      - /opt/stacks:/opt/stacks
      - /var/run/docker.sock:/var/run/docker.sock
      - home:/root
    restart: unless-stopped

volumes:
  home: {}
```


## license-tool
Useful when you need to look up your VertiGIS Account ID:
- Authenticates with the VertiGIS identity service via a browser-based OAuth flow.
- Prints your Account ID to stdout and exits.

### Usage
```sh
docker run --rm -p 7780:7780 ghcr.io/vertigis/host-kit/license-tool:latest
```

Open [http://localhost:7780/](http://localhost:7780/) in a browser. The container redirects you to the VertiGIS identity service, waits for the callback, prints your Account ID, and exits.

> **Note:** If your Docker host is remote, enable the `LocalForward` for port 7780 in your SSH config before running this — see the commented line in the [SSH configuration section](../README.md#modify-your-ssh-configuration-sshconfig).


## ca-enroll
Useful when you need to assemble and distribute a CA root trust bundle:
- Consume CA trust anchors using Cert/PEM files.
- Consume CA trust anchors using Cert/PEM distribution points.
- Offers coherent CA trust material for other containers.

### Environment Variables

| Variable | Description |
|---|---|
| `CHECK_URLS` | Space-separated list of URLs to fetch additional CA certificates from (optional) |

### Volumes

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| `ca_dist` | named volume (rw) | `/data` | Output volume where the assembled, deduplicated CA bundle is written. Other containers (`certsrv-ca`, `certsrv-submit`) mount this read-only to get trusted CA certificates for validating HTTPS connections. |
| `ca_root` | named volume (ro) | `/opt/root` | Input volume where other containers (e.g. `certsrv-ca`) drop raw CA certificate files. `ca-enroll` reads from here to incorporate them into the distributed bundle. |
| `ca_bundle` config | Docker config (ro) | `/opt/ca_bundle.pem` | Seed PEM containing the initial set of CA certificates to include. Lets you pre-populate the bundle with org-specific roots without rebuilding the image. |

### Compose Example
```yaml
services:
  ca-enroll:
    image: ghcr.io/vertigis/host-kit/ca-enroll:latest
    environment:
      # additional distribution lists to check
      CHECK_URLS: >
        https://pki.example.local/roots.pem
        https://pki.example.local/extra-roots.pem
    volumes:
      - ca_dist:/data
      - ca_root:/opt/root:ro
    configs:
      # initial distribution list
      - source: ca_bundle
        target: /opt/ca_bundle.pem
    restart: unless-stopped

volumes:
  ca_dist: {}
  ca_root: {}

configs:
  ca_bundle:
    content: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
```


## certsrv-ca
Useful when your CA is a Windows Active Directory Certificate Services (CERTSRV) server:
- Fetches the CA certificate chain from the CERTSRV web enrollment interface.
- Outputs PEM files to a shared volume consumable by `ca-enroll`.
- Uses Kerberos for authentication against the CERTSRV endpoint.

### Environment Variables

| Variable | Description | Auth Path |
|---|---|---|
| `CERTSRV_URL` | Base URL to the Windows CERTSRV web enrollment interface | — |
| `KINIT_PRINCIPAL` | Kerberos principal (`user@REALM`) | Kerberos |
| `KINIT_KEYTAB_FILE` | Path to Kerberos keytab file | Kerberos keytab |
| `KINIT_SECRET_FILE` | Path to file containing Kerberos password | Kerberos password |

Set `KINIT_PRINCIPAL` with either `KINIT_KEYTAB_FILE` (keytab) or `KINIT_SECRET_FILE` (password) — credentials provided by IT either way. Keytab is preferred for production; password is shown in examples for familiarity. Ask your AD team which format they can issue.

### Volumes

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| `ca_root` | named volume (rw) | `/data` | Output volume where downloaded CA certificates are written as PEM files. `ca-enroll` reads from this volume to assemble the distributed trust bundle. |
| `ca_dist` | named volume (ro) | `/etc/ssl/certs` | Read-only CA bundle from `ca-enroll`, used to validate HTTPS connections to the CERTSRV server itself. Without this, `curl` cannot verify the server's TLS certificate when the CA is not publicly trusted. |

### Compose Example
```yaml
services:
  certsrv-ca:
    image: ghcr.io/vertigis/host-kit/certsrv-ca:latest
    environment:
      # base URL to Windows CERTSRV
      CERTSRV_URL: https://ca.contoso.com
      # kerberos service/user authentication
      KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      KINIT_SECRET_FILE: /opt/secret
      # kerberos keytab authentication
      # KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      # KINIT_KEYTAB_FILE: /opt/secret
    volumes:
      - ca_dist:/etc/ssl/certs:ro
      - ca_root:/data
    configs:
      - source: kinit_secret
        target: /opt/secret
    restart: unless-stopped

volumes:
  ca_dist: {}
  ca_root: {}

configs:
  kinit_secret:
    file: kinit_secret
```


## `cert-enroll`
Useful when you want to partially automate certificate enrollment:
- Can be useful if you can't use ACME.
- Can monitor and notify you when you need to take action.

### Environment Variables

| Variable | Description |
|---|---|
| `CERT_DIR` | Directory where certificate state and files are stored |
| `CERT_CA` | CA label identifying this request (matched by `certsrv-submit`) |
| `CERT_SUBJECT` | X.509 subject DN for the CSR (e.g., `CN=server.example.local`) |
| `CERT_SAN` | Space-separated list of Subject Alternative Names (DNS names) |

### Operational guidance
This container writes certificate requests to a shared data volume and polls until a certificate appears.

Typical Flow:
1. Start the container with a persistent certificate directory.
2. The container generates a CSR and writes it to `/data/request-*/csr.pem`.
3. A CA label is written to `/data/request-*/nickname.txt` (from `CERT_CA`).
4. The container polls until a certificate appears at `/data/request-*/cert.pem`.
5. Once the certificate is present, the container loads it and begins tracking renewal.

To fulfill requests automatically for Windows CERTSRV, run `certsrv-submit` alongside this container.
For other CAs, place the signed certificate at `cert.pem` in the request directory manually.

### Volumes

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| `certs_data` | named volume (rw) | `/data` | Shared persistent volume for CSRs, issued certificates, private keys, and certmonger renewal state. Must be shared with `certsrv-submit` (or whichever tool fulfills the requests). Survives container restarts so in-progress enrollments and renewals are not lost. |

### Compose Example
```yaml
services:
  cert-enroll:
    image: ghcr.io/vertigis/host-kit/cert-enroll:latest
    environment:
      # which folder to manage
      CERT_DIR: /data/server
      # ca label used to identify this request
      CERT_CA: web-server-sd87g8h7ds8sdt8h
      # the subject for the csr/cert
      CERT_SUBJECT: CN=server.example.local
      # the DNS names for the csr/cert
      CERT_SAN: studio.contoso.com studio-prod.local
    volumes:
      - certs_data:/data
    restart: unless-stopped

volumes:
  certs_data: {}
```


## certsrv-submit
Useful when you want to automatically fulfill `cert-enroll` requests via Windows CERTSRV:
- Monitors the shared certificate data volume for pending requests from `cert-enroll`.
- Submits each CSR to the CERTSRV web enrollment interface and fetches the issued certificate.
- Writes the certificate back to the request directory for `cert-enroll` to pick up.
- Uses Kerberos for authentication against the CERTSRV endpoint.

### Environment Variables

| Variable | Description | Auth Path |
|---|---|---|
| `CERTSRV_URL` | Base URL to the Windows CERTSRV web enrollment interface | — |
| `CERTSRV_CA` | CA label to match — must equal `CERT_CA` in `cert-enroll` | — |
| `KINIT_PRINCIPAL` | Kerberos principal (`user@REALM`) | Kerberos |
| `KINIT_KEYTAB_FILE` | Path to Kerberos keytab file | Kerberos keytab |
| `KINIT_SECRET_FILE` | Path to file containing Kerberos password | Kerberos password |

Set `KINIT_PRINCIPAL` with either `KINIT_KEYTAB_FILE` (keytab) or `KINIT_SECRET_FILE` (password) — credentials provided by IT either way. Keytab is preferred for production; password is shown in examples for familiarity. Ask your AD team which format they can issue.

### Pairing with `cert-enroll`
Both containers must share the same `certs_data` volume. `CERTSRV_CA` must match the `CERT_CA` value in `cert-enroll`.

### Volumes

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| `certs_data` | named volume (rw) | `/data` | Shared with `cert-enroll`. This container reads pending CSRs from `/data/request-*/csr.pem`, submits them to CERTSRV, and writes the issued certificate back as `cert.pem` so `cert-enroll` can pick it up. The handshake between the two containers happens entirely through this volume. |
| `ca_dist` | named volume (ro) | `/etc/ssl/certs` | Read-only CA bundle from `ca-enroll`, used to validate HTTPS connections to the CERTSRV server. Same reason as `certsrv-ca` — required when the CA is internal and not publicly trusted. |

### Compose Example
```yaml
services:
  certsrv-submit:
    image: ghcr.io/vertigis/host-kit/certsrv-submit:latest
    environment:
      # base URL to Windows CERTSRV
      CERTSRV_URL: https://ca.contoso.com
      # must match CERT_CA in cert-enroll
      CERTSRV_CA: web-server-sd87g8h7ds8sdt8h
      # kerberos password authentication
      KINIT_SECRET_FILE: /opt/secret
      KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      # kerberos keytab authentication
      # KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      # KINIT_KEYTAB_FILE: /opt/secret
    volumes:
      - ca_dist:/etc/ssl/certs:ro
      - certs_data:/data
    configs:
      - source: kinit_secret
        target: /opt/secret
    restart: unless-stopped

volumes:
  ca_dist: {}
  certs_data: {}

configs:
  kinit_secret:
    file: kinit_secret
```


## dhcp-fw
Useful when you want to manage network ingress for a container:
- Obtain an IP address via DHCP and advertise the hostname.
- Restrict inbound TCP traffic to HTTP (80) and HTTPS (443) only.
- Advertise the container hostname via mDNS for local network discovery.

### Environment Variables

| Variable | Description |
|---|---|
| `DHCP_HOSTNAME` | Short hostname to advertise via DHCP (e.g. `my-studio`, not a FQDN) |

### Volumes

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| `dhcp_data` | named volume (rw) | `/var/lib/dhcpcd` | Persists the DHCP lease and client state across restarts. Without this, the container re-negotiates a new lease on every restart, which may result in a different IP address and break DNS or firewall rules that depend on a stable address. |

### Compose Example
```yaml
services:
  dhcp-fw:
    image: ghcr.io/vertigis/host-kit/dhcp-fw:latest
    environment:
      # the hostname to send via DHCP
      DHCP_HOSTNAME: my-studio
    volumes:
      - dhcp_data:/var/lib/dhcpcd
    networks:
      ingress:
        interface_name: eth0
        mac_address: "02:ab:cd:ef:00:01"
      private:
        interface_name: eth1      
    hostname: my-studio
    privileged: true
    restart: unless-stopped    

networks:
  default:
    driver: bridge
  ingress: 
    driver: macvlan
    driver_opts:
      parent: eth0
  private:
    driver: bridge
    internal: true

volumes:
  dhcp_data: {}
```


## ns-update
Useful when you want to manage your own IP assignment and update DNS appropriately.

### Environment Variables

| Variable | Description | Auth Path |
|---|---|---|
| `DNS_HOST` | Fully qualified hostname to register in DNS | — |
| `DNS_SERVER` | DNS server that will perform the update | — |
| `KINIT_PRINCIPAL` | Kerberos principal (`user@REALM`) | Kerberos |
| `KINIT_KEYTAB_FILE` | Path to Kerberos keytab file | Kerberos keytab |
| `KINIT_SECRET_FILE` | Path to file containing Kerberos password | Kerberos password |
| `NSUPDATE_KEY_FILE` | Path to TSIG key file | TSIG key |
| `NSUPDATE_SECRET_FILE` | Path to file containing TSIG shared secret | TSIG secret |

Authentication (choose one): Kerberos keytab (`KINIT_PRINCIPAL` + `KINIT_KEYTAB_FILE`), Kerberos password (`KINIT_PRINCIPAL` + `KINIT_SECRET_FILE`), TSIG key (`NSUPDATE_KEY_FILE`), or TSIG secret (`NSUPDATE_SECRET_FILE`).

### Volumes

This container has no persistent volumes. Authentication secrets are delivered as Docker configs (read-only files injected at runtime), so no sensitive material is stored in a volume or baked into the image.

| Mount | Type | Internal Path | Why |
|---|---|---|---|
| Auth secret config | Docker config (ro) | `/opt/secret` | Holds the keytab file, password, or TSIG key depending on the chosen auth method. Using a Docker config keeps secrets out of environment variables and out of the image layer. |

### Compose Example
```yaml
services:
  ns-update:
    image: ghcr.io/vertigis/host-kit/ns-update:latest
    environment:
      # the host entry to update
      DNS_HOST: my-studio.contoso.com
      # the server that should perform the update
      DNS_SERVER: dc01.contoso.com
      # authentication (pick one method):

      # kerberos password file:
      KINIT_SECRET_FILE: /opt/secret
      KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      # kerberos keytab:
      # KINIT_KEYTAB_FILE: /opt/secret
      # KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      # TSIG key file:
      # NSUPDATE_KEY_FILE: /opt/secret
      # TSIG shared secret:
      # NSUPDATE_SECRET_FILE: /opt/secret
    configs:
      - source: kinit_secret
        target: /opt/secret
    network_mode: service:dhcp-fw
    restart: unless-stopped

configs:
  kinit_secret:
    file: kinit_secret
```


## egress-fw
Useful when you want to restrict outgoing requests:
- Applies network level policy controls on a container.
- Only allow access to specific systems.

### Environment Variables

| Variable | Description |
|---|---|
| `ALLOW_CIDRS` | Space-separated list of CIDR blocks allowed for outbound TCP traffic |

### Volumes

This container has no volumes. It operates entirely at the network level — it joins the target container's network namespace via `network_mode: service:<name>` and installs `iptables` rules there. No persistent state is needed because the rules are re-applied fresh on each startup.

### Compose Example
```yaml
services:
  egress-fw:
    image: ghcr.io/vertigis/host-kit/egress-fw:latest
    environment:
      ALLOW_CIDRS: >
        10.0.0.0/8
        192.168.100.0/24
        150.171.110.146/24
    # manage the outgoing network traffic for the app container
    network_mode: service:my-app
    privileged: true
    restart: unless-stopped
```
