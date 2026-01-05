#!/bin/bash
set -euo pipefail

if [[ "$(uname -m)" != "aarch64" ]]; then
    echo "This script is intended to be run on an aarch64 (ARM64) system." >&2
    exit 1
fi

if ! grep -q "Ubuntu" /etc/lsb-release; then
    echo "This script is intended to be run on an Ubuntu-based system." >&2
    exit 1
fi

if ! grep -R "fex-emu" /etc/apt/sources.list* /etc/apt/sources.list.d/; then
    echo "FEX-EMU PPA not found. Please ensure you have added the FEX-EMU PPA." >&2
    echo "Use: sudo apt-get install software-properties-common" >&2
    echo "     sudo add-apt-repository ppa:fex-emu/fex" >&2
    exit 1
fi

CPUREV=$(awk -F: '/CPU revision/ {gsub(/ /, "", $2); print $2; exit}' /proc/cpuinfo)
echo "Detected CPU revision: $CPUREV"

echo "Updating package lists..."
apt-get update

case "$CPUREV" in
    0|1) FEX_EMU_ARCH_REV="fex-emu-armv8.0" ;;
    2|3) FEX_EMU_ARCH_REV="fex-emu-armv8.2" ;;
    4)     FEX_EMU_ARCH_REV="fex-emu-armv8.4" ;;
    *)
        echo "Unsupported CPU revision: $CPUREV" >&2
        exit 1
        ;;
esac

echo "Using FEX package for architecture revision: $FEX_EMU_ARCH_REV"

echo "Installing FEX packages..."
apt-get install -y --no-install-recommends "$FEX_EMU_ARCH_REV"

echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "FEX installation completed successfully."
exit 0
