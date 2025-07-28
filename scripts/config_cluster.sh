#!/bin/bash

ENV_FILE="./.env"
CONF="/etc/pve/corosync.conf"
NEW_CONF="${CONF}.new"
BAK_CONF="${CONF}.bak"

# Load env
[[ -f "$ENV_FILE" ]] || { echo "❌ Missing $ENV_FILE"; exit 1; }
source "$ENV_FILE"

# Dry-run mode
if [[ "$1" == "--dry-run" ]]; then
  echo "🧪 Dry-run mode active: no config will be modified"

  echo "🔍 Current config_version:"
  cv_current=$(awk '/totem {/,/}/ { if ($1=="config_version:") print $2 }' "$CONF")
  echo "  → $cv_current"
  echo "  🧮 Proposed next version: $((cv_current + 1))"
  echo ""

  echo "📌 Proposed ring address changes:"
  for node in $(echo "$MON_INITIAL_MEMBERS" | tr ',' ' '); do
    r0_ip=$(echo "$RING0_IPV4_MAP" | grep -o "$node=[^ ]*" | cut -d= -f2)
    r1_ip=$(echo "$RING1_IPV4_MAP" | grep -o "$node=[^ ]*" | cut -d= -f2)
    echo "  • $node → ring0 = $r0_ip, ring1 = $r1_ip"
  done
  echo ""
  
  echo "📎 Backup target: $BAK_CONF"
  echo "📎 New config target: $NEW_CONF"
  echo ""

  echo "🩺 Corosync service status:"
  systemctl status corosync --no-pager | head -n 10
  echo ""
  echo "📜 journalctl -b -u corosync:"
  journalctl -b -u corosync --no-pager | tail -n 10
  exit 0
fi
