#!/bin/bash
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚙️ Default toggles
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ENABLE_SYSLOG="${ENABLE_SYSLOG:-true}"
DRY_RUN="${DRY_RUN:-false}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🪵 Logging functions (console + journaling)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
log_info() {
  local msg="[INFO] $(date -Is) $*"
  echo -e "$msg"
  [ "$ENABLE_SYSLOG" = "true" ] && logger -t proxmox-mesh-tools "$msg"
}

log_warn() {
  local msg="[WARN] $(date -Is) $*"
  echo -e "$msg" >&2
  [ "$ENABLE_SYSLOG" = "true" ] && logger -t proxmox-mesh-tools "$msg"
}

log_error() {
  local msg="[ERROR] $(date -Is) $*"
  echo -e "$msg" >&2
  [ "$ENABLE_SYSLOG" = "true" ] && logger -t proxmox-mesh-tools "$msg"
}

log_success() {
  local msg="[SUCCESS] $(date -Is) $*"
  echo -e "$msg"
  [ "$ENABLE_SYSLOG" = "true" ] && logger -t proxmox-mesh-tools "$msg"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚨 Exit wrapper
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
die() {
  log_error "$1"
  exit 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ❔ Interactive Confirm Prompt
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
confirm() {
  local msg="${1:-Are you sure?}"
  read -rp "❔ $msg [y/N]: " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) log_warn "↩️ Operation cancelled." ; return 1 ;;
  esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧠 Auto-resolve hostname
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
resolve_pve_hostname() {
  : "${PVE_HOSTNAME:=$(hostname)}"
  log_info "🧭 Using PVE_HOSTNAME: $PVE_HOSTNAME"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📂 Repository root resolver
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
repo_root() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "$(cd "$script_dir/../.." && pwd)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📂Git  Repository root resolver
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
get_repo_root() {
  git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [[ -z "$git_root" ]]; then
    echo "❌ Not inside a Git repository" >&2
    return 1
  fi
  echo "$git_root"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 Load .env from repo root + validate
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
load_env_and_validate() {
  local repo_root="$(get_repo_root)"
  local env_file="$repo_root/scripts/.env"

  if [[ -f "$env_file" ]]; then
    log_info "🔍 Sourcing .env from: $env_file"
    set -a
    . "$env_file"
    set +a
    resolve_pve_hostname
  else
    log_error "❌ .env file not found at: $env_file"
    exit 1
  fi

  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log_error "🚨 Missing required env var: $var"
      exit 1
    fi
  done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎭 Dry Run Guard
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
dry_run_guard() {
  if [[ "$DRY_RUN" = "true" || "${1:-}" == "--dry-run" ]]; then
    log_warn "💡 Dry-run mode active. Skipping execution."
    return 0
  fi
  return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛡 Root User Check
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
require_root_user() {
  if [[ "$EUID" -ne 0 ]]; then
    log_error "⛔ This script must be run as root."
    exit 1
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🗃️ Backup Function
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
backup_script() {
  local target="$1"
  local ts
  ts=$(date +"%Y-%m-%d-%H:%M")
  local backup_path="${target}.bak.$ts"
  cp "$target" "$backup_path"
  log_info "📦 Backup created: $backup_path"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💾 Backup Rotation (keep last 3)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
rotate_backups() {
  local prefix="$1"
  ls -t "${prefix}.bak."* 2>/dev/null | tail -n +4 | while read -r old_backup; do
    rm -f "$old_backup"
    log_info "🧹 Removed old backup: $old_backup"
  done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 Validation Helper
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
validate_presence() {
  local missing_vars=()
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      missing_vars+=("$var")
    fi
  done
  if [[ "${#missing_vars[@]}" -ne 0 ]]; then
    log_error "Missing vars: ${missing_vars[*]}"
    return 1
  fi
  return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📡 Cluster Node Fetch
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
get_all_nodes() {
  # Extract real hostnames from pvecm nodes output
  raw_nodes=$(pvecm nodes | awk 'NR>4 {print $3}' | sort -u)
  for node in $raw_nodes; do
    if host "$node" >/dev/null 2>&1; then
      echo "$node"
    else
      log_warn "⚠️ Skipping unresolved node: $node"
    fi
  done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧪 Validate cluster mesh readiness
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
validate_mesh_environment() {
  log_info "🔎 Validating mesh environment..."

  load_env_and_validate DNS_DOMAIN DNS_SERVERS

  if ! pvecm status &>/dev/null; then
    log_error "❌ Node is not part of a PVE cluster!"
    exit 1
  fi

  for node in $(get_all_nodes); do
    if [[ "$node" != "$PVE_HOSTNAME" ]]; then
      ssh -o ConnectTimeout=2 root@"$node" true &>/dev/null || {
        log_error "🔒 Unable to SSH into $node"
        exit 1
      }
    fi
  done

  log_success "✅ Mesh environment looks ready!"
}
