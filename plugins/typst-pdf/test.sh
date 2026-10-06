#!/bin/bash
# acceptance test: typst-pdf (rendered by assembler)
set -u
D="$(cd "$(dirname "$0")" && pwd)"
"$D/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }
export PATH="$D/bin:$PATH"
cd "$D"
fail=0
echo "  [version reports]"
if out=$(timeout 30 "$D/driver.sh" --version 2>&1); then
  if printf "%s" "$out" | grep -q "typst 0.15.1"; then echo "    PASS";
  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
echo "  [compiles a minimal doc]"
if out=$(timeout 30 "$D/driver.sh" cases/hello.typ cases/hello.pdf 2>&1); then
  if [ -f "cases/hello.pdf" ]; then echo "    PASS";
  else echo "    FAIL: expected file missing"; echo "$out" | head -5; fail=1; fi
else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi
exit $fail
