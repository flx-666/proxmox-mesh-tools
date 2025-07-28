#!/bin/bash

# Load .env variables if available
ENV_FILE=".env"
if [[ -f "$ENV_FILE" ]]; then
  while IFS='=' read -r key value; do
    # Ignore blank lines and comments
    [[ "$key" =~ ^#.*$ || -z "$key" || -z "$value" ]] && continue
    key=$(echo "$key" | xargs)       # Trim whitespace
    value=$(echo "$value" | xargs)   # Trim whitespace
    export "$key=$value"
  done < "$ENV_FILE"
fi

# Define backup timestamp
timestamp=$(date +%Y-%m-%d-%H:%M)
backup_file="config_cluster_pvecm.sh.bak.$timestamp"
dry_run=false

# Parse flags
for arg in "$@"; do
  case $arg in
    --dry-run)
      dry_run=true
      ;;
  esac
done

# Backup original
cp config_cluster_pvecm.sh "$backup_file"
echo "✅ Backup created: $backup_file"

# Corosync config using .env
echo "🧩 Using settings:"
echo "CLUSTER_NAME: ${CLUSTER_NAME:-pve-cluster01}"
echo "INTERFACE: ${INTERFACE:-eth0}"
echo "BINDNETADDR: ${BINDNETADDR:-10.0.0.0}"

# Simulate or apply
if $dry_run; then
  echo "🧪 Dry-run mode activated"
  echo "Would run: pvecm create ${CLUSTER_NAME:-pve-cluster01} --bindnetaddr ${BINDNETADDR:-10.0.0.0}"
else
  echo "🚀 Creating cluster..."
  pvecm create "${CLUSTER_NAME:-pve-cluster01}" --bindnetaddr "${BINDNETADDR:-10.0.0.0}"
  echo "🎉 Cluster '${CLUSTER_NAME:-pve-cluster01}' created!"
fi
