#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"
REQUIRED_VARS=(CLUSTER_NAME NODE_NAME INTERFACE BINDNETADDR)
load_env_and_validate "${REQUIRED_VARS[@]}" || exit 1

#!/bin/bash

echo "🧠 Mesh Tools Menu"
select OPTION in "Configurer DNS" "Configurer FRR" "Configurer Cluster" "Valider Mesh" "Quitter"; do
  case $OPTION in
    "Configurer DNS") bash scripts/dns/config_cluster_dns.sh ;;
    "Configurer FRR") bash scripts/frr/config_cluster_frr.sh ;;
    "Configurer Cluster") bash scripts/cluster/config_cluster_pvecm.sh ;;
    "Valider Mesh") bash scripts/tools/validate_mesh.sh ;;
    "Quitter") break ;;
  esac
done
