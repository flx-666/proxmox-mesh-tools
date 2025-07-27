#!/bin/bash

# Usage : ./rollback_conf.sh <node> <date: YYYY-MM-DD>
NODE="$1"
DATE="$2"

if [[ -z "$NODE" || -z "$DATE" ]]; then
  echo "❌ Usage: $0 <node> <date (YYYY-MM-DD)>"
  exit 1
fi

echo "🔁 Rollback des fichiers de configuration sur $NODE à la date $DATE..."

BACKUP_DIR="/root/conf-backup/$DATE"

# Vérification préliminaire
ssh "$NODE" "test -f $BACKUP_DIR/interfaces.bak && test -f $BACKUP_DIR/frr.conf.bak"
if [[ $? -ne 0 ]]; then
  echo "❌ Fichiers de sauvegarde introuvables pour $NODE à $DATE"
  exit 1
fi

# Restauration
echo "📦 Restauration des fichiers..."
ssh "$NODE" "
  cp $BACKUP_DIR/interfaces.bak /etc/network/interfaces &&
  cp $BACKUP_DIR/frr.conf.bak /etc/frr/frr.conf &&
  systemctl restart networking &&
  systemctl restart frr
"

# 🔍 Vérifications post-restauration
echo "🔎 Validation après rollback sur $NODE..."
ssh "$NODE" "
  echo '📡 Résolution DNS :';
  getent hosts $NODE
  getent hosts $NODE.ad.famille-clerc.com

  echo -e '\n🧩 corosync.conf (liens Link0 / Link1) :';
  grep -A2 'link' /etc/pve/corosync.conf

  echo -e '\n🔍 Quorum Proxmox :';
  pvecm status | grep -E 'Quorate|Vote|Node'

  echo -e '\n📮 Réseau Ceph (IPv6 mesh attendu) :';
  ceph config show | grep public_network
  ceph -s | grep mon

  echo -e '\n🔁 Service FRR :';
  systemctl is-active frr
  systemctl status frr --no-pager | head -n 10

  echo -e '\n📶 Routage IPv6 vers mesh (fc00::/7) :';
  ip -6 route | grep fc00

  echo -e '\n🧪 ping6 vers voisins :';
  ping6 -c 2 fc00::82:1 || echo '⚠️ ping échoué vers pve02'
  ping6 -c 2 fc00::83:1 || echo '⚠️ ping échoué vers pve03'
"

echo "✅ Rollback terminé pour $NODE ✔️"
