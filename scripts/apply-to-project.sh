#!/usr/bin/env bash
# Setka harnessni mahsulot papkasiga ko‘chiradi. Mavjud mahsulot kodini o‘chirmaydi.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DST="${1:-}"
[ -n "$DST" ] || { echo "usage: apply-to-project.sh /path/to/product" >&2; exit 2; }
mkdir -p "$DST"
DST="$(cd "$DST" && pwd)"

copy_tree() {
  local rel="$1"
  mkdir -p "$DST/$(dirname "$rel")"
  if [ -d "$SRC/$rel" ]; then
    mkdir -p "$DST/$rel"
    cp -R "$SRC/$rel/." "$DST/$rel/"
  else
    mkdir -p "$DST/$(dirname "$rel")"
    cp "$SRC/$rel" "$DST/$rel"
  fi
}

had_agents=0
[ -f "$DST/AGENTS.md" ] && had_agents=1

for rel in \
  REGLAMENT.md GEMINI.md team.conf bus.sh susi \
  .gitignore .env.example \
  roles \
  board \
  scripts \
  templates \
  docs/agents \
  scene \
  .cursor/agents .cursor/rules .cursor/hooks .cursor/hooks.json .cursor/mcp.json.example \
  .cursor/commands/susi-start.md .cursor/commands/susi-end.md \
  .cursor/skills/task-start .cursor/skills/task-end \
  .agents
 do
  [ -e "$SRC/$rel" ] || continue
  copy_tree "$rel"
done

if [ "$had_agents" = 1 ]; then
  if ! grep -q 'Setka — doimiy qoidalar' "$DST/AGENTS.md"; then
    {
      echo
      echo '---'
      echo
      cat "$SRC/AGENTS.md"
    } >> "$DST/AGENTS.md"
  fi
else
  copy_tree AGENTS.md
fi

chmod +x "$DST/bus.sh" \
  "$DST/scripts/"*.sh \
  "$DST/.cursor/hooks/"*.sh 2>/dev/null || true

chmod +x "$DST/susi" 2>/dev/null || true
echo "Setka qo‘llandi: $DST"
echo "Keyin:"
echo "  cd \"$DST\""
echo "  ./susi start"
echo "Cursor chat: /susi-start  →  tushuntirasiz  →  /susi-end"
