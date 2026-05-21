---
name: redmine-md-bullet-layout
description: "Redmine 일감 .md (/data/redmine/<id>-<slug>.md) 본문 layout — paragraph 대신 bullet tree. 최상위 `- `, 하위는 한 단계 들여쓴 `  - `."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3348282f-7c68-46c9-b31f-8e8005882730
---

`/data/redmine/<id>-<slug>.md` 파일을 작성/수정할 때 본문 layout 규칙: 섹션 헤더 (##/###) 바로 아래의 모든 내용은 **최상위 불릿 `- `** 로 시작하고, 하위 내용은 한 단계 들여쓴 **`  - `** 로 nesting. paragraph 식 평문 대신 bullet tree 구조 유지. 코드 블록/표는 bullet 의 자식으로 들여쓰기.

**Why:** 사용자가 redmine 본문에 paste 했을 때 일관된 outline 구조로 보이도록. 사용자가 명시적으로 이 layout 을 [[project-redmine-files]] 작성 시 따라달라고 요청.

**How to apply:** 새 redmine md 파일 작성하거나 기존 파일의 §3.1 (문제 분석) / §3.2 (문제 해결) 등 본문 섹션을 다듬을 때 항상 이 layout. paragraph 톤이 자연스러운 설명도 bullet 로 변환. 단 (a) 최상위 헤더 라인 (`# Redmine #...`) 자체, (b) 헤더 직후의 메타 정보(상태/담당/관련 등) 는 이미 bullet 이라 그대로, (c) 인용된 로그/명령은 fenced code block — **`- ` 불릿 prefix 없이** 부모 bullet 의 자식 깊이만큼 tab/space 로만 들여쓰기. 표(table)도 같은 방식.

예:
```
### 3.1.1. 디스크 상태

- 문제 디스크는 다음 상태로 예상됨
  - sector 0 의 PMBR 살아있음
    - PMBR(Protective MBR): GPT 디스크의 sector 0 ...
  - LBA 1 의 primary GPT 헤더 CRC 유효
- 근거 — sgdisk 출력에 명시:
  ```
  Disk size is smaller than the main header indicates! ...
  ```
```
