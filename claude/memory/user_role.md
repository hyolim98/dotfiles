---
name: User role — Storage team on POPCON
description: User is on the Storage team for POPCON HCI; responsibilities center on Ceph, OpenStack Cinder, and storage-related pods/services
type: user
originSessionId: ca3ba225-f699-48ab-89ed-3c9069defb66
---
User is on the **Storage team** for POPCON HCI.

**Primary responsibilities (inferred):**
- Ceph cluster health and daemons
- OpenStack Cinder (block storage service)
- Storage-related code in admin-core: `pkg/pcsm/storage/`, `pkg/server/controllerManager/storage/` (incl. PWL cache), `pkg/ceph/`, `pkg/storage/`
- Tickets tagged `[PWL]`, `[SAN]`, `[SAN | Shared LUN]`, `[PCS-UI | Storage]`, Ceph/Cinder-related

**How to apply:**
- When the user reports a bug, bias investigation toward storage-path first: Ceph (`ceph health detail`, OSD state, pool state), Cinder (`/var/log/kolla/cinder/`), PWL cache code, RBD, volume lifecycle
- Explanations of non-storage areas (auth, api-gateway, UI) can be shorter — they care about the interface, not the internals
- For code reviews, pay extra attention to storage edge cases: concurrent access, pool full, OSD down, rbd lock, snapshot consistency
