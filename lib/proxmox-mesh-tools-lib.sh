#!/bin/bash

### 🧪 Environment Variable Loader & Validator
load_env_and_validate() {
  local required_vars=("$@")
  local missing_vars=()

  for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
      missing_vars+=("$var")
    fi
  done

  if [ "${#missing_vars[@]}" -ne 0 ]; then
    log_error "Missing required environment variables: ${missing_vars[*]}"
    return 1
  fi
  return 0
}

### 🎯 Logging Functions
log_info()   { echo -e "[INFO]  $*"; }
log_warn()   { echo -e "[WARN]  $*"; }
log_error()  { echo -e "[ERROR] $*" >&2; }
log_debug()  { [[ "${DEBUG:-}" == "true" ]] && echo -e "[DEBUG] $*"; }

### 🗃️ Backup Function
backup_script() {
  local target="$1"
  local ts
  ts=$(date +"%Y-%m-%d-%H:%M")
  local backup_path="${target}.bak.$ts"
  cp "$target" "$backup_path"
  log_info "📦 Backup created: $backup_path"
}

### 🛡 Root User Check
require_root_user() {
  if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root."
    exit 1
  fi
}

### 🎭 Dry Run Guard
dry_run_guard() {
  if [ "${DRY_RUN:-}" == "true" ]; then
    log_info "Dry-run mode: skipping execution."
    return 0
  fi
  return 1
}

### 💾 Backup Rotation (keep last 3)
rotate_backups() {
  local prefix="$1"
  ls -t "${prefix}.bak."* 2>/dev/null | tail -n +4 | while read -r old_backup; do
    rm -f "$old_backup"
    log_info "🧹 Removed old backup: $old_backup"
  done
}
