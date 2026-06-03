# Changelog

## [2.0.0] — 2026-06-03

### Added
- **`statusline-command.js`** — reimplementação em Node.js com layout idêntico ao script Bash
- **Fuso horário dinâmico**: por padrão segue o fuso do sistema operacional (correto ao viajar entre países), via `Intl` + ICU
- **Override de fuso** via variável de ambiente `CLAUDE_STATUSLINE_TZ` (zona IANA) para travar um fuso fixo
- Leitura de stdin assíncrona com timeout de segurança (evita o bug `EAGAIN` do `readFileSync(0)` em pipes do Windows)

### Performance
- ~14x mais rápido no Windows (~2.8s → ~0.2s por render): processo único, sem forks de `sed`/`awk`/`git`

### Notes
- O script Bash (`statusline-command.sh`) continua disponível e suportado
- Comando portável único (`node ~/.claude/statusline-command.js`) funciona em Windows (via Git Bash), macOS e Linux

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
