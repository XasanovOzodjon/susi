#!/usr/bin/env bash
# Запуск сетки Claude Code в tmux (Linux, macOS, WSL). РЕГЛАМЕНТ.md §10.
# Лежит в <проект>/.team/ рядом с team.conf, roles/, bus.sh.
#   DRYRUN=1 launch-team.sh    показать команды, ничего не создавать
#   launch-team.sh             поднять (или подключиться к уже поднятой) сетке
# Переменные: PROJECT (по умолчанию — папка над .team), BUS_DIR (~/bus),
#             MODEL (claude-opus-5-5), SESSION (team).
set -euo pipefail

TEAM="$(cd "$(dirname "$0")" && pwd)"
PROJECT="${PROJECT:-$(dirname "$TEAM")}"
WT_ROOT="$(dirname "$PROJECT")/$(basename "$PROJECT")-wt"
MODEL="${MODEL:-claude-opus-5-5}"
SESSION="${SESSION:-team}"
export BUS_DIR="${BUS_DIR:-$HOME/bus}"
run() { if [ "${DRYRUN:-}" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }

command -v claude >/dev/null || { echo "нет claude в PATH" >&2; exit 1; }
[ "${DRYRUN:-}" = 1 ] || command -v tmux >/dev/null || { echo "нет tmux: apt install tmux / brew install tmux" >&2; exit 1; }
git -C "$PROJECT" rev-parse --git-dir >/dev/null || { echo "$PROJECT — не git-репозиторий" >&2; exit 1; }

if [ "${DRYRUN:-}" != 1 ] && tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"     # сетка уже поднята: вторую копию НЕ запускаем (одно имя — одна копия)
fi

run "$TEAM/bus.sh" init >/dev/null
mkdir -p "$TEAM/sessions"
first=1
while read -r role tree tg; do
  # 1. Папка роли: основное дерево или свой worktree на ветке w/<роль>/main.
  if [ "$tree" = main ]; then dir="$PROJECT"; else
    dir="$WT_ROOT/$role"
    if [ ! -d "$dir" ]; then
      git -C "$PROJECT" fetch -q origin 2>/dev/null || true
      base=$(git -C "$PROJECT" rev-parse --verify -q origin/main || git -C "$PROJECT" rev-parse HEAD)
      if git -C "$PROJECT" rev-parse --verify -q "w/$role/main" >/dev/null; then
        run git -C "$PROJECT" worktree add "$dir" "w/$role/main"
      else
        run git -C "$PROJECT" worktree add -b "w/$role/main" "$dir" "$base"
      fi
    fi
  fi

  # 2. Постоянный id сессии: первый запуск --session-id, дальше --resume (история переживает перезагрузку).
  idf="$TEAM/sessions/$role.id"
  if [ -s "$idf" ]; then sess="--resume $(cat "$idf")"; else
    id=$(python3 -c 'import uuid; print(uuid.uuid4())' 2>/dev/null || cat /proc/sys/kernel/random/uuid)
    [ "${DRYRUN:-}" = 1 ] || echo "$id" > "$idf"
    sess="--session-id $id"
  fi

  # 3. Команда роли. Telegram-канал — только у роли с tg=yes (один бот = один потребитель).
  ch=""; [ "$tg" = yes ] && ch="--channels plugin:telegram@claude-plugins-official"
  # Промпт роли с подставленными путями: в worktree нет .team, поэтому пути — абсолютные.
  pf="$TEAM/sessions/$role.prompt.md"; p=$(cat "$TEAM/roles/$role.md")
  busc="BUS_DIR='$BUS_DIR' '$TEAM/bus.sh'"
  p=${p//\{\{bus\}\}/$busc}; p=${p//\{\{team\}\}/$TEAM}; p=${p//\{\{busdir\}\}/$BUS_DIR}
  [ "${DRYRUN:-}" = 1 ] || printf '%s\n' "$p" > "$pf"
  cmd="claude $sess --name $role --model $MODEL $ch --append-system-prompt-file '$pf'"

  # 4. Панель tmux: первая создаёт сессию, остальные делят окно; раскладка — плиткой.
  if [ $first = 1 ]; then run tmux new-session -d -s "$SESSION" -n grid -c "$dir" "$cmd"; first=0
  else run tmux split-window -t "$SESSION:grid" -c "$dir" "$cmd"; run tmux select-layout -t "$SESSION:grid" tiled; fi
  run tmux select-pane -t "$SESSION:grid" -T "$role"
done < <(grep -v '^\s*#' "$TEAM/team.conf" | awk 'NF')

run tmux set -t "$SESSION" pane-border-status top
run tmux attach -t "$SESSION"
