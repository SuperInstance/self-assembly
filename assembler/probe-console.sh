#!/bin/bash
# probe-console.sh — "are we on the console?"
# Hardcoded spec, not discovery. Exit 0 = yes. Exit 1 = no (reason on stderr).
# Usage: probe-console.sh [--quiet]
set -u
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
say() { [ "$QUIET" = 1 ] || echo "$*" >&2; }

fail=0
ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then say "NOT-CONSOLE: arch=$ARCH (want aarch64)"; fail=1; fi

CORES="$(nproc)"
if [ "$CORES" -lt 4 ]; then say "NOT-CONSOLE: cores=$CORES (want >=4)"; fail=1; fi

MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
# 22 GiB floor (23 GB box, some slack for the kernel's accounting)
if [ "$MEM_KB" -lt 23000000 ]; then say "NOT-CONSOLE: mem_kb=$MEM_KB (want >=23000000)"; fail=1; fi

if ! grep -qi 'ubuntu' /etc/os-release 2>/dev/null; then say "NOT-CONSOLE: not Ubuntu"; fail=1; fi

if [ "$fail" = 0 ]; then say "CONSOLE-OK: aarch64, ${CORES} cores, $((MEM_KB/1024/1024)) GiB"; fi
exit "$fail"
