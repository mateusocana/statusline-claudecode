#!/usr/bin/env node
// ─────────────────────────────────────────────────────────────────────────────
// Claude Code — Custom Status Line (Node port — fast, single-process)
//
// Layout:
//   🐙 Model | 🌿 Branch | 📁 Path | [ctx bar] % | 🧊 5h:XX% (reset) | 🔢 7d:[bar] % (reset)
//
// Why Node: the original bash script forks sed/awk/git dozens of times. On Windows
// that costs ~2.8s per render. This does everything in one process (~0.15s):
// native JSON.parse, one git spawn, Intl for timezone formatting. No deps.
//
// Source of layout: github.com/mateusocana/statusline-claudecode (bash original
// kept intact at ~/.claude/statusline-claudecode/).
// ─────────────────────────────────────────────────────────────────────────────

'use strict';
const { spawnSync } = require('child_process');

// ── Read all stdin (async — readFileSync(0) throws EAGAIN on Windows pipes) ────
const chunks = [];
let done = false;
let safety = null;
function finish() {
  if (done) return;
  done = true;
  if (safety) clearTimeout(safety); // release event loop so process exits now
  render(Buffer.concat(chunks).toString('utf8'));
}
if (process.stdin.isTTY) {
  finish(); // no piped input
} else {
  process.stdin.on('data', (c) => chunks.push(c));
  process.stdin.on('end', finish);
  process.stdin.on('error', finish);
  process.stdin.resume();
  safety = setTimeout(finish, 1500); // never hang the status line
  safety.unref(); // don't keep the loop alive on its own
}

function render(raw) {
let data = {};
try { data = JSON.parse(raw); } catch { data = {}; }

// ── ANSI colors ───────────────────────────────────────────────────────────────
const DIM = '\x1b[90m', GREEN = '\x1b[32m', YELLOW = '\x1b[33m', RED = '\x1b[31m', RST = '\x1b[0m';
const SEP = `${DIM} | ${RST}`;
// Follows the OS/runtime timezone by default (Intl reads it at process start, so
// it stays correct when traveling). Set CLAUDE_STATUSLINE_TZ to an IANA zone
// (e.g. 'America/Sao_Paulo') to force a fixed timezone.
const TZ = process.env.CLAUDE_STATUSLINE_TZ || undefined;

// ── 1. Model display name ─────────────────────────────────────────────────────
const model = (data.model && data.model.display_name) || 'unknown';

// ── 2. Current working directory (cross-platform) ─────────────────────────────
let rawDir = (data.workspace && data.workspace.current_dir) || process.cwd();
const cwd = String(rawDir).replace(/\\/g, '/'); // Windows backslashes → forward

// ── 3. Git branch (single spawn, no lock files) ───────────────────────────────
let branch = 'no-git';
try {
  const r = spawnSync('git', ['-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'], {
    encoding: 'utf8',
    timeout: 800,
    env: Object.assign({}, process.env, { GIT_OPTIONAL_LOCKS: '0' }),
    windowsHide: true,
  });
  const out = (r.stdout || '').trim();
  if (out) branch = out;
} catch { /* no-git */ }

// ── 4. Relative path (strip /Users/<user>/ prefix) ───────────────────────────
let rel = '';
const m = cwd.match(/.*\/[Uu]sers\/[^/]*\/(.+)/);
if (m) rel = m[1];
if (!rel) {
  const parts = cwd.split('/').filter(Boolean);
  rel = parts.length ? parts[parts.length - 1] : '~';
}
// Maestri.app injects .maestri/roles/<uuid> — strip it
rel = rel.replace(/\/\.maestri\/roles\/[^/]*.*$/, '');

// ── helpers ───────────────────────────────────────────────────────────────────
function pct(v) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.round(n) : 0;
}
function bar(intPct) {
  let filled = Math.floor((intPct * 10) / 100);
  if (filled > 10) filled = 10;
  if (filled < 0) filled = 0;
  return '█'.repeat(filled) + '░'.repeat(10 - filled);
}
function colorFor(intPct) {
  if (intPct <= 60) return { col: GREEN, dot: '🟢' };
  if (intPct <= 80) return { col: YELLOW, dot: '🟡' };
  return { col: RED, dot: '🔴' };
}
function fmtTs(ts) {
  const sec = Number(ts);
  if (!Number.isFinite(sec) || sec <= 0) return '--';
  try {
    const d = new Date(sec * 1000);
    const opts = { day: '2-digit', month: '2-digit', hour: '2-digit', hour12: false };
    if (TZ) opts.timeZone = TZ; // omitted => Intl uses the OS/runtime default zone
    const p = new Intl.DateTimeFormat('en-GB', opts)
      .formatToParts(d).reduce((a, x) => (a[x.type] = x.value, a), {});
    let hh = p.hour === '24' ? '00' : p.hour; // Intl can emit 24 at midnight
    return `${p.day}/${p.month} ${hh}h`;
  } catch { return '--'; }
}

// ── 5. Context window % ───────────────────────────────────────────────────────
const ctxInt = pct(data.context_window && data.context_window.used_percentage);
const ctxC = colorFor(ctxInt);
const ctxDisplay = `${ctxC.col}${bar(ctxInt)} ${ctxInt}%${RST}`;

// ── 6 & 7. Rate limits ────────────────────────────────────────────────────────
const rl = data.rate_limits || {};
const fh = rl.five_hour || {};
const sd = rl.seven_day || {};

const fhInt = pct(fh.used_percentage);
const fhReset = fmtTs(fh.resets_at);

const sdInt = pct(sd.used_percentage);
const sdReset = fmtTs(sd.resets_at);
const sdC = colorFor(sdInt);
const sdDisplay = `${sdC.col}${bar(sdInt)} ${sdInt}%${RST}`;

// ── Output ────────────────────────────────────────────────────────────────────
process.stdout.write(
  `🐙 ${model}${SEP}` +
  `🌿 ${branch}${SEP}` +
  `📁 ${rel}${SEP}` +
  `${ctxC.dot} ${ctxDisplay}${SEP}` +
  `🧊 5h:${fhInt}% (${fhReset})${SEP}` +
  `${sdC.dot} ${sdDisplay}${SEP}` +
  `🔢 7d:${sdReset}\n`
);
}
