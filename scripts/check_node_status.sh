#!/bin/bash
set -e

# Source the shared lib
. "$(dirname "$0")/../lib/proxmox-mesh-tools-lib.sh"

# Dry-run mode logic
if dry_run_guard; then
  exit 0
fi

# Require root user
require_root_user

# Validate required env vars
load_env_and_validate PROXMOX_HOST || die "Missing environment vars"

# Dummy action
log_info "Checking Proxmox node status for: $PROXMOX_HOST"
ping -c 2 "$PROXMOX_HOST" >/dev/null && \
  log_info "✅ Node reachable: $PROXMOX_HOST" || \
  log_error "❌ Failed to reach $PROXMOX_HOST"
