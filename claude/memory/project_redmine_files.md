---
name: Redmine ticket local files in /data/redmine
description: Local working copies of Redmine tickets live in /data/redmine/<id>-<slug>.md — used as the shared workspace between user (VSCode Remote-SSH) and Claude
type: project
originSessionId: e7afb041-00a2-491a-97dd-08ba9c5d493e
---
Tickets the user is actively working on are kept as Markdown files in `/data/redmine/` on this server.

**Filename convention:** `<ticket_id>-<short-slug>.md`
- Example: `211647-pwl-volume-type.md`, `211409-nas-inactive-cause.md`
- Slug should be short, kebab-case, English, descriptive of the ticket subject
- Always include the slug — never bare `<id>.md`

**Why:** User edits these files from Mac via VSCode Remote-SSH; Claude edits the same files server-side. Single source of truth, no sync needed. Final content gets copy-pasted into Redmine via the web UI.

**How to apply:**
- When the user says "일감 N번 검토해줘" / "수정한 거 봐줘" / "초안 써줘" without specifying a path, **default to working on `/data/redmine/<N>-*.md`**. Glob match the prefix.
- If no file exists for that ticket yet, ask whether to create one (and offer to fetch the ticket description via Redmine MCP to seed it).
- When creating new files, pick a slug from the ticket subject and confirm it once with the user before locking it in.
- Don't sync these files anywhere — the user edits via VSCode Remote-SSH, Claude edits directly.
- Format: Markdown (Redmine project supports Markdown). Don't auto-convert to Textile unless asked.

**Upload to Redmine:**
- When the user says "업로드해줘" / "올려줘" / "redmine에 반영해줘" for a ticket, fetch the corresponding Redmine ticket via MCP and update its `description` field with the local file content (`updateIssue`).
- If the ticket already has a non-empty `description`, **show the user that a body exists and confirm overwrite before proceeding**. Don't silently overwrite.
- If the ticket description is empty, upload directly without confirmation.
- After upload, briefly confirm what was written (ticket id, title, char count).
