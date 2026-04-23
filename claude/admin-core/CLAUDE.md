# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product Context

`admin-core` is the control plane for **POPCON**, a private cloud HCI (Hyperconverged Infrastructure) appliance. It manages OpenStack (compute/network/identity/image), Ceph (storage), hosts, clusters, backup, DR, alerts, and licensing. The end-user web UI is based on OpenStack Skyline.

Go module path: `git.piolink.com/phci` (Go 1.26).

## Repository Shape

This is a **multi-binary monorepo**. Each directory under `cmd/` is an independent Go binary that compiles into its own container image and runs as a k3s pod. They communicate over gRPC using protobufs defined in a **separate repo** (`phci-idl`).

- `cmd/<service>/` — service binaries (api-gateway, auth, resource, controllerManager, alert, backup, disasterRecovery, billing, vmware, migration, license, integration, recentTasks, maintenance, host-periodic-tasks, hc, pupdate, phainstaller, systemAssistant)
- `cmd/{pcli,poctl,pinit,padm}` — CLI tools
- `cmd/pcm-ui/` — UI container (only built on Ubuntu)
- `pkg/server/<service>/` — per-service business logic (matches `cmd/<service>/`)
- `pkg/pcsm/` — **POPCON Cloud Service Manager**: thin layer over OpenStack (gophercloud) for compute/identity/image/network/storage/lbaas/masakari
- `pkg/dao/` — MongoDB data access (uses `pkg/dao/serviceDao/v2/` with `dummy/` JSON fixtures for dev)
- `pkg/ceph/`, `pkg/openstack/`, `pkg/k8s/`, `pkg/storage/`, `pkg/system/`, `pkg/utils/` — cross-cutting libraries
- `api/` → **symlink to `phci-idl/idl/`** (auto-created by `make phci-idl`). Never edit generated code here; edit the `.proto` files in `phci-idl` and rebuild.
- `phci-idl/` — cloned sibling repo for protobuf/IDL definitions
- `pcvm-compose/` — docker-compose for the registry + apt mirror that PSM uses on the PCVM VM
- `pbs`, `pbs2` — PCVM boot/setup scripts, run separately via their own Makefiles
- `contrib/` — auxiliary helper binaries installed alongside CLIs (dedup, forecast, mirror, zram)
- `tools/drctl/` — registry image mgmt (pull-pcon, push-pcon, rm-pcon)

Services talk to each other through `cmd/api-gateway` (HTTP/gRPC entrypoint) and are authenticated via `cmd/auth`. `cmd/controllerManager` (binary name: `pcm`) is the central orchestrator.

## Build System

Top-level `Makefile` fans out to each `cmd/<subdir>/Makefile`, which includes `cmd/common.Makefile` for shared targets. Build artifacts land in `dist/binary/` and `dist/container/`.

### Required env vars (have defaults)

- `CODE_NAME` — **`psm-rocky`** (current active branch) vs older `psm-*`. On `psm-rocky`: MongoDB 8.0, k3s-v1.30, `Dockerfile.rocky`.
- `VER` / `CONTAINER_TAG` — image tag (default `db02`)
- `REPO_SERV` — local docker registry, default `pcvm:8282`
- `TARGET_BRANCH` — phci-idl branch to clone (default `master`; dev usually `psm-rocky`)

### Common commands

| Task | Command |
|---|---|
| Full build (tidy + idl + all services) | `make build` |
| Build + images + push | `make && make mk-docker-img && make push-docker-img` |
| Build **one** service | `cd cmd/<service> && make && make mk-docker-img && make push-docker-img` |
| Regenerate protobuf (IDL) | `make phci-idl` (clones/updates `phci-idl/`, runs its `make`) |
| Deploy rebuilt image to live cluster | `kubectl set image deployment/<name> <name>=pcvm:8282/cvm/<img>:latest` then `kubectl delete pod <POD>` |
| Run services locally (dev, tmux) | `make run` → attach with `tmux attach -t phci` |
| Stop dev session | `make stop` |
| Run distributed binaries locally | `make run-binaries` / `make stop-binaries` |
| Tests (all services) | `make test` |
| Tests (one package) | `cd pkg/<dir> && go test ./...` or `go test -run TestName ./pkg/<dir>` |
| Lint | `make lint` (installs `golangci-lint` on first run via `make install-lint`) |
| Clean builds | `make clean` (artifacts) / `make distclean` (everything incl. data) |

Binary names don't always match directory names — e.g. `cmd/controllerManager` produces `pcm`, `cmd/api-gateway` produces `api-gateway`, UI pod is `psm-api`/`psm-cm`. Check the service's `Makefile` (`BINARY_NAME=`, `CONTAINER_NAME=`) when in doubt.

## Deploy / Debug Loop

Runtime differs by variant:
- **Ubuntu variant**: management plane runs inside a **PCVM** (POPCON Control VM) hosting k3s + pods
- **Rocky variant** (`CODE_NAME=psm-rocky`): **no PCVM**; k3s/pods run directly on the host. Don't assume PCVM paths on Rocky.

Typical edit→deploy cycle:

1. Edit Go source under `pkg/` and/or `cmd/<svc>/`
2. `cd cmd/<svc> && make && make mk-docker-img && make push-docker-img`
3. `kubectl set image deployment/<name> <name>=pcvm:8282/cvm/<img>:latest`
4. `kubectl delete pod <POD_NAME>` (forces redeploy of the new image)

If a `.proto` file changed: rebuild `phci-idl` first (`cd phci-idl/idl && make`), then rebuild **every** consuming service (commonly at least `psm-api`).

Configs live at `/etc/phci/` on the runtime host; `make install-etc` copies from `etc/phci/` and `cert/`. Cluster-critical IP `10.0.0.10` (br_cvm) is hard-coded — don't change it in dev configs.

### Bug analysis — where to look first

Most bugs surface in one of these log locations:

- **Control plane pod**: `kubectl logs deployment/psm-cm` — the majority of admin-core functionality runs here. Start here for almost any admin-plane bug.
- **OpenStack (Kolla-deployed)**: `/var/log/kolla/<service>/` on the host — `cinder/`, `nova/`, `neutron/`, `glance/`, `keystone/` etc.
- **Ceph**: `/var/log/ceph/` on the host — MON, OSD, MGR, MDS daemon logs. Always pair with `ceph health detail`, `ceph -s`, `ceph osd tree`, `ceph df`.

See `docs/debug/` for the symptom→service→log runbook.

## Conventions Worth Knowing

- **Never edit anything under `api/`** — it's a symlink to generated IDL code. Edit the `.proto` files in `phci-idl/idl/` and rebuild.
- **`3rd/` is vendored forks** (gophercloud, elogrus, goph) with local patches — treat as third-party, don't refactor casually.
- Dummy JSON fixtures under `pkg/dao/serviceDao/v2/*/dummy/` are deployed to `/opt/phci/etc/dummy/` by `make run` and used when MongoDB/real backends aren't available. Keep them in sync if you change DAO shapes.
- Version info is injected at link time via `PSM_LDFLAGS` (see `cmd/common.Makefile`) into `pkg/config.{VERSION,GitCommit,CodeName}` — don't hardcode these.
- Build targets use `-tags netgo` and `strip` — pure-Go networking, statically linked where possible.
- Ubuntu vs Rocky branching is gated by `CODE_NAME`; Rocky path uses `Dockerfile.rocky`. UI container only builds on Ubuntu hosts (`$(UBUNTU) = true` check in top-level Makefile).

## External Dependencies (context for bugs)

- **OpenStack** via `github.com/gophercloud/gophercloud` — wrapped in `pkg/pcsm/`
- **Ceph** via `github.com/ceph/go-ceph` — wrapped in `pkg/ceph/`
- **MongoDB** via official driver — wrapped in `pkg/dao/`
- **Kubernetes/k3s** via `client-go` / kubectl shells — wrapped in `pkg/k8s/`
- **Elasticsearch v7**, **Ansible** (apenella/go-ansible), **wkhtmltopdf**, **SNMP** (gosnmp), **go-git** for various operational tasks

When bugs involve "waiting on instance creation", "Ceph pool state", "Kolla deploy", etc., suspect the wrapper layers above before the upstream libs.

## Team Workflow Notes

- **Redmine is the source of truth** for bug root cause, fix rationale, and feature design. Git commits alone won't tell the full story — if a Redmine ticket ID is referenced, fetch it for context.
- Active branch is typically **`psm-rocky`** (not `master`).
- phci-idl pushes require switching its `.git/config` URL from `git://...` to `ssh://...` (read-only clone URL vs push URL).
