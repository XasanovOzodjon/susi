#!/usr/bin/env bash
# Mahalliy TaskView: board/BOARD.md + board/tickets/TV-N.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOARD="$ROOT/board"
TICKETS="$BOARD/tickets"
TABLE="$BOARD/BOARD.md"
mkdir -p "$TICKETS"

next_id() {
  local n=1 f
  for f in "$TICKETS"/TV-*.md; do
    [ -e "$f" ] || continue
    local i="${f##*/}"; i="${i#TV-}"; i="${i%%-*}"
    i="${i%.md}"
    case "$i" in (*[!0-9]*) continue ;; esac
    [ "$i" -ge "$n" ] && n=$((i + 1))
  done
  printf 'TV-%03d' "$n"
}

rebuild_table() {
  {
    echo '# Doska'
    echo
    echo 'Ustunlar: Backlog → Ishda → Gate → Chiqarishga tayyor → Prodda → Done'
    echo
    echo '| ID | Sarlavha | Rol | Ustun | Blocker |'
    echo '|----|----------|-----|-------|---------|'
    for f in "$TICKETS"/TV-*.md; do
      [ -e "$f" ] || continue
      id=$(sed -n 's/^id: //p' "$f" | head -1)
      title=$(sed -n 's/^title: //p' "$f" | head -1)
      role=$(sed -n 's/^role: //p' "$f" | head -1)
      col=$(sed -n 's/^column: //p' "$f" | head -1)
      blk=$(sed -n 's/^blocked_by: //p' "$f" | head -1)
      printf '| %s | %s | %s | %s | %s |\n' "$id" "$title" "$role" "$col" "${blk:-—}"
    done
  } > "$TABLE"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  add)
    title="${1:-}"; role="${2:-orchestrator}"; col="${3:-Backlog}"
    [ -n "$title" ] || { echo "usage: board.sh add \"sarlavha\" [rol] [ustun]" >&2; exit 2; }
    id=$(next_id)
    cat > "$TICKETS/$id.md" <<EOF
id: $id
title: $title
role: $role
column: $col
blocked_by:
ready_when:
sha:

# $id · $title

## Qabul
- 

## Dalil
- 
EOF
    rebuild_table
    echo "$id" ;;
  move)
    id="${1:-}"; col="${2:-}"
    [ -n "$col" ] || { echo "usage: board.sh move TV-N <ustun>" >&2; exit 2; }
    f="$TICKETS/$id.md"
    [ -f "$f" ] || f=$(ls "$TICKETS"/"$id"*.md 2>/dev/null | head -1 || true)
    [ -f "${f:-}" ] || { echo "yoq: $id" >&2; exit 1; }
    tmp="$f.tmp"
    awk -v c="$col" 'BEGIN{done=0} /^column:/{print "column: " c; done=1; next} {print} END{if(!done) print "column: " c}' "$f" > "$tmp" && mv "$tmp" "$f"
    rebuild_table
    echo "$id -> $col" ;;
  show|ls)
    cat "$TABLE" ;;
  *)
    echo "board.sh add|move|show" >&2; exit 2 ;;
esac
