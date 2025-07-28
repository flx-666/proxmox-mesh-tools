#!/bin/bash
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 config_cluster_dns.sh — Cluster-wide DNS setup with backup & dry-run
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../lib/proxmox-mesh-tools-lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌱 Load .env + prepare backup/log directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
required_env_vars=("DNS_DOMAIN" "DNS_SEARCH" "DNS_SERVERS")
load_env_and_validate "${required_env_vars[@]}"

REPO_ROOT="$(get_repo_root)"
BACKUP_DIR="$REPO_ROOT/Backups"
mkdir -p "$BACKUP_DIR"

timestamp="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$BACKUP_DIR/config_cluster_dns.$timestamp.log"
exec > >(tee "$LOG_FILE") 2>&1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Generate full DNS update command block
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
generate_dns_block() {
  block=""
  block+="echo search $DNS_SEARCH > /etc/resolv.conf\n"
  block+="echo domain $DNS_DOMAIN >> /etc/resolv.conf\n"
  for entry in $(echo "$DNS_SERVERS" | tr ',' ' '); do
    ip="${entry%%:*}"
    flag="${entry##*:}"
    if [[ "$flag" == "active" ]]; then
      block+="echo nameserver $ip >> /etc/resolv.conf\n"
    else
      block+="echo \"# inactive nameserver $ip\" >> /etc/resolv.conf\n"
    fi
  done
  echo -e "$block"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📥 Backup function with dry-run awareness
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
backup_resolv_conf() {
  local node="$1"
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "🧪 [dry-run] Skipping backup from $node"
  else
    log_info "📥 Backing up remote /etc/resolv.conf from $node"
    ssh root@"$node" cat /etc/resolv.conf > "$BACKUP_DIR/resolv.conf.$node.$timestamp" \
      || log_warn "⚠️ Failed to fetch /etc/resolv.conf from $node"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 DNS propagation function with dry-run logic
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
propagate_dns() {
  local node="$1"
  local block="$(generate_dns_block)"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "🧪 [dry-run] Would execute on $node:"
    echo -e "ssh root@$node bash -c '\n$block'"
  else
    ssh root@"$node" bash -c "$block"
    log_info "✅ DNS updated on $node"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧼 Cluster-wide Execution Loop
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
log_info "🔧 Starting DNS propagation across cluster..."

for node in $(get_all_nodes); do
  log_info "📍 Processing node: $node"
  backup_resolv_conf "$node"
  propagate_dns "$node"
done

log_success "🎉 DNS configuration completed for all nodes!"
