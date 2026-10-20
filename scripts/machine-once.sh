#!/usr/bin/env bash
# Kompyuterga bir marta: Graphify CLI + claude-mem (Cursor va Antigravity).
# Loyiha papkasiga qayta yozilmaydi. Kalit faqat ~/.claude-mem/ da.
set -u
export PATH="$HOME/Library/Python/3.12/bin:$HOME/Library/Python/3.11/bin:$HOME/.local/bin:$PATH"

remember_path() {
  local rc="$HOME/.zshrc"
  local line='export PATH="$HOME/Library/Python/3.12/bin:$HOME/Library/Python/3.11/bin:$HOME/.local/bin:$PATH"'
  touch "$rc"
  if ! grep -q 'Library/Python/3.11/bin' "$rc" 2>/dev/null; then
    printf '\n# setka: graphify\n%s\n' "$line" >> "$rc"
  fi
}

install_graphify() {
  if command -v graphify >/dev/null 2>&1; then
    echo "Graphify allaqachon bor: $(command -v graphify)"
    return 0
  fi
  echo "==> Graphify (bir marta, shu kompyuter)"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "ogoh: python3 yo‘q, graphify o‘tmadi" >&2
    return 0
  fi
  python3 -m pip install --user graphifyy || echo "ogoh: graphifyy o‘rnatilmadi" >&2
  remember_path
  hash -r || true
  if command -v graphify >/dev/null 2>&1; then
    graphify install --platform cursor || true
    graphify install --platform antigravity || graphify install --platform gemini || true
    echo "Graphify tayyor"
  else
    echo "ogoh: graphify PATH da yo‘q. Yangi terminal oching." >&2
  fi
}

have_gemini_key() {
  python3 - <<'PY'
import json
from pathlib import Path
p = Path.home() / ".claude-mem" / "settings.json"
if not p.is_file():
    raise SystemExit(1)
try:
    data = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(1)
key = ""
if isinstance(data, dict):
    key = str(data.get("CLAUDE_MEM_GEMINI_API_KEY") or "")
raise SystemExit(0 if key.strip() else 1)
PY
}

save_gemini_key() {
  python3 - <<'PY'
import json, os
from pathlib import Path
p = Path.home() / ".claude-mem" / "settings.json"
p.parent.mkdir(parents=True, exist_ok=True)
data = {}
if p.is_file():
    try:
        loaded = json.loads(p.read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            data = loaded
    except Exception:
        data = {}
data["CLAUDE_MEM_PROVIDER"] = "gemini"
key = os.environ.get("CLAUDE_MEM_GEMINI_API_KEY", "").strip()
if key:
    data["CLAUDE_MEM_GEMINI_API_KEY"] = key
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

install_claude_mem() {
  local stamp="$HOME/.setka/claude-mem-hooks"
  mkdir -p "$HOME/.setka"
  if [ -z "${CLAUDE_MEM_GEMINI_API_KEY:-}" ] && ! have_gemini_key; then
    if [ -t 0 ]; then
      printf 'Gemini API key (claude-mem, bir marta, ko‘rinmaydi). Bo‘sh qoldirish mumkin: '
      read -rs key || key=""
      printf '\n'
      if [ -n "$key" ]; then
        CLAUDE_MEM_GEMINI_API_KEY="$key"
        export CLAUDE_MEM_GEMINI_API_KEY
      fi
    fi
  fi
  if [ -n "${CLAUDE_MEM_GEMINI_API_KEY:-}" ] || have_gemini_key; then
    save_gemini_key
  fi
  if [ -f "$stamp" ]; then
    echo "claude-mem hooklari bor"
    if ! have_gemini_key; then
      echo "ogoh: Gemini kaliti yo‘q. Keyingi ./susi install da so‘raydi, yoki ~/.claude-mem/settings.json"
    fi
    return 0
  fi
  echo "==> claude-mem (bir marta: Cursor + Antigravity, provider Gemini)"
  local ok=0
  npx --yes claude-mem install --ide cursor --provider gemini && ok=1 || echo "ogoh: claude-mem cursor o‘tmadi" >&2
  npx --yes claude-mem install --ide antigravity --provider gemini && ok=1 || echo "ogoh: claude-mem antigravity o‘tmadi" >&2
  if [ "$ok" = 1 ]; then
    date -u +%Y-%m-%dT%H:%M:%SZ > "$stamp"
  fi
  if ! have_gemini_key; then
    echo "claude-mem o‘rnatildi. Xotira Gemini kalitisiz ishlamaydi."
    echo "Kalitni keyinroq: CLAUDE_MEM_GEMINI_API_KEY=... ./susi install"
  else
    echo "claude-mem tayyor. Cursor va Antigravity ni qayta oching."
  fi
}

install_graphify
install_claude_mem
