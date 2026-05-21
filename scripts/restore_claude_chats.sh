#!/bin/bash

set -euo pipefail

OLD_SERVER="${1:-${OLD_SERVER:-}}"
if [ -z "$OLD_SERVER" ]; then
	read -r -p "옛 서버 IP: " OLD_SERVER
fi
if [ -z "$OLD_SERVER" ]; then
	echo "[ERR] OLD_SERVER가 비어있음" >&2
	exit 1
fi

REMOTE_DIR="${REMOTE_DIR:-/root/claude-backups}"

echo "restoring Claude state from $OLD_SERVER..."
LATEST=$(ssh -o StrictHostKeyChecking=accept-new root@"$OLD_SERVER" \
	"ls -1t $REMOTE_DIR/claude-*.tar.gz 2>/dev/null | head -1")
if [ -z "$LATEST" ]; then
	echo "  [WARN] no backup found at $OLD_SERVER:$REMOTE_DIR" >&2
	exit 1
fi

scp "root@$OLD_SERVER:$LATEST" /tmp/
tar -xzf "/tmp/$(basename "$LATEST")" -C /root
chmod 600 /root/.claude/.credentials.json 2>/dev/null || true

TS=$(basename "$LATEST" | sed -n 's/claude-\(.*\)\.tar\.gz/\1/p')
REDMINE_REMOTE="$REMOTE_DIR/redmine-$TS.tar.gz"
if ssh root@"$OLD_SERVER" "test -f $REDMINE_REMOTE" 2>/dev/null; then
	scp "root@$OLD_SERVER:$REDMINE_REMOTE" /tmp/
	mkdir -p /data
	tar -xzf "/tmp/redmine-$TS.tar.gz" -C /data
	echo "  restored: $(basename "$LATEST") + $(basename "$REDMINE_REMOTE")"
else
	echo "  restored: $(basename "$LATEST")"
fi
