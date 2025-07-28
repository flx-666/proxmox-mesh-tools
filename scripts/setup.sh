#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"

#!/bin/bash

echo "🔧 Installing latest mesh scripts from GitHub..."

# Load .env file
ENV_PATH="$(dirname "$0")/../.env"
if [ -f "$ENV_PATH" ]; then
  export $(grep -v '^#' "$ENV_PATH" | xargs)
else
  echo "⚠️ .env file not found at $ENV_PATH"
  exit 1
fi

# List of scripts to fetch from GitHub raw
SCRIPTS=(
  "config_cluster.sh"
  "config_cluster_ceph.sh"
  "config_cluster_dns.sh"
  "config_cluster_frr.sh"
  "config_cluster_pvecm.sh"
  "rollback_conf.sh"
  "validate_mesh.sh"
)

# GitHub raw base URL
RAW_URL="https://raw.githubusercontent.com/flx-666/proxmox-mesh-tools/main/scripts"

# Download each script and inject `.env` sourcing at the top
for FILE in "${SCRIPTS[@]}"; do
  curl -s "$RAW_URL/$FILE" | sed "1i\\source \"\$ENV_PATH\"" > "./scripts/$FILE"
  chmod +x "./scripts/$FILE"
  echo "✅ Updated $FILE"
done

echo "🏁 All scripts updated with .env sourcing."
