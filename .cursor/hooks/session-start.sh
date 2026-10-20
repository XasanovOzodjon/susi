#!/usr/bin/env bash
# Inject Setka standing orders at session start. Fail open.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
role="${SETKA_ROLE:-orchestrator}"
bus="${BUS_DIR:-$HOME/bus}"
graph="$root/graphify-out/GRAPH_REPORT.md"
tickets="$root/board/BOARD.md"

ctx="SETKA: You are in the Setka harness. Default role=$role. Read AGENTS.md. Intake: /taskstart then owner explains, then /taskend starts spec/tickets/build. Do not write product code until /taskend tickets exist. Prefer graphify-out over grepping the tree. Pentester/QA never patch. Each turn: scripts/live.sh $role working|waiting|done \"what I am doing now\" [TV-N] [stage]. Owner watches the office at http://127.0.0.1:8765. Launch from terminal: ./setka start"

if [ -f "$graph" ]; then
  ctx="$ctx Graphify report exists at graphify-out/GRAPH_REPORT.md — query it before reading source."
else
  ctx="$ctx graphify-out is missing; after intake, map with /graphify ."
fi

if [ -f "$tickets" ]; then
  ctx="$ctx Board: board/BOARD.md"
fi

if [ -x "$root/bus.sh" ]; then
  BUS_DIR="$bus" "$root/bus.sh" beat "$role" >/dev/null 2>&1 || true
fi

python3 -c 'import json,sys; print(json.dumps({"additional_context": sys.argv[1]}))' "$ctx"
exit 0
