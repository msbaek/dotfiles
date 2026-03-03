#!/bin/bash
# daily-obsidian-maintenance.sh — morning-auto.sh에서 호출
# 1. Chrome 쿠키 → Playwright storage state 동기화
# 2. Playwright MCP 최신 버전 확인 및 settings.json 업데이트

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
PYTHON="$HOME/.pyenv/versions/3.11.7/bin/python3"

echo "=== Obsidian Daily Maintenance ==="
echo ""

# 1. Cookie sync
echo "[1/2] Chrome 쿠키 동기화..."
if output=$("$PYTHON" ~/bin/sync-chrome-cookies.py 2>&1); then
  echo "  ✅ 쿠키 동기화 완료"
  [[ -n "$output" ]] && echo "$output"
else
  echo "  ⚠ 쿠키 동기화 실패"
  [[ -n "$output" ]] && echo "$output"
fi

echo ""

# 2. Playwright MCP version check
echo "[2/2] Playwright MCP 버전 확인..."
current=$(jq -r '.mcpServers.playwright.args[0]' "$SETTINGS" | sed 's/@playwright\/mcp@//')
echo "  현재 버전: v$current"

latest=$(npm view @playwright/mcp version 2>/dev/null)

if [[ -z "$latest" ]]; then
  echo "  ⚠ npm registry 조회 실패"
elif [[ "$current" == "$latest" ]]; then
  echo "  ✅ 최신 버전 사용 중 (v$current)"
else
  echo "  🔄 업데이트: v$current → v$latest"
  jq --arg ver "@playwright/mcp@$latest" '.mcpServers.playwright.args[0] = $ver' "$SETTINGS" > "$SETTINGS.tmp" \
    && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "  ✅ settings.json 업데이트 완료"
  # 업데이트된 내용 확인
  updated=$(jq -r '.mcpServers.playwright.args[0]' "$SETTINGS")
  echo "  확인: $updated"
fi

echo ""
echo "=== Obsidian Daily Maintenance 완료 ==="
