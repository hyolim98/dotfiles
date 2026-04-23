---
name: POPCON product context
description: POPCON HCI — private cloud platform with Ubuntu (PCVM-based) and Rocky variants; Skyline-based UI
type: project
originSessionId: ca3ba225-f699-48ab-89ed-3c9069defb66
---
User's company builds **POPCON**, a private cloud HCI platform.

**Two build/runtime variants (gated by `CODE_NAME` env):**
- **Ubuntu variant** — runs inside a **PCVM** (POPCON Control VM) that hosts k3s and the management containers. Docs under `docs/psm-quick-start-guide.md` describe this flow.
- **Rocky variant** (`CODE_NAME=psm-rocky`, currently active branch `psm-rocky`) — **no PCVM**. Runs differently (likely directly on the host, not wrapped in a management VM). Uses MongoDB 8.0, k3s-v1.30, `Dockerfile.rocky`.

**Stack:**
- End-user web UI based on **OpenStack Skyline**
- OpenStack deployed via **Kolla/Kolla-Ansible** (logs under `/var/log/kolla/`, e.g. `cinder/`, `nova/`, `neutron/`)
- Storage backend: **Ceph** (logs under `/var/log/ceph/`)
- Control plane in k3s: `psm-cm` pod (most functionality lives here), `psm-api`, `psm-*` family

**How to apply:**
- Don't assume PCVM when the user is on `psm-rocky` — ask or check `CODE_NAME`
- When debugging, logs most likely lie in three places: `kubectl logs deployment/psm-cm`, `/var/log/kolla/<service>/`, `/var/log/ceph/`
- `ceph health detail` + OSD/pool status are routine first checks for any storage-related symptom
- Skyline = browser UI; Playwright MCP useful for reproducing UI-reported bugs

**Reference files (read on demand, not auto-loaded):**
- `~/.claude/admin-core/CLAUDE.md` — admin-core architecture, build/deploy commands, conventions. Read when user asks about build, deploy, code layout, or mentions a specific service/package.
- `~/.claude/admin-core/docs/debug/storage.md` — storage debug runbook (Ceph/Cinder/PWL/SAN). Read when analyzing a storage-related bug report.
- `~/.claude/admin-core/docs/debug/README.md` — debug runbook index.
