# Changelog

## [1.1.0] — 2026-05-13

### Added
- 7-day rate limit progress bar (10 blocks) with color indicator (🟢/🟡/🔴)
- Reset timestamps for both 5h and 7d rate limits in local timezone
- Maestri role path stripping (`.maestri/roles/<uuid>` removed from display path)
- Full inline comments on every section of the script

### Changed
- Color thresholds unified: ≤60% green, ≤80% yellow, >80% red (applies to context window and 7d bar)

## [1.0.0] — 2026-04-16

### Initial release (based on @geovanyferreira's gist)
- Model name display
- Git branch detection
- Relative project path
- Context window 10-block bar with color + percentage
- 5-hour rate limit percentage
