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
 ├── scripts/
 	│
 	├── rollback_conf.sh
 	│
 	└── validate_mesh.sh
 ├── Makefile
 ├── README.md
 └── .gitignore

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
