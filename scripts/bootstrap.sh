#!/usr/bin/env bash
# Mashina + joriy papka: skilllar, graphify, skillui, ECC (ixtiyoriy).
# Interaktiv narsalar (claude-mem login) oxirida chop etiladi.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SKIP_CYBER="${SETKA_SKIP_CYBER:-0}"
SKIP_ECC="${SETKA_SKIP_ECC:-0}"
export SKILLS_CLONE_TIMEOUT_MS="${SKILLS_CLONE_TIMEOUT_MS:-600000}"

install_skill() {
  local src="$1"
  echo "==> skills add $src"
  # PromptScript va boshqa agentlar globalni rad etishi mumkin; Cursor/Antigravity nusxasi yetarli.
  npx --yes skills@latest add "$src" -g -y || npx --yes skills add "$src" -g -y || {
    echo "ogoh: $src to‘liq o‘rnatilmadi, davom etamiz" >&2
    return 0
  }
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "kerak: $1" >&2; exit 1; }; }
need git
need node
need npm
need npx
command -v python3 >/dev/null || { echo "ogoh: python3 yoq (Django backend uchun kerak)" >&2; }

echo "==> Setka skilllari (global, -y)"
install_skill mattpocock/skills
install_skill Graphify-Labs/graphify
install_skill usestrix/strix
install_skill oil-oil/oil-ui
install_skill oso95/scroll-world
npx --yes skills add oso95/scroll-world -a cursor -a antigravity -a gemini-cli -a codex -y || true
install_skill jakubkrehel/skills

VENDOR="${SETKA_VENDOR:-$HOME/.setka/vendor}"
mkdir -p "$VENDOR"
echo "==> Anthropic-Cybersecurity-Skills (vendor clone, pentester o‘qiydi)"
if [ ! -d "$VENDOR/Anthropic-Cybersecurity-Skills/.git" ]; then
  git clone --depth 1 https://github.com/mukul975/Anthropic-Cybersecurity-Skills.git \
    "$VENDOR/Anthropic-Cybersecurity-Skills"
else
  git -C "$VENDOR/Anthropic-Cybersecurity-Skills" pull --ff-only || true
fi
if [ "$SKIP_CYBER" = 1 ]; then
  echo "SETKA_SKIP_CYBER=1 — 800+ skill discovery ga qo‘shilmadi (vendor clone yetarli)"
else
  echo "==> cybersecurity skills ni agent discovery ga qo‘shish (katta)"
  install_skill mukul975/Anthropic-Cybersecurity-Skills
fi

echo "==> skillui"
npm install -g skillui || npx --yes skillui --help >/dev/null

echo "==> Graphify CLI"
if command -v uv >/dev/null 2>&1; then
  uv tool install graphifyy || uv tool upgrade graphifyy || true
elif command -v pipx >/dev/null 2>&1; then
  pipx install graphifyy || pipx upgrade graphifyy || true
else
  python3 -m pip install --user graphifyy || echo "ogoh: graphifyy o‘rnatilmadi. Keyin: python3 -m pip install --user graphifyy"
fi
export PATH="$HOME/Library/Python/3.12/bin:$HOME/Library/Python/3.11/bin:$HOME/.local/bin:$PATH"
if command -v graphify >/dev/null 2>&1; then
  graphify install --platform cursor || true
  graphify install --platform antigravity || graphify install --platform gemini || true
fi

if [ "$SKIP_ECC" = 1 ]; then
  echo "SETKA_SKIP_ECC=1 — ECC o‘tkazildi"
else
  echo "==> ECC npm adapter (hook runtime yoq — Setka hook saqlanadi)"
  (cd "$ROOT" && npx --yes ecc-universal@2.2.3 install --profile minimal --target cursor --no-hooks) || true
  (cd "$ROOT" && npx --yes ecc-universal@2.2.3 install --profile minimal --target antigravity --no-hooks) || true
  if [ -f "$ROOT/.cursor/hooks.json" ] && ! grep -q 'session-start.sh' "$ROOT/.cursor/hooks.json"; then
    echo "ogoh: .cursor/hooks.json ECC tomonidan o‘zgargan. session-start.sh ni qo‘lda qo‘shing." >&2
  fi
fi

chmod +x "$ROOT/bus.sh" "$ROOT/scripts/"*.sh "$ROOT/.cursor/hooks/"*.sh 2>/dev/null || true
"$ROOT/bus.sh" init || true
mkdir -p "$ROOT/board/tickets" "$ROOT/docs/agents" "$ROOT/docs/design"

cat <<'EOF'

Setka bootstrap tugadi.

Qolgan (bir marta, interaktiv):
  1. Claude-mem (Cursor + Gemini kalit):  npx claude-mem install
     Cursor ni tanlang, provider = Gemini.
  2. Strix cloud (ixtiyoriy): .cursor/mcp.json.example ni .cursor/mcp.json ga nusxa, Strix ga login.
  3. TaskView (ixtiyoriy): self-host yoki board/ bilan ishlang.
  4. Cursor / Antigravity ni QAYTA oching.

Loyiha: chatda /start-project
EOF
