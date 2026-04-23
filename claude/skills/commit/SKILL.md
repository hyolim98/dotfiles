---
name: commit
description: Create a git commit in the `R #<ticket> <message>` convention (Redmine-referenced, used across the user's repositories). Use when the user asks to commit, says "커밋해줘", "commit", or finishes a logical change. Extracts the Redmine ticket number from the current branch name, drafts a Korean commit message from the diff AND the prior conversation context (why the change was made), matches the house style of the current repo's git log, and asks the user to confirm before committing.
---

# commit skill

The user's repositories follow this commit message convention. Every commit must reference a Redmine ticket.

## Format

```
R #<ticket_number> <message>
```

Variants — **always derive the allowed variants by reading `git log --oneline -30` in the current repo**, not from a hardcoded list:

- `R #<num> <message>` — bare form, when the change is a single-line feature or fix
- `R #<num> [Category] <message>` — when the current repo's recent log shows `[Something]` category tags. Only use categories that **actually appear** in this repo's recent history. Do not invent new ones and do not carry categories between repos.
- `R #<num> fix: <message>` — small, targeted bug fixes when that prefix is used in the current repo's history. Can combine: `R #<num> [Category] fix: <message>`.

If the current repo's history doesn't use `[Category]` tags at all, don't add them. Match the local house style, not a remembered style from a different repo.

Messages are written in **Korean** and describe what the change accomplishes. Keep the first line focused; do not include a body unless the change genuinely needs multi-line explanation.

Do **not** add any `Co-Authored-By` trailer, `🤖 Generated with Claude Code` footer, or any other signature. The user's repos don't have these — follow the existing style exactly.

## Steps

### 1. Inspect repository state (run in parallel)

- `git status` — see what's staged / unstaged / untracked
- `git diff --staged` and `git diff` — see the actual changes
- `git branch --show-current` — current branch name
- `git log --oneline -10` — recent commits (so you can match the house style for this subsystem right now)

### 2. Extract the Redmine ticket number

Try these branch-name patterns in order against the current branch name:

1. `R?(\d{5,6})` case-insensitive — matches `R211647`, `r211647-foo`, `R#211647`
2. `issue[-/_]?(\d{5,6})` — matches `issue/211647`, `issue-211647`
3. `#?(\d{5,6})` anywhere — matches `feature/#211647-bla`, `211647-fix`
4. Any standalone 5-6 digit number

If a number is found, confirm with the user in one line: `브랜치에서 #211647 추출했어요. 맞나요?`

If nothing is found, or the user says the extracted number is wrong, ask: `Redmine 일감 번호를 알려주세요 (예: 211647)`.

### 3. Draft the commit message

Use **both** of these sources:

- **The diff** — what files changed, what functions/values were modified, what was added/removed
- **The prior conversation in this session** — why the user made this change, what problem they were solving, what they called it. This context is often more important than the diff for the message. If the user said "pwlCache에서 instanceWaitRetires 2000으로 바꿔줘", that phrasing should shape the commit message.

Guidelines:
- Korean, describe the outcome (what was accomplished) not the mechanics (which line changed)
- If the conversation framed it as a bug, use `fix:` prefix
- If the conversation or diff points clearly at a subsystem (Ceph/Storage/OpenStack wrapper/etc.), add the matching `[Category]`. When unsure, leave it off — no category is better than a wrong one.
- Keep it to one line unless the change genuinely spans unrelated concerns (in which case prefer splitting into multiple commits)
- Do not invent a ticket ID — use only the confirmed number

### 4. Show the draft and confirm

Present exactly what will be committed:

```
커밋 메시지 초안:
  R #<num> <message>

포함될 파일:
  M  path/one.go
  M  path/two.go
  ?? path/new.go

이대로 커밋할까요? (Y/n, 또는 수정사항을 알려주세요)
```

List every file that will be staged so the user can catch accidental inclusions (e.g. scratch files, secrets, unrelated edits). If there are untracked files, explicitly ask whether to include them — don't silently add them.

### 5. Commit

After confirmation:

- Stage the files by **explicit path** (never `git add .` or `git add -A`) to avoid accidentally including untracked files the user didn't approve
- Run `git commit -m "R #<num> <message>"` via a HEREDOC for correct quoting
- Run `git status` after, and show the user the new HEAD (`git log -1 --oneline`) so they can verify

Do not push. Pushing is a separate explicit action.

## Refusal conditions

- If there are no changes to commit, say so and stop — don't create an empty commit.
- If the user-specified files include anything that looks like a secret (`.env`, keys, credentials, tokens), warn clearly and require explicit confirmation before staging it.
- If the working tree has a merge conflict in progress, stop and point it out — don't paper over it with a commit.
