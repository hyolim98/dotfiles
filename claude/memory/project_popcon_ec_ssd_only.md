---
name: project_popcon_ec_ssd_only
description: "POPCON EC 풀은 SSD 전용 정책(#127099) — HDD EC는 주석처리, CCTV EC-on-HDD를 막는 근본 원인"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2e3b891d-3e50-4d24-a8d1-a3cfa8f4123d
---

POPCON은 **EC(erasure-coded) 풀을 SSD/NVMe에만** 자동 생성한다. **HDD EC는 의도적으로 비활성화**(코드에 주석으로만 존재) → CCTV가 원하는 EC-on-HDD를 막는 근본 원인. [[project_cctv_pwl_test]]

- **근거 일감 #127099** (사업팀 결정, 2023-06): EC는 SSD에만 적용하도록 제한. 사유 = ① EC-on-HDD **속도 저하 우려**, ② **VMware vSAN도 Hybrid 구성에선 EC/압축/중복제거 미지원**(선례). 3벌복제는 HDD 허용, **EC만 SSD 전용** 확정.
- **구현**: `bp.service.ceph/actions/cephadm/config.py` `fill_ecpool_datapool()` — `ec_*_ssd`만 활성, `_hdd`/`_nvme` 변종은 주석. 커밋 `28e13f4d` ("erasure coding 은 ssd 에만 구동되도록"). EC 프로파일은 jerasure, k/m = 2+1·2+2·4+2·8+3 (1E/2E/3E/4E), failure-domain=host, `allow_ec_overwrites=true`, 짝 replicated 메타 풀 생성.
- **설치 게이트**: `ecpool_enabled`(기본 true, admin-core) + `disk_per_host>=3` + `osd_host_count>=k+m`(3/4/6/11) + ssd/nvme device-class 존재 + openstack_enabled.
- **UI 경로(V2 `POST /psmapi/v2/.../storage/pool`)**: `poolType:"erasure"` 받긴 하나 k/m/device-class/메타페어링 없이 `osd pool create erasure`만 → **Ceph default k2m1로 떨어지고 Cinder 연결도 차단** → 운영용 EC 생성 불가. V1·CLI는 EC 거부.

**CCTV 핵심**: SSD-only 정책은 "일반 VM 랜덤 IO엔 EC-on-HDD가 느리다"는 전제. CCTV는 large sequential이라 그 전제가 깨짐(read-modify-write 페널티 없음) → EC-on-HDD가 오히려 이상적. **CCTV EC-on-HDD 정공법 = 주석처리된 hdd EC 변종 활성화(제품/블루프린트 변경 일감)**. 사업팀이 정한 정책이라 사업팀이 재검토 가능.
