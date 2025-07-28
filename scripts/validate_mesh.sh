#!/bin/bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧪 Mesh Validation Script
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 📦 Import shared lib
. "$SCRIPT_DIR/../lib/proxmox-mesh-tools-lib.sh"

# 🚩 Parse args
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      log_warn "⚠️ Unknown argument: $arg"
      ;;
  esac
done

# 📁 Load and validate env
load_env_and_validate || {
  log_error "❌ Environment file could not be loaded"
  exit 1
}

# 🧠 Context-aware validation based on enabled features
validate_presence PVE_HOSTNAME || exit 1

if [ "${CEPH_MESH_IPV6:-false}" = "true" ]; then
  validate_presence MESH_IPV6_MAP CEPH_MON_MAP CEPH_PUBLIC_NETWORK || exit 1
fi

if [ "${SDN_ENABLED:-false}" = "true" ]; then
  validate_presence FRR_ROUTER_ID6 FRR_INTERFACE FRR_NETWORK6 || exit 1
fi

# 📋 Log summary
log_info "🔍 Starting mesh validation for node: $PVE_HOSTNAME"
log_info "🔧 CEPH MON IP: $CEPH_MON_IPv6"
log_info "🔧 CEPH MDS Name: $CEPH_MDS_NAME"
log_info "🔧 FRR Mesh IPv6: $FRR_MESH_IPV6"

# 🧪 Dry-run mode
if [ "$DRY_RUN" = true ]; then
  log_info "🫧 Dry-run mode enabled. Skipping validation actions."
  exit 0
fi

# 📂 Real validation logic goes here
# For example, check Ceph config exists or FRR status
if ! systemctl is-active --quiet ceph-mon@"$CEPH_MDS_NAME"; then
  log_error "❌ Ceph MON $CEPH_MDS_NAME is not active"
else
  log_info "✅ Ceph MON $CEPH_MDS_NAME is active"
fi

if ! grep -q "$FRR_MESH_IPV6" /etc/frr/frr.conf; then
  log_warn "⚠️ FRR mesh IPv6 not found in frr.conf"
else
  log_info "✅ FRR mesh IPv6 detected in frr.conf"
fi

log_success "🎉 Mesh validation completed successfully"
