#!/bin/bash
# Clears the devstr= value in simpleusb.conf and restarts Asterisk.
# Run as root (or with sudo)

set -euo pipefail

FILE="/etc/asterisk/simpleusb.conf"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ ! -f "$FILE" ]; then
    echo "ERROR: $FILE not found" >&2
    exit 1
fi

echo "=== Backing up simpleusb.conf ==="
cp "$FILE" "${FILE}.bak.${TIMESTAMP}"
echo "  Backed up to simpleusb.conf.bak.${TIMESTAMP}"

echo ""
echo "=== Clearing devstr value ==="
sed -i 's/^devstr=.*/devstr=/' "$FILE"
echo "Done — devstr= is now blank"

echo ""
echo "=== Restarting Asterisk ==="
systemctl restart asterisk
echo "Done — Asterisk restarted"
