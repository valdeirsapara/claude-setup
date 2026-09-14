#!/usr/bin/env bash
#
# claude-setup — instalador idempotente do Claude Code + status line personalizada.
#
# Uso local (repo clonado):
#     ./install.sh
#
# Uso remoto (um comando):
#     curl -fsSL https://raw.githubusercontent.com/valdeirsapara/claude-setup/main/install.sh | bash
#
# É seguro rodar quantas vezes quiser: só instala o que falta e só escreve no
# settings.json quando o conteúdo muda.

set -euo pipefail

# --- Configuração -----------------------------------------------------------
REPO_RAW="${CLAUDE_SETUP_RAW:-https://raw.githubusercontent.com/valdeirsapara/claude-setup/main}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSLINE_DEST="$CLAUDE_DIR/statusline.sh"

# Caminho gravado no settings.json. Usa ~ quando estiver no diretório padrão
# (portável entre máquinas); caso contrário, caminho absoluto.
if [ "$CLAUDE_DIR" = "$HOME/.claude" ]; then
  STATUSLINE_CMD="~/.claude/statusline.sh"
else
  STATUSLINE_CMD="$STATUSLINE_DEST"
fi
REFRESH_INTERVAL=10

# Onde está este script (vazio quando executado via `curl | bash`).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

log()  { printf '\033[36m[claude-setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[claude-setup]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[claude-setup]\033[0m %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1; }

pick_python() {
  if need python3; then echo python3
  elif need python; then echo python
  else die "Preciso de python3 para editar o settings.json com segurança."
  fi
}

# --- 1. Instalar o Claude Code (se faltar) --------------------------------
install_claude() {
  if need claude; then
    log "Claude Code já instalado ($(claude --version 2>/dev/null | head -1 || echo 'versão desconhecida'))."
    return
  fi
  log "Instalando o Claude Code..."
  if need curl && curl -fsSL https://claude.ai/install.sh | bash; then
    log "Claude Code instalado (installer nativo)."
  elif need npm; then
    npm install -g @anthropic-ai/claude-code
    log "Claude Code instalado (npm)."
  else
    die "Nenhum método de instalação disponível (precisa de curl ou npm)."
  fi
  need claude || warn "Claude instalado, mas 'claude' não está no PATH desta shell. Abra um novo terminal."
}

# --- 2. Colocar o statusline.sh em ~/.claude -----------------------------
install_statusline_script() {
  mkdir -p "$CLAUDE_DIR"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/statusline.sh" ]; then
    install -m 0755 "$SCRIPT_DIR/statusline.sh" "$STATUSLINE_DEST"
    log "statusline.sh instalado a partir do repo local."
  elif need curl; then
    curl -fsSL "$REPO_RAW/statusline.sh" -o "$STATUSLINE_DEST"
    chmod 0755 "$STATUSLINE_DEST"
    log "statusline.sh baixado de $REPO_RAW"
  else
    die "Não achei o statusline.sh localmente e não tenho curl para baixá-lo."
  fi
}

# --- 3. Mesclar statusLine e attribution no settings.json (idempotente) --
merge_settings() {
  [ -f "$SETTINGS" ] || { mkdir -p "$CLAUDE_DIR"; printf '{}\n' > "$SETTINGS"; }
  local py; py="$(pick_python)"

  STATUSLINE_CMD="$STATUSLINE_CMD" REFRESH_INTERVAL="$REFRESH_INTERVAL" \
  "$py" - "$SETTINGS" <<'PY'
import json, os, sys

path = sys.argv[1]
try:
    with open(path) as fh:
        cfg = json.load(fh)
    if not isinstance(cfg, dict):
        raise ValueError("settings.json não é um objeto")
except (FileNotFoundError, ValueError, json.JSONDecodeError):
    cfg = {}

desired = {
    "statusLine": {
        "type": "command",
        "command": os.environ["STATUSLINE_CMD"],
        "refreshInterval": int(os.environ["REFRESH_INTERVAL"]),
    },
    # Sem Co-Authored-By nos commits, sem "Generated with Claude Code" nos PRs
    # e sem o link da sessão.
    "attribution": {
        "commit": "",
        "pr": "",
        "sessionUrl": False,
    },
}

changed = [key for key, value in desired.items() if cfg.get(key) != value]

if not changed:
    print("settings.json já está atualizado — nada a fazer.")
else:
    for key in changed:
        cfg[key] = desired[key]
    with open(path, "w") as fh:
        json.dump(cfg, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print("settings.json: blocos aplicados: " + ", ".join(changed) + ".")
PY
}

main() {
  log "Diretório de configuração: $CLAUDE_DIR"
  install_claude
  install_statusline_script
  merge_settings
  log "Concluído. Abra o Claude Code — a status line aparece no rodapé."
}

main "$@"
