#!/bin/bash
# ask_judge.sh — one bounded LLM call, fail-closed. The judge hook.
# Usage: ask_judge.sh <plugin-name> <question-file>
# Contract: the model must reply with a first line matching
#   VERDICT: PASS | VERDICT: FAIL | VERDICT: RETRY | VERDICT: ESCALATE
# Anything else (empty output, prose, evasions) -> VERDICT: ESCALATE + ledger.
# The judge is advisory-only in v1; the caller decides, and logs the override.
# Exit 0 always (the verdict is on stdout); the caller interprets.
set -u
PLUGIN="$1"; QFILE="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/scratch/judge-$(date +%s).out"

QUESTION="$(cat "$QFILE")"
PROMPT="You are a build judge for the plugin '$PLUGIN'. Read the situation, then reply with EXACTLY one line as your first line: VERDICT: PASS or VERDICT: FAIL or VERDICT: RETRY or VERDICT: ESCALATE. Then at most two short lines of reason. Situation: $QUESTION"

if ! curl -s --max-time 60 http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d "$(python3 -c "import json,sys; print(json.dumps({'model':'lfm25-1.2b','prompt':sys.argv[1],'stream':False,'options':{'num_predict':60}}))" "$PROMPT")" \
  -o "$OUT" 2>/dev/null; then
  echo "VERDICT: ESCALATE"; echo "judge transport failed" >> "$ROOT/LEDGER.md"
  echo "## $(date -u +%FT%TZ) — judge $PLUGIN: transport failure -> ESCALATE" >> "$ROOT/LEDGER.md"
  exit 0
fi
FIRST="$(python3 -c "
import json,sys
try:
    d=json.load(open('$OUT')); r=d.get('response','')
except Exception: r=''
for line in r.splitlines():
    s=line.strip()
    if s: print(s); break
" 2>/dev/null)"
case "$FIRST" in
  "VERDICT: PASS"|"VERDICT: FAIL"|"VERDICT: RETRY"|"VERDICT: ESCALATE")
    echo "$FIRST" ;;
  *)
    echo "VERDICT: ESCALATE"
    echo "## $(date -u +%FT%TZ) — judge $PLUGIN: unparseable verdict (got: '${FIRST:0:80}') -> ESCALATE (fail-closed)" >> "$ROOT/LEDGER.md"
    ;;
esac
rm -f "$OUT"
exit 0
