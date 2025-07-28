#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"

#!/bin/bash

# Chemins des scripts
SCRIPTS=(
  "scripts/dns/config_cluster_dns.sh"
  "scripts/frr/config_cluster_frr.sh"
  "scripts/cluster/config_cluster_pvecm.sh"
  "scripts/tools/validate_mesh.sh"
)

LOGFILE="install_cluster.log"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Installation du cluster mesh démarrée...${NC}" | tee $LOGFILE

i=1
for SCRIPT in "${SCRIPTS[@]}"; do
  if [[ -f "$SCRIPT" ]]; then
    echo -e "${YELLOW}🔧 [${i}/${#SCRIPTS[@]}] Exécution : $SCRIPT${NC}" | tee -a $LOGFILE
    bash "$SCRIPT" >> $LOGFILE 2>&1
    echo -e "${GREEN}✅ ${SCRIPT} terminé${NC}" | tee -a $LOGFILE
  else
    echo -e "${RED}❌ ${SCRIPT} introuvable. Abandon.${NC}" | tee -a $LOGFILE
    exit 1
  fi
  ((i++))
done

echo -e "${GREEN}🎉 Installation terminée avec succès !${NC}" | tee -a $LOGFILE
