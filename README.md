# statusline-claudecode

> Status line customizada para o [Claude Code](https://claude.ai/code) — mostra modelo, branch git, caminho do projeto, barra de uso do contexto e barras de rate limit em tempo real.

![status line preview](https://img.shields.io/badge/claude-code-orange?style=flat-square) ![platform](https://img.shields.io/badge/plataforma-macOS%20%7C%20Linux%20%7C%20Windows%20Git%20Bash-blue?style=flat-square)

---

## Preview

```
🐙 claude-sonnet-4-6 | 🌿 main | 📁 Projects/meu-app | 🟢 ██░░░░░░░░ 15% | 🧊 5h:22% (13/05 19h) | 🟡 ███████░░░ 68% | 🔢 7d:68% (17/05 00h)
```

As cores mudam automaticamente conforme o uso aumenta:

| Faixa | Cor | Significado |
|-------|-----|-------------|
| ≤ 60% | 🟢 Verde | Tranquilo |
| 61–80% | 🟡 Amarelo | Atenção |
| > 80% | 🔴 Vermelho | Crítico |

---

## O que exibe

| Segmento | Descrição |
|----------|-----------|
| `🐙 Model` | Nome do modelo Claude ativo |
| `🌿 Branch` | Branch git atual (ou `no-git` se fora de um repositório) |
| `📁 Path` | Caminho relativo do projeto a partir de `~/` |
| `[barra] %` | Uso da janela de contexto — barra de 10 blocos + porcentagem |
| `🧊 5h:XX% (data)` | Uso do rate limit de 5 horas + horário de reset no fuso local |
| `🟢/🟡/🔴 [barra] %` | Uso do rate limit de 7 dias — barra + porcentagem |
| `🔢 7d:XX% (data)` | Horário de reset do rate limit de 7 dias no fuso local |

---

## Versão Node (recomendada)

Além do script Bash original, o repositório inclui **`statusline-command.js`** — uma reimplementação em Node.js com o **layout idêntico**, recomendada principalmente no Windows.

**Por que usar a versão Node:**

| Vantagem | Detalhe |
|----------|---------|
| ⚡ **~14x mais rápida no Windows** | O Bash forka `sed`/`awk`/`git` dezenas de vezes (~2.8s por render no Windows). O Node faz tudo em **1 processo** (~0.2s). |
| 🌍 **Fuso horário automático** | Segue o fuso do sistema operacional. Viajou pra outro país? O horário de reset se ajusta sozinho no próximo render — sem editar nada. |
| 🧭 **Override opcional de fuso** | Variável de ambiente `CLAUDE_STATUSLINE_TZ` (zona IANA, ex: `America/Sao_Paulo`) força um fuso fixo. Sem ela = segue o SO. |
| 📦 **Cross-platform sem `sed`/`awk`** | `JSON.parse` nativo + `Intl` (ICU) para datas. Mesmo comportamento no Windows, macOS e Linux. |
| 🔧 **1 comando portável** | `node ~/.claude/statusline-command.js` funciona nos dois OS (no Windows o Claude Code roda o comando via Git Bash, que expande o `~`). |

**Requisito extra:** Node.js 14+ (com ICU full — padrão nos builds oficiais).

### Instalação (Node)

```bash
# 1. Copie o script
cp statusline-command.js ~/.claude/statusline-command.js

# (ou via curl)
curl -o ~/.claude/statusline-command.js \
  https://raw.githubusercontent.com/mateusocana/statusline-claudecode/main/statusline-command.js
```

```json
// 2. ~/.claude/settings.json — bloco statusLine
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline-command.js",
    "refreshInterval": 1
  }
}
```

3. Reinicie o Claude Code.

> Para travar um fuso fixo (em vez de seguir o SO), defina `CLAUDE_STATUSLINE_TZ` no seu ambiente, ex: `export CLAUDE_STATUSLINE_TZ=America/Sao_Paulo`.

---

## Requisitos

- **Claude Code** instalado (comando `claude` disponível)
- **bash** (nativo no macOS, Linux ou Windows Git Bash)
- **git** (para detecção de branch)
- **sed** e **awk** (nativos no macOS e Linux)
- Sem dependência de `jq` — usa apenas ferramentas nativas do shell

---

## Instalação

### 1. Copie o script

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

Ou via `curl`:

```bash
curl -o ~/.claude/statusline-command.sh \
  https://raw.githubusercontent.com/mateusocana/statusline-claudecode/main/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 2. Configure o `~/.claude/settings.json`

Adicione o bloco `statusLine` ao seu arquivo de configuração:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh",
    "refreshInterval": 2
  }
}
```

Se já tiver um `settings.json`, mescle o bloco — não substitua o arquivo inteiro. Veja `settings.json.example` para o trecho mínimo necessário.

### 3. Reinicie o Claude Code

Feche e abra novamente o terminal ou a extensão do IDE. A status line aparece na parte inferior da interface do Claude Code.

---

## Customização

### Fuso horário

O padrão é `America/Sao_Paulo`. Para alterar, edite as duas linhas que chamam `date -r`:

```bash
# Altere TZ= para o seu fuso, ex: America/New_York, Europe/London, Asia/Tokyo
TZ=America/Sao_Paulo date -r "$fh_ts" "+%d/%m %Hh"
```

### Formato de data

Altere a string de formato do `date`. Padrão: `%d/%m %Hh` → `13/05 19h`

Algumas alternativas:

| Formato | Saída |
|---------|-------|
| `%d/%m %Hh` | `13/05 19h` (padrão) |
| `%H:%M` | `19:30` |
| `%b %d %H:%M` | `May 13 19:30` |
| `%Y-%m-%d %H:%M` | `2026-05-13 19:30` |

### Limites de cor

Edite as condições `awk` nas seções 5 e 7:

```bash
# Padrão: ≤60 verde | ≤80 amarelo | >80 vermelho
if awk "BEGIN{exit !($ctx_int <= 60)}"; then  # ← altere o 60
```

### Emojis / ícones

Substitua qualquer emoji na linha `printf` no final do script. Cada segmento tem comentário identificando sua posição.

### Remoção do path do Maestri.app (macOS)

O [Maestri.app](https://maestri.app) é um orquestrador de agentes IA para macOS. Quando ele executa uma sessão, injeta um diretório de role dentro do projeto com o padrão:

```
<seu-projeto>/.maestri/roles/<uuid>/
```

Sem o strip, a status line mostraria algo como `Projects/meu-app/.maestri/roles/70356567-c0c2-4bbd-b1f2-de8de8ec2a9b` em vez de `Projects/meu-app`.

O script remove automaticamente esse sufixo:

```bash
# Strips .maestri/roles/<uuid> injected by Maestri.app (macOS)
rel=$(printf '%s' "$rel" | sed 's|/\.maestri/roles/[^/]*.*||')
```

Se não usar o Maestri.app, remova essa linha. Não afeta projetos sem o diretório `.maestri/`.

---

## Como funciona

O Claude Code envia um payload JSON para o script via stdin a cada refresh. O script extrai os seguintes campos usando apenas `sed` e `awk` (sem dependências externas):

```
model.display_name                    → nome do modelo
workspace.current_dir                 → diretório de trabalho
context_window.used_percentage        → % de contexto usado
rate_limits.five_hour.used_percentage → % do limite de 5h
rate_limits.five_hour.resets_at       → timestamp de reset do limite de 5h
rate_limits.seven_day.used_percentage → % do limite de 7d
rate_limits.seven_day.resets_at       → timestamp de reset do limite de 7d
```

O bloco `context_window` é isolado antes de `rate_limits` para evitar capturar o campo `used_percentage` errado — os três blocos compartilham o mesmo nome de campo.

---

## Solução de problemas

**Status line não aparece**

- Verifique o caminho: `ls -la ~/.claude/statusline-command.sh`
- Confirme que é executável: `chmod +x ~/.claude/statusline-command.sh`
- Valide o JSON: `python3 -m json.tool ~/.claude/settings.json`

**Modelo aparece como "unknown"**

O campo `model.display_name` pode ter um caminho diferente na sua versão. Teste o script manualmente:

```bash
echo '{"model":{"display_name":"teste-modelo"}}' | bash ~/.claude/statusline-command.sh
```

**Horários de reset aparecem `--`**

O campo `resets_at` é um timestamp Unix. Alguns planos do Claude podem não incluí-lo. O script usa `--` como fallback sem quebrar.

**Fuso horário errado**

Atualize `TZ=America/Sao_Paulo` para o seu fuso IANA. Liste todos os disponíveis:

```bash
ls /usr/share/zoneinfo
```

---

## Créditos

Baseado no prompt original de [@geovanyferreira](https://gist.github.com/geovanyferreira/787fee2aaf01a66c98ca477f230c70fa), com funcionalidades adicionais:

- Barra do rate limit de 7 dias com indicador de cor
- Timestamps de reset para 5h e 7d no fuso local
- Remoção automática do path de roles do Maestri
- Documentação inline completa no script

---

## Licença

MIT
