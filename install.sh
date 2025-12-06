#!/bin/bash
set -e

usage() {
    echo "Usage: $0 [--dnf-packages \"pkg1 pkg2...\"] [--pip-packages \"pkg1 pkg2...\"]"
    exit 1
}

PACKAGES="nano qbittorrent-nox"
PIP_PACKAGES="croniter python-dateutil apscheduler"

echo "[INFO] Starting install.sh script"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dnf-packages)
            PACKAGES="$2"
            echo "[INFO] Overriding system packages to install: $PACKAGES"
            shift 2
            ;;
        --pip-packages)
            PIP_PACKAGES="$2"
            echo "[INFO] Overriding PIP packages to install: $PIP_PACKAGES"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

if command -v dnf &> /dev/null; then
    echo "[INFO] Detected DNF package manager"
    echo "[INFO] Updating DNF repositories"
    dnf -y update
    echo "[INFO] Installing packages: $PACKAGES"
    echo "$PACKAGES" | xargs dnf install -y
    echo "[INFO] Packages installed successfully"

    if [ ! -z "$PIP_PACKAGES" ]; then
        echo "[INFO] Checking for pip3"
        if ! command -v pip3 &> /dev/null; then
            echo "[INFO] pip3 not found, installing python3-pip"
            dnf install -y python3-pip
        fi
    fi

elif command -v apt-get &> /dev/null; then
    echo "[INFO] Detected APT package manager"
    export DEBIAN_FRONTEND=noninteractive
    echo "[INFO] Updating APT repositories"
    apt-get update -y
    echo "[INFO] Installing packages: $PACKAGES"
    echo "$PACKAGES" | xargs apt-get install -y
    echo "[INFO] Packages installed successfully"

    if [ ! -z "$PIP_PACKAGES" ]; then
        echo "[INFO] Checking for pip3"
        if ! command -v pip3 &> /dev/null; then
            echo "[INFO] pip3 not found, installing python3-pip"
            apt-get install -y python3-pip
        fi
    fi
else
    echo "[ERROR] No supported package manager found (dnf, apt-get)"
    exit 1
fi

if [ ! -z "$PIP_PACKAGES" ]; then
    echo "[INFO] Installing pip packages: $PIP_PACKAGES"
    # Try to install with --break-system-packages if available (for recent Debian/Ubuntu)
    if pip3 install --help | grep -q "break-system-packages"; then
        echo "$PIP_PACKAGES" | xargs pip3 install --break-system-packages
    else
        echo "$PIP_PACKAGES" | xargs pip3 install
    fi
    echo "[INFO] PIP packages installed successfully"
fi

if command -v qbittorrent-nox &> /dev/null; then
    echo "[INFO] Creating symlink for stormtorrent"
    ln -sf $(which qbittorrent-nox) /usr/bin/stormtorrent
else
    echo "[ERROR] qbittorrent-nox not found, cannot create stormtorrent symlink"
fi

echo "[INFO] install.sh script completed"
