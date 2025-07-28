#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"
REQUIRED_VARS=(CLUSTER_NAME NODE_NAME INTERFACE BINDNETADDR)
load_env_and_validate "${REQUIRED_VARS[@]}" || exit 1

#!/bin/bash

MASTER="pve01"

if [ "$HOSTNAME" != "$MASTER" ]; then
    echo "🔗 Rejoin cluster via $MASTER"
    pvecm add $MASTER
else
    echo "✅ Nœud maître détecté → pas de join nécessaire"
fi
