---
name: project_cctv_pwl_test
description: CCTV 워크로드에서 PWL 캐시 무익 입증 실험 (사업실/일감
metadata: 
  node_type: memory
  type: project
  originSessionId: 116f2cfd-2008-4f90-a231-d68d5e08af3a
---

POPCON이 CCTV 관제 사업에 투입될 때 **PWL 쓰기 캐시가 효과 없음(고밀도엔 손해)** 을 벤치마크로 입증해 사업실에 제시하는 작업. 이후 PWL이 효과적인 케이스(OLTP/varmail)도 대조군으로 제시 예정.

- **근거 일감 #181369** (천안아산): 서버 14대 / CCTV 4000채널 / 채널당 월 1TB → 채널당 ~3Mbps. 노드당 4000÷14≈286채널, ÷6VM ≈ **48채널/VM**.
- **설계**: CCTV 녹화 워크로드(48 순차 append 스트림 = 채널, 버퍼드, throttle 4Mbps/8Mbps), **VM 6개 고정(같은 호스트, 로컬 PWL SSD 공유)**, PWL on/off 비교, 20분. 핵심 지표 = 합산 throughput + 호스트 PWL SSD iostat.
- **핵심 논리**: CCTV는 버퍼드 쓰기 → page cache가 복제지연 흡수 → PWL 무익. throttle 필수(안 하면 버스트라 PWL이 거짓으로 좋아 보임).

**도구 결론 (중요, 반복 삽질 방지):**
- **filebench 1.5-alpha3의 rate-limiting(eventgen/bwlimit)은 48-스레드에서 망가짐.** `target=`(공식 videoserver.f 문법) 빠진 것까지 고쳐도 불안정(35MB/s·60초 stall·파일풀 고갈 크래시). → **throttle은 fio로** (`rate=512k`/job ×48 = 24MB/s 정확 확인됨).
- filebench의 워크로드 모델링(create/append/close/delete 회전)은 정상이나, throttle을 못 해서 fio 채택.

**환경/파일:**
- 작업물: `/data/cctv-pwl-test/` (cctv.fio, README.md, jammy-cctv-admin.img)
- 테스트 VM 이미지: jammy 클라우드이미지 + virt-customize로 admin/Admin123! 구움. **이 클러스터는 DHCP off** → static IP 또는 Config Drive 필요. PWL은 **librbd 경로(VM/rbd-nbd)** 에서만 동작(krbd X).

관련: [[feedback_justify_parameters]] [[user_role]]
