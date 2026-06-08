variable "OWNER" {
    default = "vertigis"
}

variable "REPO" {
    default = "host-kit"
}

variable "RUN_NUMBER" {
    default = "0"
}

variable "VER" {
    default = "1.1"
}

target "image" {
    matrix = {
        item = [
            "config-editor",
            "license-tool",
            "ca-enroll",
            "cert-enroll",
            "certsrv-ca",
            "certsrv-submit",
            "dhcp-fw",
            "egress-fw",
            "ns-update",
        ]
    }

    name       = item
    context    = item

    tags = [
        "ghcr.io/${OWNER}/${REPO}/${item}:v${VER}.${RUN_NUMBER}",
        "ghcr.io/${OWNER}/${REPO}/${item}:v${VER}",
        "ghcr.io/${OWNER}/${REPO}/${item}:latest",
    ]
}

group "default" {
  targets = ["image"]
}
