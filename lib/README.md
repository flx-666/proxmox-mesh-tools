# 🧰 Proxmox Mesh Tools

A modular and centralized toolkit for automating Proxmox cluster tasks with Bash.

## 📂 Unified Utility Library

All core helper functions have been consolidated into:

lib/proxmox-mesh-tools-lib.sh


> ✅ This replaces previous files like `lib_env_loader.sh` and `lib_logger.sh`

---

## ⚙️ Included Functions

| Function                   | Description                                        |
|----------------------------|----------------------------------------------------|
| `load_env_and_validate()`  | Validates required env vars                        |
| `log_info()` / `log_warn()`| Logging with consistent format                     |
| `log_error()` / `log_debug()`| Error and conditional debug output               |
| `backup_script()`          | Timestamped backup of current script               |
| `require_root_user()`      | Enforces root-level execution                      |
| `dry_run_guard()`          | Skips execution if `DRY_RUN=true`                  |
| `rotate_backups()`         | Keeps last 3 backups, removes older ones           |

---

## 🚀 How to Use in Your Scripts

```bash
source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"

require_root_user
backup_script "$0"
rotate_backups "$0"

REQUIRED_VARS=("CLUSTER_NAME" "NODE_NAME" "INTERFACE" "BINDNETADDR")
load_env_and_validate "${REQUIRED_VARS[@]}" || exit 1

log_info "Starting mesh tool script..."

Optional:

DEBUG=true      # Enable debug logging
DRY_RUN=true    # Skip actual execution steps

