#!/usr/bin/env bash
# Setka ofis sahnasi: http://127.0.0.1:8765
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export BUS_DIR="${BUS_DIR:-$HOME/bus}"
export SETKA_SCENE_PORT="${SETKA_SCENE_PORT:-8765}"
exec python3 "$ROOT/scene/server.py"
