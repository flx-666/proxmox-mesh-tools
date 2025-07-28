#!/bin/bash

CONFIGS=("corosync" "ceph" "frr" "frr.local")
CONFIG_PATHS=(
  "/etc/pve/corosync.conf"
  "/etc/pve/ceph.conf"
  "/etc/frr/frr.conf"
  "/etc/frr/frr.conf.local"
)
BACKUP_PATTERN=(
  "/etc/pve/corosync.conf.bak.*"
  "/etc/pve/ceph.conf.bak.*"
  "/etc/frr/frr.conf.bak.*"
  "/etc/frr/frr.conf.local.bak.*"
)

# Detect if SDN override exists
if [[ -f "/etc/frr/frr.conf.local" ]]; then
  FRR_INDEX=3
else
  FRR_INDEX=2
fi

# Parse flags
INTERACTIVE=true
DRY_RUN=false
SELECTED_CONFIG=""
ROLL_ALL=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --config) SELECTED_CONFIG="$2"; INTERACTIVE=false; shift ;;
    --all) ROLL_ALL=true; INTERACTIVE=false ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

rollback() {
  NAME=$1
  INDEX=$2
  FILE=${CONFIG_PATHS[$INDEX]}
  PATTERN=${BACKUP_PATTERN[$INDEX]}
  LATEST=$(ls -t $PATTERN 2>/dev/null | head -n 1)

  [[ -z "$LATEST" ]] && echo "❌ No backup found for $NAME" && return

  TIMESTAMP=$(date '+%Y-%m-%d-%H:%M')
  ARCHIVE="${FILE}.orig.$TIMESTAMP"

  if $DRY_RUN; then
    echo "🧪 Dry-run mode active: no files will be changed"
    echo "🗂️ Latest backup found: $LATEST"
    echo "📁 Current config archived as: $ARCHIVE"
    echo "🔍 Command that would run: cp $LATEST → $FILE"
    echo "📜 Journal for ${NAME}:"
    journalctl -n 10 -u "${NAME}" | tail -n 10
  else
    cp "$FILE" "$ARCHIVE" && cp "$LATEST" "$FILE"
    systemctl restart "${NAME}" || echo "⚠️ Could not restart $NAME"
    journalctl -n 10 -u "${NAME}" | tail -n 10
    echo "✅ Rolled back $NAME"
  fi
}

if $INTERACTIVE; then
  echo "Select config to roll back:"
  echo "1) corosync"
  echo "2) ceph"
  echo "3) frr"
  echo "4) frr.local (SDN override)"
  echo "5) all"
  read -p "Enter choice [1–5]: " CHOICE

  if [[ "$CHOICE" -eq 5 ]]; then
    ROLL_ALL=true
  else
    INDEX=$((CHOICE - 1))
    rollback "${CONFIGS[$INDEX]}" "$INDEX"
    exit
  fi
fi

if $ROLL_ALL; then
  for i in "${!CONFIG_PATHS[@]}"; do
    rollback "${CONFIGS[$i]}" "$i"
  done
elif [[ -n "$SELECTED_CONFIG" ]]; then
  for i in "${!CONFIGS[@]}"; do
    if [[ "${CONFIGS[$i]}" == "$SELECTED_CONFIG" ]]; then
      rollback "$SELECTED_CONFIG" "$i"
      exit
    fi
  done
  echo "❌ Unknown config: $SELECTED_CONFIG"
fi
