# statusline-claudecode

> Custom status line for [Claude Code](https://claude.ai/code) — shows model, git branch, project path, context window usage, and rate limit bars in real time.

![status line preview](https://img.shields.io/badge/claude-code-orange?style=flat-square) ![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows%20Git%20Bash-blue?style=flat-square)

---

## Preview

```
🐙 claude-sonnet-4-6 | 🌿 main | 📁 Projects/my-app | 🟢 ██░░░░░░░░ 15% | 🧊 5h:22% (13/05 19h) | 🟡 ███████░░░ 68% | 🔢 7d:68% (17/05 00h)
```

Color changes automatically as usage grows:

| Range | Color | Meaning |
|-------|-------|---------|
| ≤ 60% | 🟢 Green | Safe |
| 61–80% | 🟡 Yellow | Caution |
| > 80% | 🔴 Red | Critical |

---

## What it shows

| Segment | Description |
|---------|-------------|
| `🐙 Model` | Active Claude model name |
| `🌿 Branch` | Current git branch (or `no-git` if outside a repo) |
| `📁 Path` | Relative project path from `~/` |
| `[bar] %` | Context window usage — 10-block bar + percentage |
| `🧊 5h:XX% (date)` | 5-hour rate limit usage + reset time in local timezone |
| `🟢/🟡/🔴 [bar] %` | 7-day rate limit usage — bar + percentage |
| `🔢 7d:XX% (date)` | 7-day rate limit reset time in local timezone |

---

## Requirements

- **Claude Code** CLI installed (`claude` command available)
- **bash** (macOS built-in, Linux, or Windows Git Bash)
- **git** (for branch detection)
- **sed** and **awk** (both macOS/Linux built-in)
- No `jq` required — parser uses only native shell tools

---

## Installation

### 1. Copy the script

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

Or with `curl`:

```bash
curl -o ~/.claude/statusline-command.sh \
  https://raw.githubusercontent.com/mateusocana/statusline-claudecode/main/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 2. Configure `~/.claude/settings.json`

Add the `statusline` block to your settings file:

```json
{
  "statusline": {
    "command": "bash ~/.claude/statusline-command.sh",
    "refreshInterval": 2
  }
}
```

If you already have a `settings.json`, merge — don't replace. See `settings.json.example` for the minimal snippet.

### 3. Restart Claude Code

Close and reopen the terminal / IDE extension. The status line appears at the bottom of the Claude Code interface.

---

## Customization

### Timezone

The reset timestamps default to `America/Sao_Paulo`. Edit the two lines that call `date -r`:

```bash
# Change TZ= to your timezone, e.g. America/New_York, Europe/London, Asia/Tokyo
TZ=America/Sao_Paulo date -r "$fh_ts" "+%d/%m %Hh"
```

### Date format

Change the `date` format string. Default: `%d/%m %Hh` → `13/05 19h`

Some alternatives:

| Format | Output |
|--------|--------|
| `%d/%m %Hh` | `13/05 19h` (default) |
| `%H:%M` | `19:30` |
| `%b %d %H:%M` | `May 13 19:30` |
| `%Y-%m-%d %H:%M` | `2026-05-13 19:30` |

### Color thresholds

Edit the `awk` conditions in sections 5 and 7:

```bash
# Default thresholds: ≤60 green | ≤80 yellow | >80 red
if awk "BEGIN{exit !($ctx_int <= 60)}"; then  # ← change 60
```

### Emoji / icons

Replace any emoji at the bottom `printf` call. The segments are labeled with comments so they're easy to find.

### Maestri role path stripping

If you use [Maestri](https://maestri.app), the script automatically strips `.maestri/roles/<uuid>` from the path display so it shows the real project name, not the role runner directory. This is handled by:

```bash
rel=$(printf '%s' "$rel" | sed 's|/\.maestri/roles/[^/]*.*||')
```

Remove that line if you don't use Maestri.

---

## How it works

Claude Code feeds a JSON payload to the script via stdin on every refresh. The script parses these fields using only `sed` and `awk` (no external dependencies):

```
model.display_name          → model name
workspace.current_dir       → working directory
context_window.used_percentage
rate_limits.five_hour.used_percentage
rate_limits.five_hour.resets_at
rate_limits.seven_day.used_percentage
rate_limits.seven_day.resets_at
```

The `context_window` block is isolated before `rate_limits` to avoid matching the wrong `used_percentage` — all three blocks share the same field name.

---

## Troubleshooting

**Status line doesn't appear**

- Verify the path: `ls -la ~/.claude/statusline-command.sh`
- Check it's executable: `chmod +x ~/.claude/statusline-command.sh`
- Validate the JSON: `python3 -m json.tool ~/.claude/settings.json`

**Model shows "unknown"**

The JSON field `model.display_name` may have a different path in your version. Run the script manually with sample input:

```bash
echo '{"model":{"display_name":"test-model"}}' | bash ~/.claude/statusline-command.sh
```

**Reset times show `--`**

The `resets_at` field is a Unix timestamp. Some Claude plans may not include it. The script falls back to `--` gracefully.

**Wrong timezone**

Update `TZ=America/Sao_Paulo` to your IANA timezone. List all available:

```bash
ls /usr/share/zoneinfo
```

---

## Credits

Based on the original prompt by [@geovanyferreira](https://gist.github.com/geovanyferreira/787fee2aaf01a66c98ca477f230c70fa), with extended features:

- 7-day rate limit bar + color indicator
- Reset timestamps for both 5h and 7d limits in local timezone
- Maestri role path stripping
- Full inline documentation

---

## License

MIT
