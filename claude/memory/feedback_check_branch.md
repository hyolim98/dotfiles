---
name: Always verify current git branch (ticket number) before working
description: User often switches branches to work on multiple tickets in parallel — always confirm the branch and its ticket number before code edits or assumptions
type: feedback
originSessionId: e7afb041-00a2-491a-97dd-08ba9c5d493e
---
Before starting any code work in `/data/admin-core` (or other git repos), **run `git branch --show-current` and identify the ticket number from the branch name**. Don't assume the branch matches the ticket the user just mentioned.

**Why:** The user frequently works on multiple tickets simultaneously, switching branches between them. Branch naming convention is `feature_r<ticket_id>` or `bug_r<ticket_id>`. If I assume the branch matches the last-discussed ticket, I risk mixing unrelated changes into the wrong commit.

**How to apply:**
- At the start of any code edit/commit task, check `git branch --show-current` first
- If the branch's ticket number doesn't match what the user just mentioned, **ask before proceeding** ("현재 브랜치는 X 인데 Y 작업 맞나요?")
- When user says "이 일감 작업해줘" without specifying branch, verify the branch matches the ticket
- Especially careful when committing — the commit message format is `R #<ticket> <message>`, so wrong branch = wrong ticket reference
- IDE file-open notifications (like `<ide_opened_file>`) can hint at what the user is currently focused on but are not authoritative — git branch is
