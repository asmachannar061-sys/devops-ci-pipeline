#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this installer with sudo: sudo bash scripts/install-docker.sh" >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot identify this Linux distribution (/etc/os-release is missing)." >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
case "${ID:-}" in
    ubuntu|debian)
        ;;
    *)
        echo "This script supports Ubuntu and Debian only (found: ${ID:-unknown})." >&2
        exit 1
        ;;
esac

if [[ -z "${VERSION_CODENAME:-}" ]]; then
    echo "Could not determine the distribution codename from /etc/os-release." >&2
    exit 1
fi

apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

architecture="$(dpkg --print-architecture)"
echo \
    "deb [arch=${architecture} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    usermod -aG docker "${SUDO_USER}"
    echo "Added ${SUDO_USER} to the docker group. Log out and back in for the change to take effect."
else
    echo "Docker is installed and running. Use sudo for Docker commands or add your user to the docker group."
fi
