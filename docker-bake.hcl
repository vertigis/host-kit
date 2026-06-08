variable "OWNER" {
    default = "vertigis"
}

variable "REPO" {
    default = "host-kit"
}

variable "REF_NAME" {
    default = "custom"
}

variable "RUN_NUMBER" {
    default = "0"
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
        "ghcr.io/${OWNER}/${REPO}/${item}:${REF_NAME}.${RUN_NUMBER}",
        "ghcr.io/${OWNER}/${REPO}/${item}:${REF_NAME}",
        "ghcr.io/${OWNER}/${REPO}/${item}:latest",
    ]
}

group "default" {
  targets = ["image"]
}
