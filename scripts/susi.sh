#!/usr/bin/env bash
# Susiezha: o‘rnatish va terminaldan ishga tushirish.
#
#   ./susi install [papka]     harnessni papkaga qo‘yadi
#   npx github:XasanovOzodjon/susi -- install ~/Loyihalar/app
#   ./susi start [--yes]       ofis + Cursor + 3 Antigravity
#   ./susi stop                ofis serverni to‘xtatadi
#   ./susi status
#   ./susi worker <rol>        shu rol uchun Antigravity + prompt
#   ./susi scene               faqat ofis (8765)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
export BUS_DIR="${BUS_DIR:-$HOME/bus}"
PORT="${SETKA_SCENE_PORT:-8765}"
CURSOR_BIN="${CURSOR_BIN:-/Applications/Cursor.app/Contents/Resources/app/bin/cursor}"
AGY_APP="${AGY_APP:-/Applications/Antigravity.app}"
LIVE="$ROOT/board/live"
PROFILES="$HOME/.setka/agy"

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \?//'
  exit 2
}

pause() {
  local msg="${1:-Davom etish uchun Enter. O‘tkazish: s}"
  if [ "${YES:-0}" = 1 ] || [ ! -t 0 ]; then
    return 0
  fi
  printf '%s ' "$msg"
  read -r ans || true
  case "$ans" in s|S|skip) return 1 ;; esac
  return 0
}

bus_init() {
  if [ -x "$ROOT/bus.sh" ]; then
    bash "$ROOT/bus.sh" init >/dev/null || true
  fi
  mkdir -p "$LIVE" "$ROOT/board/tickets" "$ROOT/docs/agents"
}

scene_up() {
  if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Ofis allaqachon ochiq: http://127.0.0.1:$PORT"
    return 0
  fi
  mkdir -p "$LIVE"
  nohup python3 "$ROOT/scene/server.py" >>"$LIVE/scene.log" 2>&1 &
  echo $! >"$LIVE/scene.pid"
  sleep 0.4
  echo "Ofis: http://127.0.0.1:$PORT"
}

scene_down() {
  local pid=""
  if [ -f "$LIVE/scene.pid" ]; then
    pid="$(cat "$LIVE/scene.pid" 2>/dev/null || true)"
  fi
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  else
    local p
    p="$(lsof -nP -t -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
    [ -n "$p" ] && kill $p 2>/dev/null || true
  fi
  rm -f "$LIVE/scene.pid"
  echo "Ofis to‘xtatildi"
}

open_cursor() {
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CURSOR (orchestrator)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1. Cursor ochiladi — shu papka."
  echo "  2. Chatga yozing:  /susi-start"
  echo "  3. Loyihani tushuntiring (savol-javob)."
  echo "  4. Tugagach yozing:  /susi-end"
  echo "     (/susi-end spec + ticket + qurishni boshlaydi)"
  if ! pause "[Enter] = Cursor ni ochish, s = o‘tkazish"; then
    echo "  o‘tkazildi"
    return 0
  fi
  if [ -x "$CURSOR_BIN" ]; then
    "$CURSOR_BIN" -n "$ROOT" >/dev/null 2>&1 &
  elif [ -d "/Applications/Cursor.app" ]; then
    open -na "Cursor" --args "$ROOT"
  else
    echo "  Cursor topilmadi. Qo‘lda oching: $ROOT"
    echo "  keyin chatga: /susi-start"
  fi
}

open_agy() {
  local slot="$1" role="$2" title="$3" hint="$4"
  local profile="$PROFILES/$slot"
  mkdir -p "$profile"
  write_prompt "$role"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ANTIGRAVITY $slot — $title"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Rol: $role"
  echo "  $hint"
  echo "  Papka: $ROOT"
  echo "  Prompt: $LIVE/prompts/$role.md  (buferga nusxa)"
  if ! pause "[Enter] = Antigravity ni ochish, s = o‘tkazish"; then
    echo "  o‘tkazildi"
    return 0
  fi
  if [ -f "$LIVE/prompts/$role.md" ] && command -v pbcopy >/dev/null; then
    pbcopy <"$LIVE/prompts/$role.md"
    echo "  Prompt buferda. Antigravity chatga Cmd+V."
  fi
  if [ -d "$AGY_APP" ]; then
    open -na "Antigravity" --args --user-data-dir "$profile" "$ROOT"
  else
    echo "  Antigravity.app yo‘q. Qo‘lda oching, papka: $ROOT"
    echo "  Agent sifatida «$role» ni tanlang."
  fi
}

write_prompt() {
  local role="$1"
  mkdir -p "$LIVE/prompts"
  cat >"$LIVE/prompts/$role.md" <<EOF
Sen Setka **$role** agentisan.

Papka: $ROOT
Qoidalar: AGENTS.md, REGLAMENT.md, roles/$role.md
Shina: BUS_DIR=$BUS_DIR  →  bash ./bus.sh beat $role && bash ./bus.sh read $role
Ofis: scripts/live.sh $role working "<hozir nima qilyapman>" [TV-N] [bosqich]
Doska: board/BOARD.md va board/tickets/

Mahsulot kodi faqat tasdiqlangan TV-N ticket bo‘lsa.
Pentester va QA patch yozmaydi.
Secretni chat/gitga yozma. Begona rol fayliga tegma.

Hozir: inboxni o‘qi. Ticket bo‘lsa — o‘z TV-N laringni qil. Yo‘q bo‘lsa kut.
Cursor da egasi /susi-end qilgach xat keladi.
EOF
}

cmd_install() {
  local dst="${1:-}"
  if [ -z "$dst" ]; then
    dst="$PWD"
  fi
  mkdir -p "$dst"
  dst="$(cd "$dst" && pwd)"
  bash "$ROOT/scripts/machine-once.sh" || true
  if [ "$dst" = "$ROOT" ]; then
    chmod +x "$ROOT/susi" "$ROOT/bus.sh" "$ROOT/scripts/"*.sh "$ROOT/.cursor/hooks/"*.sh 2>/dev/null || true
    bus_init
    echo "Susiezha allaqachon shu papkada: $dst"
    echo "Ishga tushirish: ./susi start"
    return 0
  fi
  bash "$ROOT/scripts/apply-to-project.sh" "$dst"
  if [ -f "$ROOT/susi" ]; then
    cp "$ROOT/susi" "$dst/susi"
    chmod +x "$dst/susi"
  fi
  mkdir -p "$dst/.cursor/commands"
  for c in susi-start susi-end; do
    [ -f "$ROOT/.cursor/commands/$c.md" ] && cp "$ROOT/.cursor/commands/$c.md" "$dst/.cursor/commands/$c.md"
  done
  echo
  echo "O‘rnatildi: $dst"
  echo "Keyin:"
  echo "  cd \"$dst\""
  echo "  ./susi start"
}

cmd_start() {
  YES="${YES:-0}"
  for a in "$@"; do
    case "$a" in
      --yes|-y) YES=1 ;;
      --dry-run) export DRYRUN=1 ;;
    esac
  done
  bus_init
  if [ "${DRYRUN:-}" = 1 ]; then
    echo "[dry-run] $ROOT"
    echo "  ofis http://127.0.0.1:$PORT"
    echo "  Cursor /susi-start → tushuntirish → /susi-end"
    echo "  Antigravity 1 backend, 2 frontend, 3 pentester"
    return 0
  fi
  scene_up
  bash "$ROOT/scripts/live.sh" orchestrator waiting "Cursor da /susi-start — egasi tushuntiradi" "" grill 2>/dev/null || true
  echo
  echo "SUSIEZHA ISHGA TUSHIRISH"
  echo "Loyiha: $ROOT"
  echo "Ofis:   http://127.0.0.1:$PORT"
  echo
  echo "Ketma-ketlik: har bir qadamda nima ochilishi yoziladi."
  echo "Enter = ochish.  s = o‘tkazish."
  open_cursor
  open_agy 1 backend "1-akkaunt · Backend" "Google akkaunt #1. Agent: backend. Django/DRF."
  open_agy 2 frontend "2-akkaunt · Frontend" "Google akkaunt #2. Agent: frontend. UI."
  open_agy 3 pentester "3-akkaunt · Pentester/QA" "Google akkaunt #3. Avval pentester; keyin QA/devops shu oynada."
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "TAYYOR"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Ofis:     http://127.0.0.1:$PORT"
  echo "  Cursor:   /susi-start  →  gapiring  →  /susi-end"
  echo "  To‘xtatish: ./susi stop"
  echo
}

cmd_worker() {
  local role="${1:-}"
  [ -n "$role" ] || { echo "usage: susi worker <orchestrator|backend|frontend|devops|pentester|qa>" >&2; exit 2; }
  bus_init
  local slot="1"
  case "$role" in
    backend) slot=1 ;;
    frontend) slot=2 ;;
    pentester|qa|devops) slot=3 ;;
    orchestrator) echo "Orchestrator Cursor da. /susi-start"; open_cursor; return 0 ;;
  esac
  YES=1 open_agy "$slot" "$role" "$role" "Rol: $role"
}

cmd_status() {
  echo "papka: $ROOT"
  echo "bus:   $BUS_DIR"
  if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "ofis:  http://127.0.0.1:$PORT  (ishlamoqda)"
  else
    echo "ofis:  to‘xtagan.  ./susi start  yoki ./susi scene"
  fi
  bash "$ROOT/bus.sh" who 2>/dev/null || true
}

cmd="${1:-}"; shift || true
case "$cmd" in
  --dry-run) cmd_start --dry-run ;;
  install) cmd_install "${1:-}" ;;
  start|up) cmd_start "$@" ;;
  stop|down) scene_down ;;
  scene) bus_init; scene_up; echo "To‘xtatish: ./susi stop" ;;
  worker) cmd_worker "${1:-}" ;;
  status) cmd_status ;;
  -h|--help|help|"") usage ;;
  *) usage ;;
esac
