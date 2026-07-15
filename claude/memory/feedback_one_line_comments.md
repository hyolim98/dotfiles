---
name: one-line-comments
description: 새 코드 작성 시 함수/상수 docstring 은 1줄로 유지 — 여러 줄 docstring 거부 패턴
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 56e21068-4271-45b6-b6be-2bbb766f16ca
---

함수 docstring, 상수 블록 주석, 인라인 주석은 모두 1줄 이내로 작성. 여러 줄 docstring 금지.

**Why:** 사용자가 코드 리뷰 중 "주석은 간단하게 1줄로 해줘" 라고 명시적으로 거부 후 재작성 요청. 긴 설명 docstring 을 싫어하는 일관된 선호.

**How to apply:** 새 함수/상수 작성 시 주석은 한 줄. "why" 가 비자명하면 한 줄에 압축. 여러 줄 설명이 필요한 경우는 일감 문서나 PR description 에 적고 코드에는 안 둠. [[feedback_redmine_md_bullet_layout]] 의 간결성 선호와 일관됨.
