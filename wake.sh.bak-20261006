#!/bin/bash
# wake.sh — the console's heartbeat. Run by cron every 15 minutes.
# (The crabs use 10m; the CPU gets 15m — assembly is heavier than watching.)
#
# Boot order (each gate fails safe):
#   0. ethos: tuned? If .tuned.yaml is missing or tuned != true, run the
#      hardware agent. If ethos fails -> ledger + HALT. No real work untuned.
#   1. probe-console.sh — are we on the box we tuned for? No -> halt.
#   2. disk guard — free space below the tuned floor? No new assemblies
#      (health checks still run).
#   3. supervise cpu-api.py — start it if not running.
#   4. validate manifests — malformed? skip + ledger, never break the boot.
#   5. process needs/ — oldest proposal first, max 1 assembly per wake.
#   6. health-check registered plugins (60s leash each).
#   7. log rotation — LEDGER.md > 2MB -> ledger/archive/.
#   8. ledger + git commit (the commit is the receipt).
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
mkdir -p scratch needs/done needs/rejected ledger/archive

ts() { date -u +%FT%TZ; }
log() { echo "## $(ts) — wake: $*" >> LEDGER.md; }
tuned_val() { python3 -c "import yaml; print(yaml.safe_load(open('.tuned.yaml')).get('$1',''))" 2>/dev/null; }

# 0. ethos gate — no real work until the hardware agent signs off
if [ "${1:-}" = "--retune" ]; then
  log "retune requested"
  assembler/ethos/ethos.sh || { log "HALT: ethos retune failed"; exit 1; }
fi
if [ ! -f .tuned.yaml ] || [ "$(tuned_val tuned)" != "True" ]; then
  log "not tuned — running ethos agent"
  if ! assembler/ethos/ethos.sh; then
    log "HALT: ethos failed — refusing real work"
    exit 1
  fi
fi

# 1. console check (against the tuned spec)
if ! assembler/probe-console.sh --quiet; then
  log "HALT: not on the tuned console"
  exit 1
fi

# 2. disk guard
FLOOR_GB="$(tuned_val disk_floor_gb)"; [ -n "$FLOOR_GB" ] || FLOOR_GB=10
FREE_GB=$(( $(df --output=avail -BG / | tail -1 | tr -dc '0-9') ))
DISK_OK=1
if [ "$FREE_GB" -lt "$FLOOR_GB" ]; then
  log "disk guard: ${FREE_GB}GB free < floor ${FLOOR_GB}GB — no new assemblies this wake"
  DISK_OK=0
fi

# 3. supervise the CPU API
if ! pgrep -f "cpu-api.py" > /dev/null 2>&1; then
  log "cpu-api not running — starting"
  nohup python3 cpu-api/cpu-api.py >> cpu-api/cpu-api.log 2>&1 &
  sleep 2
  pgrep -f "cpu-api.py" > /dev/null 2>&1 && log "cpu-api started" || log "cpu-api FAILED to start"
fi

# 4. manifest validation
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

# 5. needs processing (one assembly per wake, max 3 concurrent, disk guard)
building="$(ls needs/*.building 2>/dev/null | wc -l)"
if [ "$DISK_OK" = 1 ] && [ "$building" -lt 3 ]; then
  oldest="$(ls -tr needs/*.yaml 2>/dev/null | head -1)"
  if [ -n "$oldest" ]; then
    log "assembling $oldest"
    if assembler/assemble.sh "$oldest"; then
      log "assembly of $oldest succeeded"
    else
      log "assembly of $oldest failed (proposal filed under rejected/ or left for retry)"
    fi
  fi
elif [ "$DISK_OK" = 0 ]; then
  : # disk guard already ledgered
else
  log "3 assemblies already in progress — deferring"
fi

# 6. health checks (60s leash each, failures ledgered, never fatal)
for p in plugins/*/; do
  [ -d "$p" ] || continue
  n="$(basename "$p")"
  if [ -x "$p/probe.sh" ]; then
    timeout 60 "$p/probe.sh" > /dev/null 2>&1 || log "plugin '$n' UNHEALTHY (probe failed)"
  fi
done

# 7. log rotation
if [ -f LEDGER.md ] && [ "$(stat -c%s LEDGER.md)" -gt 2097152 ]; then
  mv LEDGER.md "ledger/archive/LEDGER-$(ts | tr ':+' '--').md"
  echo "# LEDGER.md — append-only run log (rotated $(ts))" > LEDGER.md
  log "ledger rotated"
fi

# 8. commit the receipt
git add -A 2>/dev/null
if ! git diff --cached --quiet 2>/dev/null; then
  git -c user.name=cpu -c user.email=cpu@console.local commit -qm "wake $(ts)" 2>/dev/null \
    && log "committed" || log "commit failed (non-fatal)"
else
  log "nothing to commit"
fi
log "wake done"
