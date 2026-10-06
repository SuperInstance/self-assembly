#!/bin/bash
# probe-console.sh — "are we on the console we tuned for?"
# Reads .tuned.yaml (written by the ethos agent). Refuses to work if the box
# was never tuned — the agent does no real work until ethos signs off.
# Exit 0 = yes. Exit 1 = no / not tuned (reason on stderr).
# Usage: probe-console.sh [--quiet]
set -u
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
say() { [ "$QUIET" = 1 ] || echo "$*" >&2; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TUNED="$ROOT/.tuned.yaml"

[ -f "$TUNED" ] || { say "NOT-TUNED: .tuned.yaml missing — run assembler/ethos/ethos.sh first; refusing real work"; exit 1; }
TUNED_OK="$(python3 -c "import yaml; print(yaml.safe_load(open('$TUNED')).get('tuned', False))" 2>/dev/null)"
[ "$TUNED_OK" = "True" ] || { say "NOT-TUNED: tuned != true — run assembler/ethos/ethos.sh; refusing real work"; exit 1; }

get() { python3 -c "import yaml; print(yaml.safe_load(open('$TUNED')).get('$1',''))" 2>/dev/null; }
fail=0
WANT_ARCH="$(get arch)"; HAVE_ARCH="$(uname -m)"
[ "$HAVE_ARCH" = "$WANT_ARCH" ] || { say "NOT-CONSOLE: arch=$HAVE_ARCH (tuned for $WANT_ARCH)"; fail=1; }
WANT_CORES="$(get cores)"; HAVE_CORES="$(nproc)"
[ "$HAVE_CORES" = "$WANT_CORES" ] || { say "NOT-CONSOLE: cores=$HAVE_CORES (tuned for $WANT_CORES)"; fail=1; }
WANT_MEM="$(get mem_gb)"; HAVE_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"; HAVE_GB=$((HAVE_KB/1024/1024))
LO=$((WANT_MEM*9/10)); HI=$((WANT_MEM*11/10+1))
if [ "$HAVE_GB" -lt "$LO" ] || [ "$HAVE_GB" -gt "$HI" ]; then say "NOT-CONSOLE: mem=${HAVE_GB}GB (tuned for ${WANT_MEM}GB ±10%)"; fail=1; fi

if [ "$fail" = 0 ]; then say "CONSOLE-OK: $HAVE_ARCH, ${HAVE_CORES} cores, ${HAVE_GB} GiB (tuned)"; fi
exit "$fail"
