#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

REGISTRY_DIR="${HOME}/.cc-orchestra"

if [[ ! -d "$REGISTRY_DIR" ]] || [[ -z "$(ls -A "$REGISTRY_DIR" 2>/dev/null)" ]]; then
  echo "cc-orchestra: no active tasks"
  exit 0
fi

for env_file in "${REGISTRY_DIR}"/*.env; do
  [[ -f "$env_file" ]] || continue
  task=$(basename "$env_file" .env)
  scope=$(grep "^CC_SCOPE=" "$env_file" 2>/dev/null | cut -d= -f2)
  created=$(grep "^CC_CREATED=" "$env_file" 2>/dev/null | cut -d= -f2)
  echo "── task: ${task}  [${scope:-?}]  created: ${created:-?}"

  # List pane entries
  while IFS='=' read -r key val; do
    [[ "$key" =~ ^PANE_ ]] || continue
    proj=$(echo "${key#PANE_}" | tr '[:upper:]_' '[:lower:]-')
    alive="✓"
    cc_pane_alive "$val" 2>/dev/null || alive="✗ dead"
    echo "   ${proj}: ${val} ${alive}"
  done < "$env_file"
  echo ""
done
