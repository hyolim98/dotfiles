# Debug Runbook

SQA가 버그를 제보했을 때, 증상으로부터 확인할 로그/파드/백엔드 상태를 빠르게 찾기 위한 문서 모음.

Claude가 이 문서를 기반으로:
1. SQA 리포트 분석 → 관련 서브시스템 판단
2. 해당 파드/데몬 로그 수집
3. 상태 체크 커맨드 실행
4. 코드 지점과 대조해 가설 제시

## 구조

| 파일 | 다룰 범위 |
|---|---|
| [storage.md](storage.md) | Ceph, Cinder, PWL cache, 볼륨, RBD, 스냅샷 관련 |
| _향후 추가 예정_ | compute, network, identity, backup, migration 등 팀별 확장 |

## 기본 사실

- **대부분의 admin-core 기능은 `psm-cm` 파드에서 돈다.** 로그 첫 포인트: `kubectl logs deployment/psm-cm`
- OpenStack은 **Kolla**로 배포됨. 각 서비스 로그: `/var/log/kolla/<service>/`
- Ceph 로그: `/var/log/ceph/` + `ceph health detail`, `ceph -s`, `ceph osd tree`, `ceph df`
- 변형 분기: `CODE_NAME=psm-rocky` (Rocky, PCVM 없음) vs Ubuntu (PCVM 있음). 로그 접근 경로가 다를 수 있음.

## 사용 패턴

SQA가 준 증상 텍스트를 붙여 넣고 "분석해줘"라고 하면 됨. Claude가 증상 키워드로 이 인덱스를 스캔해서 해당 섹션의 체크리스트를 순서대로 실행.
