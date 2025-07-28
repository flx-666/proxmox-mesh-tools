#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"
REQUIRED_VARS=(CLUSTER_NAME NODE_NAME INTERFACE BINDNETADDR)
load_env_and_validate "${REQUIRED_VARS[@]}" || exit 1

#!/bin/bash

REQUIRED_VARS=("CEPH_MON_MAP" "CEPH_PUBLIC_NETWORK" "CEPH_CLUSTER_NETWORK")

if ! load_env_and_validate "${REQUIRED_VARS[@]}"; then
  log_error "Environment failed validation. Aborting."
  exit 1
fi

log_info "Starting Ceph cluster setup..."

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🧪 Dry-run mode active: no changes will be made"
fi

# 🧬 Load environment variables
source "$(dirname "$0")/.env"

TIMESTAMP=$(date '+%Y-%m-%d-%H:%M')
CONFIG_FILE="/etc/pve/ceph.conf"
BACKUP_FILE="${CONFIG_FILE}.bak.${TIMESTAMP}"

# 🔍 Parse MON → IP pairs
MON_NAMES=()
MON_IPS=()
MON_MAP_CSV=""

for pair in $CEPH_MON_MAP; do
  NAME="${pair%%=*}"
  IP="${pair##*=}"
  MON_NAMES+=("$NAME")
  MON_IPS+=("$IP")
  MON_MAP_CSV+="$IP,"
done

if $DRY_RUN; then
  echo "📦 Would back up: $CONFIG_FILE → $BACKUP_FILE"
  echo "✍️ Would write Ceph config to $CONFIG_FILE"

  echo "🔗 MON pairing:"
  for i in "${!MON_NAMES[@]}"; do
    echo "  - ${MON_NAMES[$i]} → ${MON_IPS[$i]}"
  done

  echo ""
  echo "🧬 Config sections that would be created:"
  echo "  - [global]: fsid, mon members, mesh networks, auth settings"
  for name in "${MON_NAMES[@]}"; do
    echo "  - [mon.$name]: host and mon addr"
  done
  echo ""
  echo "✅ Simulated: ${#MON_NAMES[@]} MON nodes configured for mesh bootstrap"
else
  cp "$CONFIG_FILE" "$BACKUP_FILE"

  echo "[global]" > "$CONFIG_FILE"
  echo "fsid = $(uuidgen)" >> "$CONFIG_FILE"
  echo "mon initial members = ${MON_NAMES[*]}" >> "$CONFIG_FILE"
  echo "mon host = ${MON_MAP_CSV%,}" >> "$CONFIG_FILE"
  echo "public network = $CEPH_PUBLIC_NETWORK" >> "$CONFIG_FILE"
  echo "cluster network = $CEPH_CLUSTER_NETWORK" >> "$CONFIG_FILE"
  echo "auth cluster required = cephx" >> "$CONFIG_FILE"
  echo "auth service required = cephx" >> "$CONFIG_FILE"
  echo "auth client required = cephx" >> "$CONFIG_FILE"
  echo >> "$CONFIG_FILE"

  for i in "${!MON_NAMES[@]}"; do
    NAME="${MON_NAMES[$i]}"
    IP="${MON_IPS[$i]}"
    echo "[mon.${NAME}]" >> "$CONFIG_FILE"
    echo "host = ${NAME}" >> "$CONFIG_FILE"
    echo "mon addr = ${IP}" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"
  done

  echo "✅ Ceph mesh config written to $CONFIG_FILE"
fi
