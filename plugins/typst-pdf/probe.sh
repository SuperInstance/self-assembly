#!/bin/bash
# probe: typst-pdf (rendered by assembler)
set -u
D="$(cd "$(dirname "$0")" && pwd)"
"$D/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }
export PATH="$D/bin:$PATH"
cd "$D"
fail=0
echo "  [--version]"
if out=$(timeout 15 "$D/driver.sh" --version 2>&1); then
  if printf "%s" "$out" | grep -q "0.15.1"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
exit $fail
