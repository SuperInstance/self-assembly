#!/bin/bash
# probe: net-latency (rendered by assembler)
set -u
D="$(cd "$(dirname "$0")" && pwd)"
"$D/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }

cd "$D"
fail=0
echo "  [127.0.0.1]"
if out=$(timeout 15 "$D/driver.sh" 127.0.0.1 2>&1); then
  if printf "%s" "$out" | grep -q "4 packets transmitted"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
exit $fail
