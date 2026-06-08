---
name: feedback_toggle_details
description: 토글/접이식 콘텐츠는 Redmine collapse 매크로 말고 <details> HTML로 작성
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 116f2cfd-2008-4f90-a231-d68d5e08af3a
---

문서(특히 Redmine md)에서 접이식 토글을 넣을 때는 **항상 `<details><summary>제목</summary> ... </details>` HTML 형식** 사용. Redmine `{{collapse}}` 매크로 쓰지 말 것.

**Why:** 사용자 지침 (명시적으로 요청).
**How to apply:** 긴 코드블록·스크립트 등을 접어둘 때 `<details>`로 감쌈. 관련: [[feedback_redmine_md_bullet_layout]]
