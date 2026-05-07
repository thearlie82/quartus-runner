#!/bin/bash
set -e

# Install system packages
apt-get update
apt-get install -y --no-install-recommends \
    git ca-certificates python3 \
    libx11-6 libxext6 libxrender1 libxtst6 libxi6 libxft2 \
    libfreetype6 libfontconfig1 \
    libglib2.0-0 libsm6 libice6 \
    libnss3 libdbus-1-3 \
    wget apt-transport-https \
    locales
rm -rf /var/lib/apt/lists/*
locale-gen en_US.UTF-8

# Install PowerShell
. /etc/os-release
wget -q "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb
apt-get update
apt-get install -y --no-install-recommends powershell
rm -rf /var/lib/apt/lists/*

# Install CA certificates
cp /tmp/*.crt /usr/local/share/ca-certificates/
update-ca-certificates
rm /tmp/*.crt

# Remove libudev - its init triggers realloc() crash in Quartus
# when running in containerized/namespaced environments
rm -f /usr/lib/x86_64-linux-gnu/libudev.so* /lib/x86_64-linux-gnu/libudev.so* 2>/dev/null || true
echo "libudev removed"

# Verify glibc version is 2.35 (Ubuntu 22.04)
ldd --version 2>&1 | head -1
if ldd --version 2>&1 | grep -q "2.35"; then
    echo "glibc 2.35 confirmed"
else
    echo "ERROR: Expected glibc 2.35"
    exit 1
fi
