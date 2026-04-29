---
name: Commit message는 코드 변경의 한 줄 요약
description: R #<일감번호> 형식의 commit subject에는 일감 제목이 아닌 코드 변경 한 줄 요약이 들어가야 한다
type: feedback
originSessionId: edf8a854-193b-4744-9748-5afac9faa616
---
`R #<ticket>` 형식으로 commit할 때, subject는 **일감 제목을 그대로 복사하지 말고 실제 코드 변경을 한 줄로 요약**해야 한다.

**Why:** 일감 제목은 문제 현상을 서술하는 경우가 많아 어떤 수정이 들어갔는지 git log에서 즉시 파악하기 어렵다. 사용자는 `git log --oneline`만 봐도 변경 의도를 알 수 있는 형태를 선호한다.

**How to apply:**
- 형식: `R #<ticket> <코드 변경 요약>`
- 예시 (212030 같은 티켓): "NFS mount 전 TCP 2049 사전 점검(ProbeNFS) 추가" 같은 식
- 일감 제목을 그대로 쓴 과거 사례(예: `R #210734 [SAN | Shared LUN] FC multipath 중 1개 링크를 down 후 up하였을 때, ...`)는 따라하지 말 것
- 사용자가 직접 수정한 commit history와 일관되게: 무엇을 고쳤는가가 한눈에 보이도록