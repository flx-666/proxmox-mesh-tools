![CI Network Checks](https://github.com/famille-clerc/proxmox-mesh-tools/actions/workflows/network-check.yml/badge.svg)
![Shell Linter](https://github.com/famille-clerc/proxmox-mesh-tools/actions/workflows/shellcheck.yml/badge.svg)
# proxmox-mesh-tools 🚀

Scripts pour rollback et validation réseau mesh IPv6 dans une infra Proxmox + Ceph + FRR.

## 🌐 Objectifs

- Restauration des fichiers critiques (`interfaces`, `frr.conf`)
- Validation réseau post-rollback
- Vérification Ceph, quorum HA, DNS, ping IPv6 mesh
- Routage dynamique OSPF via FRR

## 📂 Structure
proxmox-mesh-tools/
├── Makefile
├── README.md
└── .gitignore
└── scripts/
    ├── config_cluster_dns.sh          # DNS + hostnames + résolvabilité
    ├── config_cluster_frr.sh          # Configuration dynamique de /etc/frr/frr.conf
    ├── config_cluster_ceph.sh         # Génère /etc/pve/ceph.conf depuis pve01
    ├── config_cluster_pvecm.sh        # Validation du cluster Proxmox
    ├── rollback_conf.sh               # Roll back sur config sauvegardée
    └── validate_mesh.sh               # Validation du cluster Proxmox



---

## 🧪 Scripts

| Script               | Fonction principale                                            |
|---------------------|----------------------------------------------------------------|
| `rollback_conf.sh`  | Restaure la conf réseau et relance les services                |
| `validate_mesh.sh`  | Vérifie connectivité, Ceph, DNS, quorum et ping IPv6 mesh      |
| `Makefile`          | Lance les scripts facilement depuis le nœud maître (`pve01`)   |

---

## 🔧 Utilisation rapide

```bash
# Rollback config réseau pour le nœud spécifié
make rollback NODE=pve02 DATE=2025-07-26

# Validation complète du nœud réseau
make validate NODE=pve02
