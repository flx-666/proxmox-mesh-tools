#!/bin/bash

echo "📦 Génération Ceph.conf → /etc/pve/ceph.conf"

# Sécurité : sauvegarde préalable
BACKUP="/etc/pve/ceph.conf.backup.$(date +%F_%H-%M)"
cp /etc/pve/ceph.conf "$BACKUP" 2>/dev/null && echo "🧾 Backup : $BACKUP"

# FSID aléatoire
FSID=$(uuidgen)

# Génération du fichier
cat <<EOF > /etc/pve/ceph.conf
[global]
fsid = $FSID
mon_initial_members = pve01, pve02, pve03
mon_host = fc00::80:1,fc00::80:2,fc00::80:3
public_network = fc00::80::/64
cluster_network = fc00::80::/64

auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

ms_bind_ipv6 = true
ms_cluster_mode = legacy
mon_allow_pool_delete = true
mon_data_avail_crit = 5
mon_data_avail_warn = 10
osd_pool_default_size = 2
osd_pool_default_min_size = 1
osd_pool_default_pg_num = 64
osd_pool_default_pgp_num = 64
osd_crush_chooseleaf_type = 1
osd_max_backfills = 2
osd_recovery_max_active = 1
osd_scrub_begin_hour = 0
osd_scrub_end_hour = 6
osd_scrub_sleep = 0.1
osd_deep_scrub_interval = 604800
osd_deep_scrub_stride = 1048576
osd_scrub_priority = 3
osd_deep_scrub_priority = 3

[client]
keyring = /etc/pve/priv/\$cluster.\$name.keyring

[client.crash]
keyring = /etc/pve/ceph/\$cluster.\$name.keyring

[mds]
keyring = /var/lib/ceph/mds/ceph-\$id/keyring

[mds.pve01]
host = pve01
mds_standby_for_name = pve

[mds.pve02]
host = pve02
mds_standby_for_name = pve

[mds.pve03]
host = pve03
mds_standby_for_name = pve

[mon.pve01]
public_addr = fc00::80:1

[mon.pve02]
public_addr = fc00::80:2

[mon.pve03]
public_addr = fc00::80:3
EOF

echo "✅ ceph.conf généré avec succès"
