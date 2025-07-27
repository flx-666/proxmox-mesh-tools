#!/bin/bash

# Usage: ./validate_mesh.sh <node>
NODE="$1"

if [[ -z "$NODE" ]]; then
  echo "❌ Usage: $0 <node>"
  exit 1
fi

echo "🔎 Vérification du nœud mesh : $NODE"

ssh "$NODE" "
  echo -e '\n📡 Résolution DNS courte et FQDN :'
  getent hosts $NODE
  getent hosts ${NODE}.ad.famille-clerc.com

  echo -e '\n🧩 corosync.conf :'
  grep -A2 'link' /etc/pve/corosync.conf

  echo -e '\n🔍 Quorum Proxmox :'
  pvecm status | grep -E 'Quorate|Vote|Node'

  echo -e '\n📮 Ceph public_network :'
  ceph config show | grep public_network

  echo -e '\n🧮 Ceph status :'
  ceph -s | grep -E 'health|mon'

  echo -e '\n🔁 Service FRR :'
  systemctl is-active frr
  systemctl status frr --no-pager | head -n 10

  echo -e '\n📶 Routes IPv6 vers fc00:: :'
  ip -6 route | grep fc00

  echo -e '\n🧪 Ping IPv6 mesh :'
  ping6 -c 2 fc00::82:1 || echo '⚠️ ping échoué vers fc00::82:1'
  ping6 -c 2 fc00::83:1 || echo '⚠️ ping échoué vers fc00::83:1'
"

echo "✅ Validation terminée. Vérifie les résultats ci-dessus."
#!/bin/bash

# Usage: ./validate_mesh.sh <node>
NODE="$1"

if [[ -z "$NODE" ]]; then
  echo "❌ Usage: $0 <node>"
  exit 1
fi

echo "🔎 Vérification du nœud mesh : $NODE"

ssh "$NODE" "
  echo -e '\n📡 Résolution DNS courte et FQDN :'
  getent hosts $NODE
  getent hosts ${NODE}.ad.famille-clerc.com

  echo -e '\n🧩 corosync.conf :'
  grep -A2 'link' /etc/pve/corosync.conf

  echo -e '\n🔍 Quorum Proxmox :'
  pvecm status | grep -E 'Quorate|Vote|Node'

  echo -e '\n📮 Ceph public_network :'
  ceph config show | grep public_network

  echo -e '\n🧮 Ceph status :'
  ceph -s | grep -E 'health|mon'

  echo -e '\n🔁 Service FRR :'
  systemctl is-active frr
  systemctl status frr --no-pager | head -n 10

  echo -e '\n📶 Routes IPv6 vers fc00:: :'
  ip -6 route | grep fc00

  echo -e '\n🧪 Ping IPv6 mesh :'
  ping6 -c 2 fc00::82:1 || echo '⚠️ ping échoué vers fc00::82:1'
  ping6 -c 2 fc00::83:1 || echo '⚠️ ping échoué vers fc00::83:1'
"

echo "✅ Validation terminée. Vérifie les résultats ci-dessus."
