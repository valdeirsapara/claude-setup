# claude-setup

Configuração versionada do [Claude Code](https://claude.com/claude-code): instala o
CLI e injeta uma **status line personalizada** em qualquer máquina, de forma
**idempotente** (pode rodar quantas vezes quiser).

## Status line

```
[Sonnet 5] | 📁 meu-app | $0.42 | ⏱️  12m 34s | 5h: 24% (reseta em 2h 34m)
```

| Campo | Origem (JSON do Claude Code) |
|-------|------------------------------|
| Nome do modelo | `model.display_name` |
| Diretório atual | `workspace.current_dir` (só o nome da pasta) |
| Custo da sessão | `cost.total_cost_usd` |
| Duração | `cost.total_duration_ms` |
| Limite de 5h + reset | `rate_limits.five_hour.used_percentage` / `resets_at` |

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
3. Mescla o bloco `statusLine` no `~/.claude/settings.json` **preservando** as
   demais chaves. Só grava o arquivo quando o conteúdo muda.

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
