#!/usr/bin/env python3
"""Claude Code status line: modelo | diretório | branch | custo | duração | limite 5h."""
import json
import os
import subprocess
import sys
import time

data = json.load(sys.stdin)

# --- Nome do modelo ---
model = data.get("model", {}).get("display_name", "?")

# --- Diretório atual (somente o nome da pasta) ---
cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd") or ""
dirname = os.path.basename(cwd.rstrip("/")) or cwd or "?"


# --- Branch do git (vazio fora de um repositório) ---
def git(*args):
    try:
        out = subprocess.run(
            ("git", "-C", cwd or ".", *args),
            capture_output=True, text=True, timeout=1,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


branch = git("rev-parse", "--abbrev-ref", "HEAD")
if branch == "HEAD":  # detached: mostra o hash curto
    branch = git("rev-parse", "--short", "HEAD")
if branch and git("status", "--porcelain"):
    branch += "*"

# --- Custo e duração da sessão ---
cost = data.get("cost", {}).get("total_cost_usd", 0) or 0
dur_ms = data.get("cost", {}).get("total_duration_ms", 0) or 0
dur_s = dur_ms // 1000
h, rem = divmod(dur_s, 3600)
m, s = divmod(rem, 60)
if h:
    dur_fmt = f"{h}h {m}m"
elif m:
    dur_fmt = f"{m}m {s}s"
else:
    dur_fmt = f"{s}s"

# --- Limite de 5h + tempo até a próxima janela ---
five = data.get("rate_limits", {}).get("five_hour", {})
five_pct = five.get("used_percentage")
five_reset = five.get("resets_at")

limit_part = ""
if five_pct is not None:
    limit_part = f"5h: {five_pct:.0f}%"
    if five_reset:
        left = int(five_reset - time.time())
        if left > 0:
            lh, lm = divmod(left // 60, 60)
            limit_part += f" (reseta em {lh}h {lm}m)" if lh else f" (reseta em {lm}m)"

# --- Cores ANSI ---
CYAN = "\033[36m"
MAGENTA = "\033[35m"
YELLOW = "\033[33m"
GREEN = "\033[32m"
RESET = "\033[0m"

parts = [
    f"{CYAN}[{model}]{RESET}",
    f"\U0001F4C1 {dirname}",
]
if branch:
    parts.append(f"{MAGENTA}\U0001F33F {branch}{RESET}")
parts += [
    f"{YELLOW}${cost:.2f}{RESET}",
    f"⏱️  {dur_fmt}",
]
if limit_part:
    parts.append(f"{GREEN}{limit_part}{RESET}")

print(" | ".join(parts))
