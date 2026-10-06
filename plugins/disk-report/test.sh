#!/bin/bash
# acceptance test: disk-report (rendered by assembler)
set -u
D="$(cd "$(dirname "$0")" && pwd)"
"$D/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }

fail=0
echo "  [root fs listed]"
if out=$(timeout 30 "$D/driver.sh" / 2>&1); then
  if printf "%s" "$out" | grep -q "/dev/"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
echo "  [human readable sizes]"
if out=$(timeout 30 "$D/driver.sh" /home 2>&1); then
  if printf "%s" "$out" | grep -q "G"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
exit $fail
