#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"
REQUIRED_VARS=(CLUSTER_NAME NODE_NAME INTERFACE BINDNETADDR)
load_env_and_validate "${REQUIRED_VARS[@]}" || exit 1

#!/bin/bash

NODE=$(hostname)
IPV6_MESH=$(ip -6 addr | grep "fc00::80" | grep -w lo | awk '{print $2}' | cut -d/ -f1 | head -n1)

cat <<EOF > /etc/frr/frr.conf
hostname $NODE
log syslog informational

interface lo
  ipv6 address $IPV6_MESH/128

router bgp 65001
  neighbor pve01 ipv6 address fc00::80:1
  neighbor pve02 ipv6 address fc00::80:2
  neighbor pve03 ipv6 address fc00::80:3
  network $IPV6_MESH/128
EOF
