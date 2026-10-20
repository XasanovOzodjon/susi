#!/usr/bin/env bash
# Ofis sahnasiga holat yozadi. Har qadamda:
#   scripts/live.sh <rol> <holat> "<hozir>" [TV-N] [bosqich]
# holat: working | waiting | done | blocked | offline
# bosqich: grill | spec | tickets | build | gate | qa | done
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIVE="$ROOT/board/live"
mkdir -p "$LIVE"

role="${1:-}"; state="${2:-working}"; now="${3:-}"; ticket="${4:-}"; stage="${5:-}"
[ -n "$role" ] || { echo 'usage: live.sh <rol> <holat> "<hozir>" [TV-N] [bosqich]' >&2; exit 2; }

python3 - "$LIVE" "$role" "$state" "$now" "$ticket" "$stage" <<'PY'
import json, sys, datetime
from pathlib import Path
live, role, state, now, ticket, stage = sys.argv[1:]
allowed = {"working", "waiting", "done", "blocked", "offline"}
if state not in allowed:
    state = "working"
ts = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
doc = {
    "role": role,
    "state": state,
    "now": now,
    "ticket": ticket or None,
    "stage": stage or None,
    "updated": ts,
}
path = Path(live) / f"{role}.json"
path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
ev = Path(live) / "events.jsonl"
line = json.dumps({"t": ts, "role": role, "state": state, "now": now, "ticket": ticket or None, "stage": stage or None}, ensure_ascii=False)
with ev.open("a", encoding="utf-8") as f:
    f.write(line + "\n")
print(f"{role}: {state} — {now}")
PY
