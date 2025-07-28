#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"
REQUIRED_VARS=(CLUSTER_NAME NODE_NAME INTERFACE BINDNETADDR)
load_env_and_validate "${REQUIRED_VARS[@]}" || exit 1

#!/bin/bash

REQUIRED_VARS=(
  "CLUSTER_NAME" "EXPECTED_NODES" "CLUSTER_MASTER"
  "INTERFACE" "BINDNETADDR"
  "CEPH_MON_MAP" "CEPH_PUBLIC_NETWORK" "CEPH_CLUSTER_NETWORK"
  "FRR_ROUTER_ID" "FRR_ROUTER_ID6" "FRR_INTERFACE"
  "FRR_NETWORK" "FRR_NETWORK6"
)

log_info "Running preflight check..."

if ! load_env_and_validate "${REQUIRED_VARS[@]}"; then
  log_error "Environment validation failed."
  exit 1
fi

log_info "✅ All required variables are set. Here's the current topology:"
echo ""
echo "🔗 Cluster Name      : $CLUSTER_NAME"
echo "👥 Expected Nodes    : $EXPECTED_NODES"
echo "🎯 Master Node       : $CLUSTER_MASTER"
echo "🌐 Interface         : $INTERFACE"
echo "🔧 Bind Network Addr : $BINDNETADDR"
echo ""
echo "💾 Ceph Public Net   : $CEPH_PUBLIC_NETWORK"
echo "💽 Ceph Cluster Net  : $CEPH_CLUSTER_NETWORK"
echo "📍 Monitor Map       : $CEPH_MON_MAP"
echo ""
echo "🧭 FRR Router ID     : $FRR_ROUTER_ID"
echo "🧭 FRR Router IPv6   : $FRR_ROUTER_ID6"
echo "📡 FRR Interface     : $FRR_INTERFACE"
echo "📡 FRR Network IPv4  : $FRR_NETWORK"
echo "📡 FRR Network IPv6  : $FRR_NETWORK6"
echo ""

log_info "Preflight check complete. You’re good to go 🚀"
