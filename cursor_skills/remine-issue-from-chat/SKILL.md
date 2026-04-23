---
name: redmine-issue-from-chat
description: 기존 Redmine 일감에 대화 내용을 기반으로 description을 채워 넣는다. "#{번호} 일감 채워줘", "이 작업 내용 Redmine에 반영해줘", "일감 내용 정리해줘" 등의 요청 시 사용. Fills in description of an existing Redmine issue based on completed agent conversation.
---

# Redmine 일감 내용 채우기

에이전트와 논의/해결한 작업 내용을 기존 Redmine 일감의 description에 채워 넣는다.

## 실행 순서

1. 사용자가 일감 번호를 알려줌 (또는 대화에서 파악)
2. `issues_get` 으로 기존 일감 조회 (트래커, subject, 현재 description 확인)
3. 트래커에 맞는 템플릿으로 대화 내용을 description에 작성
4. `issues_update` 로 description 업데이트
5. 업데이트된 이슈 URL 안내

## Description 템플릿

### 기능개선 / 새기능 (tracker_id: 2, 23)

```markdown
{{>toc}}

## 1. 개요

### 1.1. 배경

- [왜 이 작업이 필요한가 — 기존 문제점/한계]

### 1.2. 목표

- [무엇을 달성하려 하는가]

## 2. 기능 개발

### 2.1. 구현

#### 2.1.1. 설계

- [설계 내용, 변경 범위, 영향받는 파일/함수]

#### 2.1.2. 동작 과정

- [구현 방법, 주요 코드, 커밋 링크]

## 3. 테스트

### 3.1. 테스트 과정

- [테스트 절차]

### 3.2. 테스트 결과

- [결과 요약]
```

### 소스코드개선 (tracker_id: 22)

```markdown
## 1. 개요

### 1.1. 배경

- [기존 코드의 문제점]

### 1.2. 목표

- [개선 목표]

## 2. 변경 내용

- 대상 파일/함수:
- 변경 방법:
- 커밋 링크:

## 3. 테스트

### 3.1. 테스트 결과

- [결과 요약]
```

### 버그 (tracker_id: 1)

```markdown
{{TOC}}

## 1. 기본 사항

- 버전   :
- 관련 환경:

## 2. 문제 사항

### 2.1. 문제 발생 배경

### 2.2. 재현 방법

### 2.3. 재현 결과

### 2.4. 기대 결과

### 2.5. 관련 로그

---

## 3. 원인 및 해결

### 3.1. 원인

### 3.2. 해결

### 3.3. 개발 테스트

#### 3.3.1. 테스트 절차

#### 3.3.2. 테스트 결과

#### 3.3.3. 연관기능

#### 3.3.4. 제약사항
```

## MCP 호출

```
# 1. 기존 일감 조회
server: user-redmine
tool: issues_get
arguments:
  id: "{issue_id}"

# 2. description 업데이트
server: user-redmine
tool: issues_update
arguments:
  id: "{issue_id}"
  description: (템플릿 기반으로 대화 내용 채워서 작성)
```

## 작성 지침

- 기존 description에 내용이 있으면 그 구조를 유지하되 빈 섹션을 채움
- 기존 description이 비어있으면 트래커에 맞는 템플릿을 새로 작성
- 아직 미완성인 섹션(테스트 결과 등)은 빈 항목으로 남김
- 대화 내용에서 파악 가능한 것은 최대한 상세하게 작성
- 완료 후 URL 안내: `https://redmine.piolink.com/issues/{id}`

## 포맷 지침

- **Redmine textile 형식(`h2.`, `h3.` 등) 사용 금지**
- description은 반드시 **Markdown 형식**으로 작성 (`##`, `###`, ` ``` `, `**`, `|---|` 등)
- 헤더: `## 1. 개요`, `### 1.1. 배경` 형태 사용
- 코드 블록: 백틱 3개(` ``` `) + 언어 태그 사용
- 인라인 코드: 백틱 1개(`` ` ``) 사용
- 테이블: Markdown 파이프 테이블(`| col | col |`) 사용
- 볼드: `**텍스트**` 사용

