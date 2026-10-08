# t3-telegram-notify

Telegram notifications from Claude Code and Codex hooks. Independent of T3 Code:
it works for agent sessions started from T3 and from the terminal alike.

| Event | Message |
|---|---|
| Agent opens a question form | 🙋 the question and its options |
| Question still unanswered after `REMINDER_MINUTES` | ⏰ one reminder (re-asking the same question sends nothing new) |
| Approval prompt (Claude, non-full-access mode) | 🔐 what needs approval |
| Turn finished after at least `MIN_TURN_MINUTES` | ✅ duration and the agent's final message |

No bot process runs: each hook calls `bin/t3-tg-notify`, which sends through
the Telegram Bot API with `curl` and exits. Only bash, curl and jq are needed.

## Setup

```bash
./install.sh
```

1. Fill in `~/.config/t3-telegram-notify/.env` (`TELEGRAM_BOT_TOKEN` and your
   numeric `TELEGRAM_USER_ID`; messages go only to that user's private chat
   with the bot).
2. Send `/start` to your bot once.
3. Codex: run `codex` in a terminal once and approve the new hooks.

## Removal

```bash
./uninstall.sh
```

Removes only the hook entries containing `t3-tg-notify` from
`~/.claude/settings.json` and `~/.codex/hooks.json`. Backups of both files are
written to `~/.config/t3-telegram-notify/backups/` on every install/uninstall.

## Debugging

Add `T3TG_DEBUG=1` to the `.env` to log every hook payload to
`~/.local/state/t3-telegram-notify/debug.log`.
