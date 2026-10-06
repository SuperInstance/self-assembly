#!/bin/bash
# acceptance test: net-latency (rendered by assembler)
set -u
D="$(cd "$(dirname "$0")" && pwd)"
"$D/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }

cd "$D"
fail=0
echo "  [localhost pings]"
if out=$(timeout 30 "$D/driver.sh" 127.0.0.1 2>&1); then
  if printf "%s" "$out" | grep -q "0% packet loss"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
echo "  [reports timing]"
if out=$(timeout 30 "$D/driver.sh" 127.0.0.1 2>&1); then
  if printf "%s" "$out" | grep -q "avg"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
exit $fail
