#!/bin/bash
# Register MCP servers for Claude Code. Idempotent — skips if already added.

# Redmine MCP
if claude mcp list 2>/dev/null | grep -q '^redmine'; then
    echo "[ok] Redmine MCP already registered."
    exit 0
fi

read -rsp "Redmine API key (input hidden, empty to skip): " REDMINE_API_KEY
echo
if [ -z "$REDMINE_API_KEY" ]; then
    echo "[skip] Redmine MCP."
    exit 0
fi

echo "registering Redmine MCP..."
claude mcp add redmine \
    --scope user \
    --env REDMINE_URL=https://redmine.piolink.com \
    --env REDMINE_API_KEY="$REDMINE_API_KEY" \
    -- npx -y @onozaty/redmine-mcp-server
