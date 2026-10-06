#!/bin/bash
# wake.sh — the console's heartbeat. Run by cron every 15 minutes.
# (The crabs use 10m; the CPU gets 15m — assembly is heavier than watching.)
#
# Each wake:
#   1. probe-console.sh — not on the console? ledger + halt. No adaptation.
#   2. supervise cpu-api.py — running? if not, start it (nohup, log to cpu-api.log).
#   3. validate manifests — malformed? skip + ledger, never break the boot.
#   4. process needs/ — oldest proposal first, max 1 assembly per wake.
#   5. health-check registered plugins — run each probe.sh (60s leash).
#   6. ledger + git commit (the commit is the receipt).
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
mkdir -p scratch needs/done needs/rejected

ts() { date -u +%FT%TZ; }
log() { echo "## $(ts) — wake: $*" >> LEDGER.md; }

# 0. never disturb the crabs' neighborhood; we live in our own tree. (No-op guard.)

# 1. console check
if ! assembler/probe-console.sh --quiet; then
  log "HALT: not on the console"
  exit 1
fi

# 2. supervise the CPU API
if ! pgrep -f "cpu-api.py" > /dev/null 2>&1; then
  log "cpu-api not running — starting"
  nohup python3 cpu-api/cpu-api.py >> cpu-api/cpu-api.log 2>&1 &
  sleep 2
  pgrep -f "cpu-api.py" > /dev/null 2>&1 && log "cpu-api started" || log "cpu-api FAILED to start"
fi

# 3+4. manifest validation + needs processing (one assembly per wake)
assembled=0
for mf in plugins/*/manifest.yaml; do
  [ -f "$mf" ] || continue
  n="$(basename "$(dirname "$mf")")"
  if ! python3 -c "
import yaml,sys
d=yaml.safe_load(open('$mf'))
assert isinstance(d,dict) and d.get('name')=='$n' and d.get('when'), 'bad manifest'
" 2>/dev/null; then
    log "plugin '$n' SKIPPED: malformed manifest (boot continues)"
  fi
done

if [ "$assembled" = 0 ]; then
  # count concurrent builds (markers are gitignored, so they reflect live state)
  building="$(ls needs/*.building 2>/dev/null | wc -l)"
  if [ "$building" -lt 3 ]; then
    oldest="$(ls -tr needs/*.yaml 2>/dev/null | head -1)"
    if [ -n "$oldest" ]; then
      log "assembling $oldest"
      if assembler/assemble.sh "$oldest"; then
        log "assembly of $oldest succeeded"
      else
        log "assembly of $oldest failed (see above; proposal filed under rejected/ or left for retry)"
      fi
      assembled=1
    fi
  else
    log "3 assemblies already in progress — deferring"
  fi
fi

# 5. health checks (60s leash each, failures ledgered, never fatal)
for p in plugins/*/; do
  [ -d "$p" ] || continue
  n="$(basename "$p")"
  [ "$n" = "README.md" ] && continue
  if [ -x "$p/probe.sh" ]; then
    if timeout 60 "$p/probe.sh" > /dev/null 2>&1; then
      : # healthy is the quiet path; ledger stays small
    else
      log "plugin '$n' UNHEALTHY (probe failed)"
    fi
  fi
done

# 6. commit the receipt
git add -A 2>/dev/null
if ! git diff --cached --quiet 2>/dev/null; then
  git -c user.name=cpu -c user.email=cpu@console.local commit -qm "wake $(ts)" 2>/dev/null \
    && log "committed" || log "commit failed (non-fatal)"
else
  log "nothing to commit"
fi
log "wake done"
