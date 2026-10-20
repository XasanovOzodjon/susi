#!/usr/bin/env bash
# Файловая шина сетки Claude Code. Протокол — РЕГЛАМЕНТ.md §3.1.
# Папка шины: $BUS_DIR (по умолчанию ~/bus). Общая для всех ролей и worktree.
#
#   bus.sh init                          папки + ящики для ролей из team.conf
#   bus.sh beat    <я>                   heartbeat (первым делом на каждом ходу)
#   bus.sh who                           кто жив: возраст heartbeat в секундах
#   bus.sh read    <я>                   новые письма по курсору (нахлёст 10 строк, дедуп по id)
#   bus.sh send    <я> <кому> <тема> <суть> <факты> <нужно>
#   bus.sh ack     <я> <id> <отправитель>
#   bus.sh pending <я> [минут=10]        мои письма без ACK дольше N минут
#   bus.sh resend  <я> <id>              переслать письмо с тем же id
set -euo pipefail

BUS="${BUS_DIR:-$HOME/bus}"
HERE="$(cd "$(dirname "$0")" && pwd)"
now() { date '+%Y-%m-%dT%H:%M:%S'; }
need() { [ -n "${1:-}" ] || { echo "нужен аргумент: $2" >&2; exit 2; }; }

cmd="${1:-}"; shift || true
case "$cmd" in
  init)
    mkdir -p "$BUS"/{inbox,outbox,presence,cursor,handoffs}
    touch "$BUS/ALERTS.md"
    grep -v '^\s*#' "$HERE/team.conf" | awk 'NF{print $1}' | while read -r r; do
      touch "$BUS/inbox/$r.md" "$BUS/outbox/$r.md"
    done
    echo "шина готова: $BUS"; ls "$BUS/inbox" ;;

  beat)
    need "${1:-}" "<я>"; now > "$BUS/presence/$1" ;;

  who)
    t=$(date +%s)
    for f in "$BUS"/presence/*; do
      [ -e "$f" ] || { echo "никого нет"; break; }
      age=$(( t - $(date -r "$f" +%s) ))
      printf '%-14s %6ss %s\n' "$(basename "$f")" "$age" "$([ "$age" -gt 900 ] && echo 'ПРОТУХ' || echo 'жив')"
    done ;;

  read)
    need "${1:-}" "<я>"; me="$1"
    in="$BUS/inbox/$me.md" cur="$BUS/cursor/$me.read" seen="$BUS/cursor/$me.seen"
    touch "$in" "$seen"
    prev=$(cat "$cur" 2>/dev/null || echo 0)
    start=$(( prev > 10 ? prev - 10 : 0 ))   # нахлёст: страховка от одновременной записи
    total=$(wc -l < "$in")
    # Печатаем письма после start; письмо, чей id уже в seen, пропускаем целиком.
    tail -n +"$((start + 1))" "$in" | awk -v seen="$seen" '
      BEGIN { while ((getline l < seen) > 0) s[l] = 1 }
      /^\[(MSG|ACK) / { id = $2; sub(/\]$/, "", id); skip = (id in s) }
      !skip { print }
      /^\[MSG / && !skip { print id >> seen }'
    echo "$total" > "$cur"
    # ACK на мои письма закрывают строки в моём outbox.
    # (awk во временный файл, а не sed -i: у sed на macOS другой синтаксис -i)
    out="$BUS/outbox/$me.md"; touch "$out"
    awk 'FNR == NR { if ($1 == "[ACK") { id = $2; sub(/\]$/, "", id); a[id] = 1 } next }
         $2 == "awaiting-ack" && ($1 in a) { $2 = "acked" } { print }' "$in" "$out" > "$out.tmp" && mv "$out.tmp" "$out" ;;

  resend)
    # Переслать письмо с ТЕМ ЖЕ id (адресат жив, но ACK нет). Дубль безопасен: дедуп по id.
    need "${2:-}" "<я> <id>"; to=$(awk -v id="$2" '$1 == id { print $4; exit }' "$BUS/outbox/$1.md")
    need "$to" "письмо $2 в outbox/$1.md"
    awk -v id="$2" '/^\[(MSG|ACK) / { on = ($2 == id "]" && $1 == "[MSG") } on' "$BUS/inbox/$to.md" > "$BUS/resend.tmp"
    [ -s "$BUS/resend.tmp" ] || { echo "письмо $2 не найдено в inbox/$to.md" >&2; exit 1; }
    cat "$BUS/resend.tmp" >> "$BUS/inbox/$to.md"; rm -f "$BUS/resend.tmp"; echo "переслано $2 -> $to" ;;

  send)
    need "${6:-}" "<я> <кому> <тема> <суть> <факты> <нужно>"
    me="$1" to="$2"; id="$me-$(date '+%Y%m%d-%H%M%S')"
    printf '[MSG %s] ОТ %s -> %s | %s | %s\nСУТЬ: %s\nФАКТЫ: %s\nНУЖНО ОТ ТЕБЯ: %s\n\n' \
      "$id" "$me" "$to" "$(now)" "$3" "$4" "$5" "$6" >> "$BUS/inbox/$to.md"
    echo "$id awaiting-ack -> $to | $(date +%s) | $3" >> "$BUS/outbox/$me.md"
    echo "$id" ;;

  ack)
    need "${3:-}" "<я> <id> <отправитель>"
    printf '[ACK %s] ОТ %s -> %s | %s\n' "$2" "$1" "$3" "$(now)" >> "$BUS/inbox/$3.md" ;;

  pending)
    need "${1:-}" "<я>"; lim=$(( ${2:-10} * 60 )); t=$(date +%s)
    awk -F' [|] ' -v t="$t" -v lim="$lim" '/awaiting-ack/ && t - $2 > lim { print "без ACK " int((t - $2) / 60) " мин: " $0 }' \
      "$BUS/outbox/$1.md" 2>/dev/null
    echo "адресат жив (bus.sh who) -> bus.sh resend <я> <id>; протух -> строка в $BUS/ALERTS.md + письмо orchestrator" ;;

  *) sed -n '2,13p' "$0"; exit 2 ;;
esac
