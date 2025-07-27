#!/bin/bash

# Usage : ./config_cluster.sh <node>
NODE="$1"
if [[ -z "$NODE" ]]; then
  echo "❌ Usage: $0 <node>"
  exit 1
fi

echo "🔧 Configuration du nœud : $NODE"

# Définition des paramètres
case "$NODE" in
  pve01)
    MGMT_IF="enp100s0"
    IP="10.1.2.11"
    TB_IF1="en05"
    TB_IF2="en06"
    IPV6_1="fc00::81:1"
    IPV6_2="fc00::81:2"
    RID="1.1.1.1"
    ;;
  pve02)
    MGMT_IF="enp114s0"
    IP="10.1.2.12"
    TB_IF1="en05"
    TB_IF2="en06"
    IPV6_1="fc00::82:1"
    IPV6_2="fc00::82:2"
    RID="1.1.1.2"
    ;;
  pve03)
    MGMT_IF="enp114s0"
    IP="10.1.2.13"
    TB_IF1="en05"
    TB_IF2="en06"
    IPV6_1="fc00::83:1"
    IPV6_2="fc00::83:2"
    RID="1.1.1.3"
    ;;
  *)
    echo "❌ Nœud inconnu : $NODE"
    exit 1
    ;;
esac

DATE=$(date +%F)
BACKUP_DIR="/root/conf-backup/$DATE"

echo "📦 Sauvegarde des fichiers sur $NODE..."
ssh "$NODE" "mkdir -p $BACKUP_DIR && \
  cp /etc/network/interfaces $BACKUP_DIR/interfaces.bak && \
  cp /etc/frr/frr.conf $BACKUP_DIR/frr.conf.bak"

echo "✍️ Génération des nouvelles configurations..."

# Fichier network/interfaces
ssh "$NODE" "cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $MGMT_IF
iface $MGMT_IF inet manual

auto vmbr0
iface vmbr0 inet dhcp
  bridge-ports $MGMT_IF
  bridge-stp off
  bridge-fd 0

auto vmbr0.2
iface vmbr0.2 inet static
  address $IP
  netmask 255.255.255.0
  gateway 10.1.2.254
  bridge-ports none
  bridge-stp off
  bridge-fd 0

auto $TB_IF1
iface $TB_IF1 inet manual
  mtu 9000
iface $TB_IF1 inet6 static
  address $IPV6_1
  netmask 64

auto $TB_IF2
iface $TB_IF2 inet manual
  mtu 9000
iface $TB_IF2 inet6 static
  address $IPV6_2
  netmask 64

post-up ip -6 route add fc00::/7 dev $TB_IF1
post-up ip -6 route add fc00::/7 dev $TB_IF2
EOF"

# Fichier FRR
ssh "$NODE" "cat > /etc/frr/frr.conf <<EOF
frr version 8.4
frr defaults traditional
hostname $NODE
log file /var/log/frr/frr.log

interface $TB_IF1
 ipv6 ospf6 cost 10
 ipv6 ospf6 hello-interval 5
 ipv6 ospf6 dead-interval 20

interface $TB_IF2
 ipv6 ospf6 cost 10
 ipv6 ospf6 hello-interval 5
 ipv6 ospf6 dead-interval 20

router ospf6
 router-id $RID
 interface $TB_IF1 area 0.0.0.0
 interface $TB_IF2 area 0.0.0.0
 redistribute connected
EOF"

# Vérifications post-déploiement
echo "🔍 Vérification réseau + services sur $NODE..."
ssh "$NODE" "
  echo '📡 DNS court & FQDN :'; getent hosts $NODE; getent hosts $NODE.ad.famille-clerc.com
  echo '🧩 corosync links :'; cat /etc/pve/corosync.conf | grep -A2 'link'
  echo '🔍 Quorum status :'; pvecm status | grep -E 'Quorate|Vote'
  echo '📮 Ceph public_network :'; ceph config show | grep public_network
  echo '🧪 Ceph status :'; ceph -s | grep mon
  echo '📶 Routes IPv6 fc00:: :'; ip -6 route | grep fc00
  echo '🔁 Service FRR :'; systemctl is-active frr && systemctl status frr --no-pager | head -n 8
"

echo "✅ Configuration terminée sur $NODE"
