# claude-setup

Configuração versionada do [Claude Code](https://claude.com/claude-code): instala o
CLI e injeta uma **status line personalizada** em qualquer máquina, de forma
**idempotente** (pode rodar quantas vezes quiser).

## Status line

```
[Sonnet 5] | 📁 meu-app | 🌿 main* | $0.42 | ⏱️  12m 34s | 5h: 24% (reseta em 2h 34m)
```

| Campo | Origem (JSON do Claude Code) |
|-------|------------------------------|
| Nome do modelo | `model.display_name` |
| Diretório atual | `workspace.current_dir` (só o nome da pasta) |
| Branch do git | `git rev-parse --abbrev-ref HEAD` no diretório atual |
| Custo da sessão | `cost.total_cost_usd` |
| Duração | `cost.total_duration_ms` |
| Limite de 5h + reset | `rate_limits.five_hour.used_percentage` / `resets_at` |

> A branch só aparece quando o diretório atual é um repositório git. Em
> *detached HEAD* mostra o hash curto, e um `*` indica que há alterações não
> commitadas.

> O trecho de limite só aparece em contas Claude.ai (Pro/Max) e após a primeira
> resposta da API. Em contas com API key ele é omitido automaticamente.

## Instalação

### Um comando (qualquer máquina)

```bash
curl -fsSL https://raw.githubusercontent.com/valdeirsapara/claude-setup/main/install.sh | bash
```

### A partir do repo clonado

```bash
git clone https://github.com/valdeirsapara/claude-setup.git
cd claude-setup
./install.sh
```

O `install.sh`:

1. Instala o Claude Code se `claude` não estiver no PATH (installer nativo, com
   fallback para `npm`). Se já estiver, não faz nada.
2. Copia `statusline.sh` para `~/.claude/statusline.sh` (`chmod +x`).
3. Mescla os blocos `statusLine` e `attribution` no `~/.claude/settings.json`
   **preservando** as demais chaves. Só grava o arquivo quando o conteúdo muda.

## Sem atribuição do Claude em commits e PRs

O instalador aplica, de forma global (vale em qualquer projeto):

```json
"attribution": {
  "commit": "",
  "pr": "",
  "sessionUrl": false
}
```

| Chave | Efeito |
|-------|--------|
| `commit: ""` | Remove o `Co-Authored-By` das mensagens de commit |
| `pr: ""` | Remove o "🤖 Generated with Claude Code" da descrição dos PRs |
| `sessionUrl: false` | Remove o `Claude-Session` com o link da sessão |

É configuração do próprio Claude Code (não uma skill), então é aplicada sempre,
sem depender do modelo seguir instruções. Para desfazer, apague o bloco do
`~/.claude/settings.json` (rodar o instalador de novo o recoloca).

## Atualizar

Edite `statusline.sh`, faça commit/push e rode o instalador de novo:

```bash
./install.sh
# ou
curl -fsSL https://raw.githubusercontent.com/valdeirsapara/claude-setup/main/install.sh | bash
```

## Variáveis de ambiente

| Variável | Padrão | Uso |
|----------|--------|-----|
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Diretório de configuração do Claude Code |
| `CLAUDE_SETUP_RAW` | `https://raw.githubusercontent.com/valdeirsapara/claude-setup/main` | Base para baixar o `statusline.sh` no modo `curl \| bash` |

## Requisitos

- `bash`, `curl`
- `python3` (usado para editar o JSON com segurança — presente por padrão em
  macOS, WSL e na maioria das distros Linux)

## Testar o script isoladamente

```bash
echo '{"model":{"display_name":"Sonnet 5"},"workspace":{"current_dir":"/home/me/app"},"cost":{"total_cost_usd":0.42,"total_duration_ms":754000},"rate_limits":{"five_hour":{"used_percentage":24,"resets_at":'"$(( $(date +%s) + 9300 ))"'}}}' | ./statusline.sh
```
