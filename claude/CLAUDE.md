# Personal preferences

Replies in Korean unless the user writes in another language.
Prefer concise answers; add detail only when the question warrants it.

## Commit convention

All of this user's git repositories use `R #<ticket> <message>` (see `/commit` skill). Never commit with a `Co-Authored-By` or `🤖 Generated with Claude Code` trailer.

## Tool preferences

- `rg` over `grep` when searching code
- `gopls` / `go doc` for Go code navigation
- For Redmine ticket lookups, use the Redmine MCP if connected

## POPCON debugging

When troubleshooting POPCON issues (bugs, install/uninstall hangs, panics, unexpected behavior), check the `psm-cm` pod log first — it is the controllerManager and the central nervous system of most POPCON services. Most root causes show up here.

Run from a POPCON host (no namespace needed):

```bash
# 최근 로그 (노이즈 필터링)
kubectl logs deployment/psm-cm --tail=300 \
  | rg -v 'multipath monitor|WTCHKPT|Slow query|Connection (accepted|ended)'

# 실시간 follow + 이슈 키워드만
kubectl logs deployment/psm-cm -f --tail=0 \
  | rg -n 'UnInstall|Install|cephadm-|PLAY RECAP|fatal|UNREACHABLE|panic|delete cluster|err :|err='

# 직전 컨테이너 (재시작/패닉 직후)
kubectl logs deployment/psm-cm --previous --tail=200 | rg -i 'panic|runtime error'
```

Always pair the log read with the user's symptom — don't dump raw logs back, summarize the key error/decision lines.
