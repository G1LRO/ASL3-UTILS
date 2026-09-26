#!/bin/bash
# RLNZ2 internal/external RF interface switch.
# Modifies rpt.conf (rxchannel). In external mode it also updates devstr in the
# [NODE-external] stanza of simpleusb.conf to wherever the external CM108 was
# detected; no other simpleusb.conf line or stanza is ever touched.
set -euo pipefail

CONF_DIR="/etc/asterisk"
RPT_CONF="$CONF_DIR/rpt.conf"
SIMPLEUSB_CONF="$CONF_DIR/simpleusb.conf"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

usage() {
    echo "Usage: $0 internal|external"
    exit 1
}

detect_node() {
    local nodes
    nodes=$(grep -oP '^\[\K[0-9]{4,6}(?=\])' "$RPT_CONF" 2>/dev/null || echo "")
    echo "$nodes" | grep -v '^1999$' | head -1 || echo ""
}

# Set key=value within a specific stanza only. Replaces if present, inserts
# after the stanza header if absent. Never touches other stanzas.
set_conf() {
    local file="$1"
    local key="$2"
    local value="$3"
    local section="$4"

    local in_stanza=0
    local found=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[${section}\] ]]; then
            in_stanza=1
        elif [[ "$line" =~ ^\[ ]]; then
            in_stanza=0
        fi
        if [[ $in_stanza -eq 1 ]] && [[ "$line" =~ ^${key}[[:space:]]*= ]]; then
            found=1
            break
        fi
    done < "$file"

    if [[ $found -eq 1 ]]; then
        awk -v section="$section" -v key="$key" -v value="$value" '
            /^\[/ { in_section = ($0 ~ "^\\[" section "\\]") }
            in_section && $0 ~ "^" key "[[:space:]]*=" { print key " = " value; next }
            { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    else
        sed -i "/^\[${section}\]/a ${key} = ${value}" "$file"
    fi
}

node_stanza_exists() {
    grep -qE "^\[${1}\]" "$2"
}

# The external USB port is always 1-1.3, but a device behind an extra hub
# enumerates deeper (e.g. 1-1.3.4), so find the sound card anywhere under
# that port instead of assuming a fixed path. Prints e.g. "1-1.3.4:1.0".
EXTERNAL_PORT="1-1.3"
detect_external_devstr() {
    local iface dev devs=()
    for iface in /sys/bus/usb/devices/${EXTERNAL_PORT}:*/sound \
                 /sys/bus/usb/devices/${EXTERNAL_PORT}.*:*/sound; do
        [[ -d "$iface" ]] || continue
        iface=$(basename "$(dirname "$iface")")
        dev="${iface%%:*}"
        [[ " ${devs[*]} " == *" ${dev} "* ]] || devs+=("$dev")
    done
    if [[ ${#devs[@]} -ne 1 ]]; then
        echo "ERROR: expected one USB sound device on external port ${EXTERNAL_PORT}, found ${#devs[@]}: ${devs[*]:-none}" >&2
        return 1
    fi
    echo "${devs[0]}:1.0"
}

# ---------------------------------------------------------------------------

if [[ $# -ne 1 ]] || [[ "$1" != "internal" && "$1" != "external" ]]; then
    usage
fi
MODE="$1"

NODE=$(detect_node)
if [[ -z "$NODE" ]]; then
    echo "ERROR: could not detect node number from $RPT_CONF"
    exit 1
fi
echo "Detected node: $NODE"

if [[ "$MODE" == "external" ]]; then
    if ! node_stanza_exists "${NODE}-external" "$SIMPLEUSB_CONF"; then
        echo "ERROR: [${NODE}-external] stanza not found in $SIMPLEUSB_CONF"
        echo "Refusing to switch to external — Phase 2 setup has not been completed"
        echo "(or the stanza was removed). Asterisk was NOT restarted."
        exit 1
    fi
    RXCHANNEL="SimpleUSB/${NODE}-external"
    if ! EXT_DEVSTR=$(detect_external_devstr); then
        echo "Refusing to switch to external. Asterisk was NOT restarted."
        exit 1
    fi
    OLD_DEVSTR=$(awk -v section="${NODE}-external" '
        /^\[/ { in_section = ($0 ~ "^\\[" section "\\]") }
        in_section && $0 ~ "^devstr[[:space:]]*=" { sub(/^devstr[[:space:]]*=[[:space:]]*/, ""); print; exit }
    ' "$SIMPLEUSB_CONF")
    if [[ "$OLD_DEVSTR" != "$EXT_DEVSTR" ]]; then
        cp "$SIMPLEUSB_CONF" "${SIMPLEUSB_CONF}.bak.${TIMESTAMP}"
        set_conf "$SIMPLEUSB_CONF" "devstr" "$EXT_DEVSTR" "${NODE}-external"
        echo "External devstr: ${OLD_DEVSTR:-<not set>} -> ${EXT_DEVSTR} (backup ${SIMPLEUSB_CONF}.bak.${TIMESTAMP})"
    else
        echo "External devstr: ${EXT_DEVSTR} (unchanged)"
    fi
else
    RXCHANNEL="SimpleUSB/${NODE}"
fi

if ! node_stanza_exists "$NODE" "$RPT_CONF"; then
    echo "ERROR: [${NODE}] stanza not found in $RPT_CONF"
    exit 1
fi

BACKUP="${RPT_CONF}.bak.${TIMESTAMP}"
cp "$RPT_CONF" "$BACKUP"
echo "Backed up rpt.conf to $BACKUP"

OLD_RXCHANNEL=$(awk -v section="$NODE" '
    /^\[/ { in_section = ($0 ~ "^\\[" section "\\]") }
    in_section && $0 ~ "^rxchannel[[:space:]]*=" { print; exit }
' "$RPT_CONF")

set_conf "$RPT_CONF" "rxchannel" "$RXCHANNEL" "$NODE"

NEW_RXCHANNEL=$(awk -v section="$NODE" '
    /^\[/ { in_section = ($0 ~ "^\\[" section "\\]") }
    in_section && $0 ~ "^rxchannel[[:space:]]*=" { print; exit }
' "$RPT_CONF")

echo ""
echo "=== rpt.conf change ==="
echo "  before: ${OLD_RXCHANNEL:-<not set>}"
echo "  after:  ${NEW_RXCHANNEL}"
echo ""
echo "Restarting Asterisk..."
systemctl restart asterisk
echo ""
echo "Switched node ${NODE} to ${MODE} mode (rxchannel = ${RXCHANNEL})."
echo "Asterisk restart issued."
