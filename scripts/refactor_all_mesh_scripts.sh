#!/bin/bash
set -euo pipefail

source "/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"
require_root_user
backup_script "$0"
rotate_backups "$0"

#!/bin/bash
set -euo pipefail

BASE_DIR="./scripts"
LIB_PATH="/opt/proxmox-mesh-tools/lib/proxmox-mesh-tools-lib.sh"

# Find every .sh script under scripts/ and subdirs
find "$BASE_DIR" -type f -name "*.sh" | while read -r script; do
  echo "🛠️ Refactoring $script..."

  # Remove legacy sourcing

  # Ensure library sourcing and core calls at the top

  # Inject dry-run guard before execution markers
  sed -i "/^# .*actual.*cluster/i \nif dry_run_guard; then\n  exit 0\nfi\n" "$script"

  echo "✅ Updated: $script"
done

echo "🎉 All scripts in '$BASE_DIR/' and subfolders refactored!"
