---
name: feedback_justify_parameters
description: User pushes back on arbitrary tuning values; ground every parameter in a concrete basis
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 116f2cfd-2008-4f90-a231-d68d5e08af3a
---

테스트/벤치마크 파라미터(파일 크기, 세그먼트 크기, iosize, thread 수 등)를 제시할 때 "적당히", "보통 이정도" 같은 임의값으로 주면 사용자가 반드시 근거를 되묻는다. 예: filebench 세그먼트 64MB·파일 1GB를 임의로 제시했다가 "왜 64야/왜 1GB야" 지적받음.

**Why:** 사용자는 사업실 발표·일감 근거로 쓸 실험을 설계 중이라, 모든 수치가 "현실 근거(예: 실제 NVR 세그먼트 길이, 일감 #181369의 비트레이트)"로 방어 가능해야 함.

**How to apply:** 값 제시할 때마다 (1) 그 값이 무엇을 좌우하는지, (2) 무엇과는 무관한지, (3) 현실/일감 기반 근거를 함께 제시. 임의값이면 "임의"라고 솔직히 밝히고 근거 있는 대안을 제안. 관련: [[project_cctv_pwl_test]]
