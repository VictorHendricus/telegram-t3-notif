#!/usr/bin/env bash
# Remove t3-tg-notify hooks from Claude Code and Codex user config.
# Only entries whose command contains "t3-tg-notify" are removed.
set -euo pipefail

CONFIG_DIR="$HOME/.config/t3-telegram-notify"
BACKUP_DIR="$CONFIG_DIR/backups"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/t3-telegram-notify"
TS="$(date +%Y%m%d-%H%M%S)"

strip_hooks() {
  local file="$1" tmp
  [[ -e "$file" ]] || return 0
  mkdir -p "$BACKUP_DIR"
  cp "$file" "$BACKUP_DIR/$(basename "$(dirname "$file")")-$(basename "$file").$TS"
  tmp="$(mktemp)"
  jq '
    if .hooks then
      .hooks |= (with_entries(.value |= (
          map(.hooks |= map(select((.command // "") | contains("t3-tg-notify") | not)))
          | map(select(.hooks | length > 0))))
        | with_entries(select(.value | length > 0)))
      | if .hooks == {} then del(.hooks) else . end
    else . end
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  echo "cleaned $file"
}

strip_hooks "$HOME/.claude/settings.json"
strip_hooks "$HOME/.codex/hooks.json"

# Codex hooks.json holding nothing else is just leftover from install.sh.
if [[ -e "$HOME/.codex/hooks.json" ]] && [[ "$(jq -c . "$HOME/.codex/hooks.json")" == "{}" ]]; then
  rm "$HOME/.codex/hooks.json"
  echo "removed empty $HOME/.codex/hooks.json"
fi

pkill -f 't3-tg-notify --remind' 2>/dev/null || true
rm -rf "$STATE_DIR"

echo "Uninstalled. Your credentials remain in $CONFIG_DIR/.env (delete it if you no longer need it)."
