#!/usr/bin/env bash
# Register t3-tg-notify hooks in Claude Code and Codex user config.
# Safe to re-run: existing t3-tg-notify entries are replaced, nothing else is touched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$ROOT/bin/t3-tg-notify"
CONFIG_DIR="$HOME/.config/t3-telegram-notify"
BACKUP_DIR="$CONFIG_DIR/backups"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_HOOKS="$HOME/.codex/hooks.json"
TS="$(date +%Y%m%d-%H%M%S)"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
chmod +x "$BIN"

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
chmod 700 "$CONFIG_DIR"
if [[ ! -e "$CONFIG_DIR/.env" ]]; then
  printf '%s\n' \
    '# Telegram credentials for t3-telegram-notify (keep this file private: chmod 600)' \
    'TELEGRAM_BOT_TOKEN=' 'TELEGRAM_USER_ID=' > "$CONFIG_DIR/.env"
  chmod 600 "$CONFIG_DIR/.env"
fi

# Merge hook entries into a settings/hooks JSON file.
# $1 file, $2 agent name, $3 JSON object {Event: matcher, ...}
merge_hooks() {
  local file="$1" agent="$2" events="$3" tmp
  mkdir -p "$(dirname "$file")"
  if [[ -e "$file" ]]; then
    cp "$file" "$BACKUP_DIR/$(basename "$(dirname "$file")")-$(basename "$file").$TS"
  else
    echo '{}' > "$file"
  fi
  tmp="$(mktemp)"
  jq --arg cmd "$BIN $agent" --argjson events "$events" '
    def strip: map(.hooks |= map(select((.command // "") | contains("t3-tg-notify") | not)))
               | map(select(.hooks | length > 0));
    .hooks = (.hooks // {} | with_entries(.value |= strip))
    | reduce ($events | to_entries[]) as $e (.;
        .hooks[$e.key] = ((.hooks[$e.key] // []) + [{
          matcher: $e.value,
          hooks: [{type: "command", command: $cmd, timeout: 10}]
        }]))
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  echo "updated $file"
}

merge_hooks "$CLAUDE_SETTINGS" claude '{
  "UserPromptSubmit": "*",
  "PreToolUse": "AskUserQuestion",
  "PostToolUse": "AskUserQuestion",
  "Notification": "*",
  "Stop": "*"
}'

merge_hooks "$CODEX_HOOKS" codex '{
  "UserPromptSubmit": "*",
  "PreToolUse": "*",
  "PostToolUse": "*",
  "Stop": "*"
}'

cat <<EOF

Installed. Next steps:
  1. Put your credentials in $CONFIG_DIR/.env
  2. Send /start to your bot once in Telegram.
  3. Codex only: run \`codex\` in a terminal once and approve the new hooks
     (Codex skips hooks it hasn't trusted).
Remove everything with: $ROOT/uninstall.sh
EOF
