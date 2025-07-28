#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"

#!/bin/bash
set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🧪 Dry-run mode active: no changes will be made"
fi

# Load environment
source "$(dirname "$0")/.env"

# Detect override path
if [[ -f "/etc/frr/frr.conf.local" ]]; then
  CONFIG_FILE="/etc/frr/frr.conf.local"
else
  CONFIG_FILE="/etc/frr/frr.conf"
fi

TIMESTAMP=$(date '+%Y-%m-%d-%H:%M')
BACKUP_FILE="${CONFIG_FILE}.bak.${TIMESTAMP}"

# Parse interfaces into array
IFS=' ' read -r -a IFACES <<< "$FRR_INTERFACE"

if $DRY_RUN; then
  echo "📦 Would back up: $CONFIG_FILE → $BACKUP_FILE"
  echo "✍️ Would write FRR config to $CONFIG_FILE"
  echo "🔁 Would restart frr service"
  echo ""
  echo "📋 Would generate config with:"
  echo "  - Router ID (IPv4): $FRR_ROUTER_ID"
  echo "  - Router ID (IPv6): $FRR_ROUTER_ID6"
  echo "  - OSPF Network: $FRR_NETWORK"
  echo "  - OSPF6 Network: $FRR_NETWORK6"
  echo "  - Interfaces: ${IFACES[*]}"
  echo ""
  echo "📖 Config preview:"
  echo "--------------------------------"
  echo "frr version 8.4"
  echo "frr defaults traditional"
  echo "hostname $(hostname)"
  echo "log syslog informational"
  echo "service integrated-vtysh-config"
  echo ""
  echo "router ospf"
  echo " ospf router-id $FRR_ROUTER_ID"
  echo " network $FRR_NETWORK area 0.0.0.0"
  echo ""
  echo "router ospf6"
  echo " ospf6 router-id $FRR_ROUTER_ID6"
  for iface in "${IFACES[@]}"; do
    echo " interface $iface area 0.0.0.0"
  done
  echo ""
  for iface in "${IFACES[@]}"; do
    echo "interface $iface"
    echo " ip ospf area 0.0.0.0"
    echo " ipv6 ospf6 area 0.0.0.0"
    echo ""
  done
  echo "line vty"
  echo "--------------------------------"
  echo "✅ FRR config simulated successfully"
else
  cp "$CONFIG_FILE" "$BACKUP_FILE"

  cat > "$CONFIG_FILE" <<EOF
frr version 8.4
frr defaults traditional
hostname $(hostname)
log syslog informational
service integrated-vtysh-config

router ospf
 ospf router-id $FRR_ROUTER_ID
 network $FRR_NETWORK area 0.0.0.0

router ospf6
 ospf6 router-id $FRR_ROUTER_ID6
EOF

  for iface in "${IFACES[@]}"; do
    echo " interface $iface area 0.0.0.0" >> "$CONFIG_FILE"
  done

  for iface in "${IFACES[@]}"; do
    echo "" >> "$CONFIG_FILE"
    echo "interface $iface" >> "$CONFIG_FILE"
    echo " ip ospf area 0.0.0.0" >> "$CONFIG_FILE"
    echo " ipv6 ospf6 area 0.0.0.0" >> "$CONFIG_FILE"
  done

  echo "" >> "$CONFIG_FILE"
  echo "line vty" >> "$CONFIG_FILE"

  systemctl restart frr
  echo "✅ FRR dual-stack mesh config written to $CONFIG_FILE"
fi
