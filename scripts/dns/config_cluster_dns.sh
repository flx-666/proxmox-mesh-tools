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

echo "🔧 Hostname → $NODE"
hostnamectl set-hostname "$NODE"

echo "🔧 /etc/hosts → Ajout IP mesh"
grep -q "$NODE" /etc/hosts || echo "$IPV6_MESH $NODE" >> /etc/hosts

cat <<EOF >> /etc/hosts
fc00::80:1 pve01
fc00::80:2 pve02
fc00::80:3 pve03
# 10.1.2.21 dc01.ad.famille-clerc.com
# 10.1.2.22 dc02.ad.famille-clerc.com
EOF

echo "🔧 /etc/resolv.conf"
cat <<EOF > /etc/resolv.conf
nameserver 10.1.2.21
nameserver 10.1.2.22
nameserver 10.1.2.1
search ad.famille-clerc.com
EOF

echo "🔧 /etc/nsswitch.conf"
sed -i 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf
