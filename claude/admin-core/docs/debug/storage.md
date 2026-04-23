# Storage Debug Runbook

스토리지(Ceph, Cinder, PWL cache, RBD, 볼륨) 관련 버그 분석용. 증상 → 확인할 것 → 관련 코드 순으로 정리.

## 기본 수집 명령 (스토리지 버그라면 거의 항상 실행)

```bash
# 1. Ceph 전반 상태
ceph -s
ceph health detail
ceph osd tree
ceph df
ceph osd pool ls detail

# 2. psm-cm 파드 로그 (최근 + 스토리지 관련 필터)
kubectl logs deployment/psm-cm --tail=500
kubectl logs deployment/psm-cm --tail=2000 | grep -iE "volume|cinder|rbd|ceph|pool|pwl|cache"

# 3. Cinder 로그 (Kolla 배포)
sudo ls /var/log/kolla/cinder/
sudo tail -n 500 /var/log/kolla/cinder/cinder-volume.log
sudo tail -n 500 /var/log/kolla/cinder/cinder-api.log
sudo tail -n 500 /var/log/kolla/cinder/cinder-scheduler.log

# 4. Ceph 데몬 로그
sudo ls /var/log/ceph/
# 증상에 맞는 데몬만 (MON, OSD, MGR, MDS, RGW)
sudo tail -n 500 /var/log/ceph/ceph-mon.*.log
sudo tail -n 500 /var/log/ceph/ceph-osd.<N>.log
```

**실행 위치 주의**: `ceph`, `/var/log/kolla`, `/var/log/ceph` 는 컨테이너가 아니라 **호스트**(또는 Ubuntu 변형에서는 PCVM)에서 접근. `kubectl logs`는 어디서든 kubeconfig만 있으면 가능.

## 증상별 체크리스트

### 볼륨 생성/삭제/첨부 실패

**우선 확인:**
- `cinder list`, `openstack volume show <id>` — 상태가 `error` / `error_deleting` / `creating` 에서 멈춤
- `/var/log/kolla/cinder/cinder-volume.log` — 스택트레이스, RBD 에러, 풀 접근 실패
- `psm-cm` 로그의 `volume`/`cinder` 키워드

**원인 후보:**
- Ceph pool 접근 권한 문제 (keyring, caps)
- Pool full / near-full (`ceph df` 로 확인)
- OSD down으로 placement 실패 (`ceph osd tree`)
- 동시성 문제 — 동일 볼륨에 여러 요청

**관련 코드:**
- `pkg/pcsm/storage/` — Cinder 래퍼
- `pkg/server/controllerManager/storage/` — 볼륨 관련 컨트롤 로직
- `pkg/ceph/` — Ceph 직접 호출 래퍼

### PWL cache 관련 ([PWL] 태그)

**우선 확인:**
- `psm-cm` 로그에서 `pwl`, `cache`, `InstanceWait` 키워드
- 호스트의 `/var/lib/rbd-write-log-cache` 상태와 용량
- 관련 인스턴스 상태: `openstack server show <id>`

**원인 후보:**
- 인스턴스 생성/삭제 대기 타임아웃 (`InstanceWaitRetries`, `InstanceWaitInterval`)
- 호스트별 PWL 적용 상태 불일치 (`HostStatusApplying` 에서 stuck)
- volume type 매핑 문제 (Redmine #211647 참고 — 하드코딩 → ceph pool 기반으로 변경)

**관련 코드:**
- `pkg/server/controllerManager/storage/pwlCache/pwlCache.go` — 핵심 로직
- `InstanceWaitRetries = 1000`, `InstanceWaitInterval = 5` (초) — 타임아웃 튜닝 포인트

### Ceph 자체 이상 (OSD down, pool degraded, slow ops)

**우선 확인:**
```bash
ceph health detail                  # 경고/에러 전체 목록
ceph osd tree                       # down된 OSD
ceph osd perf                       # slow OSD 후보
ceph -w                             # 실시간 이벤트 (몇 초만)
ceph pg dump_stuck                  # stuck PG
```

**관련 로그:**
- `/var/log/ceph/ceph-osd.<N>.log` — 특정 OSD 문제
- `/var/log/ceph/ceph-mon.*.log` — 클러스터 합의, election 문제
- `/var/log/ceph/ceph-mgr.*.log` — 모듈(dashboard, prometheus) 관련

### 공유 LUN / SAN ([SAN], [SAN | Shared LUN] 태그)

**우선 확인:**
- `multipath -ll` — multipath 상태, 경로 down 여부
- `iscsiadm -m session` — iSCSI 세션 상태
- `dmesg | tail -n 200` — 링크 down/up, I/O 에러

**원인 후보:**
- FC/iSCSI 링크 flapping 후 복구 실패 (Redmine #210734 참고)
- LUNZ가 shared lun으로 잘못 인식 (Redmine #211239 참고)

**관련 코드:**
- `pkg/server/controllerManager/` 내 SAN/disk 관련 로직 (경로는 확인 필요)
- `pkg/storage/` 저수준 유틸

### 볼륨 타입 / 쓰기 캐시 / UI 에러 메시지 ([PCS-UI | Storage])

**우선 확인:**
- `psm-api` 로그 — UI에서 호출하는 API 응답 확인
- 볼륨 상태와 type 매핑: `cinder type-list`, `cinder show <vol>`

**관련 코드:**
- `pkg/pcsm/storage/` — 볼륨 타입 변경 API 호출
- UI 에러 메시지는 `cmd/pcm-ui/` 쪽도 영향 가능

## 수집한 정보로 분석할 때 참고

- **에러 키워드 우선순위**: `panic` > `FATAL` > `ERROR` > `WARN`. panic/trace는 반드시 전체 스택 확인.
- **시각 맞추기**: SQA가 제공한 발생 시각 ± 5분 범위로 로그 잘라서 볼 것.
- **Redmine 중복 확인**: 증상이 익숙해 보이면 Redmine에서 유사 티켓 검색 후 원인/해결책 재사용.
- **여러 파드 상관관계**: `psm-cm` → Cinder API → Cinder Volume → Ceph 순으로 요청이 흐르므로 에러는 **상류**(psm-cm)에서 먼저 터졌을 수도, **하류**(Ceph OSD)에서 반사된 것일 수도 있음. 양쪽 타임라인 비교.

## 채워야 할 빈칸 (TODO — 팀에서 내용 보강)

- [ ] 실제 PCVM Ubuntu vs Rocky 환경에서 로그 경로 차이 정리
- [ ] Cinder backend 설정 파일 위치와 주요 옵션
- [ ] 자주 반복되는 증상 → 과거 Redmine 티켓 번호 매핑
- [ ] `ceph` 커맨드 실행 권한 (sudo 필요 여부, 계정)
- [ ] PWL cache 정상 상태일 때의 기준값 (cache 사이즈, 적용 소요 시간 등)
