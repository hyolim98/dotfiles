---
name: Redmine-driven dev workflow
description: Team uses Redmine as the source of truth for bug reports, root-cause analysis, fixes, and new-feature design/implementation/test records
type: project
originSessionId: ca3ba225-f699-48ab-89ed-3c9069defb66
---
The team uses **Redmine** as the canonical record of engineering work:
- Bugs: ticket contains the report, the developer's root-cause analysis, and the fix/solution
- New features: ticket contains design → implementation approach → test notes

User wants Claude Code to be able to **read and understand Redmine tickets** (and ideally write notes back) to be useful during dev and debugging.

**Why:** The context for why a piece of code exists, or why a bug was fixed a certain way, lives in Redmine — not in git history or code comments.

**How to apply:**
- When the user references "일감", "티켓", "이슈 번호", or a Redmine ID, assume it's a Redmine issue and try to fetch it via the Redmine MCP (once configured) before answering from code alone
- When proposing a fix, suggest what should be recorded back to the Redmine ticket (root cause, fix summary, test evidence) to match team conventions
- Don't assume git log / PRs capture the reasoning — Redmine does
