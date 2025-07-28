#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"

#!/bin/bash

MASTER="pve01"

if [ "$HOSTNAME" != "$MASTER" ]; then
    echo "🔗 Rejoin cluster via $MASTER"
    pvecm add $MASTER
else
    echo "✅ Nœud maître détecté → pas de join nécessaire"
fi
