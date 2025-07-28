![CI Network Checks](https://github.com/famille-clerc/proxmox-mesh-tools/actions/workflows/network-check.yml/badge.svg)
![Shell Linter](https://github.com/famille-clerc/proxmox-mesh-tools/actions/workflows/shellcheck.yml/badge.svg)
# 🔗 proxmox-mesh-tools/scripts — Mesh Provisioning Toolkit

Modular scripts for building a loopback-based mesh fabric across your Proxmox nodes. The system configures IPv6 overlays, Thunderbolt peer links, BGP routes, and Ceph + Corosync services without touching `/etc/network/interfaces` directly. All mesh-related configs are modular and sourced cleanly.

---

## 📁 Flat Description of Files

| Filename                   | Description |
|----------------------------|-------------|
| `.env.example`             | Environment variable template with cluster-wide settings: node maps, mesh IPs, Thunderbolt interfaces, ring IPs, DNS search domains. |
| `README.md`                | Setup overview and recovery guidance. |
| `config_cluster.sh`        | Base dispatcher script, calls individual modules in order. |
| `config_cluster_ceph.sh`   | Generates `ceph.conf` with mesh IPv6 overlay; configures MON/MDS. |
| `config_cluster_frr.sh`    | BGP mesh config between loopback IPs via FRRouting. |
| `config_cluster_dns.sh`    | Adds DNS forwarders and multiple search domains to mesh interface. |
| `config_cluster_pvecm.sh`  | Generates dual-ring Corosync config and handles optional `pvecm join`. |
| `validate_mesh.sh`         | Verifies `.env` completeness, IP/interface sanity, and sourcing for `interfaces.d`. |
| `rollback_conf.sh`         | Reverts generated mesh fragments cleanly. |

---

## 🧪 Runtime Behavior

Scripts will:

- 🛡️ Modify only `/etc/network/interfaces.d/thunderbolt`
- 🔍 Verify presence of `source /etc/network/interfaces.d/*` in `/etc/network/interfaces`
- 🧪 Support dry-run mode via `DRY_RUN=1` flag
- 🧠 Parse `.env` mappings for per-node IPs and NICs
- 🌐 Handle dual-stack addressing (IPv6 + IPv4)
- 🔁 Support rollback with `rollback_conf.sh`

---

## 📦 Required Setup

Copy `.env.example` and adjust per your cluster topology:

```bash
cp .env.example .env
