#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Claude Code — Custom Status Line
#
# Layout:
#   🐙 Model | 🌿 Branch | 📁 Path | [ctx bar] % | 🧊 5h:XX% (reset) | 🔢 7d:[bar] %  (reset)
#
# Dependencies: bash, sed, awk, git  (no jq — works on macOS and Windows Git Bash)
#
# Installation:
#   1. cp statusline-command.sh ~/.claude/statusline-command.sh
#   2. chmod +x ~/.claude/statusline-command.sh
#   3. Add the snippet from settings.json.example to ~/.claude/settings.json
#
# ─────────────────────────────────────────────────────────────────────────────

input=$(cat)

# ANSI color codes
DIM=$'\033[90m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
RST=$'\033[0m'
SEP="${DIM} | ${RST}"

# ── 1. Model display name ─────────────────────────────────────────────────────
model=$(printf '%s' "$input" \
  | sed 's/.*"model"[^{]*{//' \
  | sed 's/}[^}]*.*//' \
  | sed -n 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1)
[ -z "$model" ] && model="unknown"

# ── 2. Current working directory (cross-platform) ─────────────────────────────
raw_dir=$(printf '%s' "$input" \
  | sed 's/.*"workspace"[^{]*{//' \
  | sed 's/}[^}]*.*//' \
  | sed -n 's/.*"current_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1)
[ -z "$raw_dir" ] && raw_dir="$(pwd)"

# Normalize Windows backslashes → forward slashes
cwd=$(printf '%s' "$raw_dir" | sed 's|\\\\|/|g; s|\\|/|g')

# ── 3. Git branch ─────────────────────────────────────────────────────────────
# GIT_OPTIONAL_LOCKS=0 prevents git from creating lock files (safe for read-only ops)
branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && branch="no-git"

# ── 4. Relative path (strip /Users/<user>/ prefix) ───────────────────────────
rel=$(printf '%s' "$cwd" | sed -n 's|.*/[Uu]sers/[^/]*/||p')
[ -z "$rel" ] && rel=$(printf '%s' "$cwd" | sed 's|.*/||')
[ -z "$rel" ] && rel="~"

# Maestri.app (macOS) injects .maestri/roles/<uuid> into the CWD — strip it so
# the status line shows the real project path, not the role runner directory.
rel=$(printf '%s' "$rel" | sed 's|/\.maestri/roles/[^/]*.*||')

# ── 5. Context window % ───────────────────────────────────────────────────────
# Isolate the context_window block before rate_limits to avoid matching
# the wrong "used_percentage" field (rate limits have the same field name).
ctx_block_raw=$(printf '%s' "$input" \
  | sed 's/.*"context_window"[^{]*{//' \
  | sed 's/}[^}]*"rate_limits".*//')
ctx_pct=$(printf '%s' "$ctx_block_raw" \
  | sed -E -n 's/.*"used_percentage"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]*)?).*/\1/p' \
  | head -1)
[ -z "$ctx_pct" ] && ctx_pct=0
ctx_int=$(awk "BEGIN{printf \"%d\", $ctx_pct + 0.5}")

# Build 10-block progress bar
filled=$(awk "BEGIN{v=int($ctx_int*10/100); if(v>10)v=10; if(v<0)v=0; print v}")
empty=$((10 - filled))
bar=""
for ((i=0; i<filled; i++)); do bar="${bar}█"; done
for ((i=0; i<empty;  i++)); do bar="${bar}░"; done

# Color: ≤60% green | ≤80% yellow | >80% red
if awk "BEGIN{exit !($ctx_int <= 60)}"; then
  col="$GREEN"; dot="🟢"
elif awk "BEGIN{exit !($ctx_int <= 80)}"; then
  col="$YELLOW"; dot="🟡"
else
  col="$RED"; dot="🔴"
fi
ctx_display="${col}${bar} ${ctx_int}%${RST}"

# ── 6. 5-hour rate limit ──────────────────────────────────────────────────────
fh_block=$(printf '%s' "$input" | sed 's/.*"five_hour"[^{]*{//' | sed 's/}.*//')
fh_pct=$(printf '%s' "$fh_block" \
  | sed -E -n 's/.*"used_percentage"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]*)?).*/\1/p' \
  | head -1)
[ -z "$fh_pct" ] && fh_pct=0
fh_int=$(awk "BEGIN{printf \"%d\", $fh_pct + 0.5}")

# Reset timestamp → local time (change TZ to your timezone)
fh_ts=$(printf '%s' "$fh_block" \
  | sed -E -n 's/.*"resets_at"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' \
  | head -1)
fh_reset=""
if [ -n "$fh_ts" ]; then
  fh_reset=$(TZ=America/Sao_Paulo date -r "$fh_ts" "+%d/%m %Hh" 2>/dev/null)
fi
[ -z "$fh_reset" ] && fh_reset="--"

# ── 7. 7-day rate limit ───────────────────────────────────────────────────────
sd_block=$(printf '%s' "$input" | sed 's/.*"seven_day"[^{]*{//' | sed 's/}.*//')
sd_pct=$(printf '%s' "$sd_block" \
  | sed -E -n 's/.*"used_percentage"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]*)?).*/\1/p' \
  | head -1)
[ -z "$sd_pct" ] && sd_pct=0
sd_int=$(awk "BEGIN{printf \"%d\", $sd_pct + 0.5}")

sd_ts=$(printf '%s' "$sd_block" \
  | sed -E -n 's/.*"resets_at"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' \
  | head -1)
sd_reset=""
if [ -n "$sd_ts" ]; then
  sd_reset=$(TZ=America/Sao_Paulo date -r "$sd_ts" "+%d/%m %Hh" 2>/dev/null)
fi
[ -z "$sd_reset" ] && sd_reset="--"

# 7d progress bar (same 10-block logic)
sd_filled=$(awk "BEGIN{v=int($sd_int*10/100); if(v>10)v=10; if(v<0)v=0; print v}")
sd_empty=$((10 - sd_filled))
sd_bar=""
for ((i=0; i<sd_filled; i++)); do sd_bar="${sd_bar}█"; done
for ((i=0; i<sd_empty;  i++)); do sd_bar="${sd_bar}░"; done

# 7d color (same thresholds)
if awk "BEGIN{exit !($sd_int <= 60)}"; then
  sd_col="$GREEN"; sd_dot="🟢"
elif awk "BEGIN{exit !($sd_int <= 80)}"; then
  sd_col="$YELLOW"; sd_dot="🟡"
else
  sd_col="$RED"; sd_dot="🔴"
fi
sd_display="${sd_col}${sd_bar} ${sd_int}%${RST}"

# ── Output ────────────────────────────────────────────────────────────────────
printf "🐙 %s%s🌿 %s%s📁 %s%s%s %s%s🧊 5h:%d%% (%s)%s%s %s%s🔢 7d:%s\n" \
  "$model"       "$SEP" \
  "$branch"      "$SEP" \
  "$rel"         "$SEP" \
  "$dot" "$ctx_display" "$SEP" \
  "$fh_int" "$fh_reset" "$SEP" \
  "$sd_dot" "$sd_display" "$SEP" \
  "$sd_reset"
