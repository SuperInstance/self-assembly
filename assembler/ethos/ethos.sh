#!/bin/bash
# ethos.sh — run the hardware agent. Thin wrapper; the brains are in ethos.py.
# Usage: ethos.sh [--out DIR]
# Exit 0 = tuned and signed off (.tuned.yaml written with tuned:true).
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
python3 "$ROOT/assembler/ethos/ethos.py" "$@" || { echo "ethos FAILED — refusing to tune" >&2; exit 1; }
TS="$(date -u +%FT%TZ)"
echo "## $TS — ethos: tuning signed off (see CONSOLE.local.md)" >> "$ROOT/LEDGER.md"
