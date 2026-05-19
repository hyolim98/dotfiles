#!/bin/bash

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/root/claude-backups}"
mkdir -p "$BACKUP_DIR"

TS=$(date +%Y%m%d-%H%M%S)
CLAUDE_OUT="$BACKUP_DIR/claude-$TS.tar.gz"
REDMINE_OUT="$BACKUP_DIR/redmine-$TS.tar.gz"

cd /root

tar -czf "$CLAUDE_OUT" \
    --exclude='.claude/cache' \
    --exclude='.claude/paste-cache' \
    --exclude='.claude/shell-snapshots' \
    --exclude='.claude/telemetry' \
    --exclude='.claude/statsig' \
    --exclude='.claude/ide' \
    --exclude='.claude/session-env' \
    --exclude='.claude/plugins' \
    --exclude='.claude/backups' \
    --exclude='.claude/.last-cleanup' \
    .claude .claude.json

echo "Claude:  $CLAUDE_OUT ($(du -h "$CLAUDE_OUT" | cut -f1))"

if [ -d /data/redmine ] && [ -n "$(ls -A /data/redmine 2>/dev/null)" ]; then
    tar -czf "$REDMINE_OUT" -C /data redmine
    echo "Redmine: $REDMINE_OUT ($(du -h "$REDMINE_OUT" | cut -f1))"
fi

echo
echo "복원: 새 서버에서"
echo "  OLD_SERVER=<this-host-ip> ./scripts/setup_rocky.sh"