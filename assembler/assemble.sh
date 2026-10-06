#!/bin/bash
# assemble.sh — the fixed assembler's 8-step loop (Kimi's sequence, console-adapted).
# Usage: assemble.sh <needs-file>
# Steps: parse → verify provenance → install (scratch) → console probe →
#        render driver/probe/test → acceptance test (bounded retries w/ judge) →
#        register (or reject with reason). Every step ledgered. Fail closed.
set -u
NEEDS="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
A="$ROOT/assembler"
mkdir -p "$ROOT/scratch" "$ROOT/needs/done" "$ROOT/needs/rejected"
NAME="$(basename "$NEEDS" .yaml)"
BUILDING="$NEEDS.building"

log() { echo "## $(date -u +%FT%TZ) — assemble $NAME: $*" >> "$ROOT/LEDGER.md"; }
blog() { echo "{\"t\":\"$(date -u +%FT%TZ)\",\"e\":\"$1\"}" >> "$ROOT/plugins/$NAME/BUILD.jsonl" 2>/dev/null || true; }

[ -f "$NEEDS" ] || { echo "assemble: no such needs file: $NEEDS" >&2; exit 1; }
touch "$BUILDING"  # gitignored marker: assembly in progress
trap 'rm -f "$BUILDING"' EXIT
log "start (from $NEEDS)"

# 1. parse + validate spec
if ! python3 -c "
import yaml,sys
s=yaml.safe_load(open('$NEEDS'))
assert s.get('name')=='$NAME', 'name mismatch'
assert s.get('driver',{}).get('command'), 'driver.command required'
assert s.get('when'), 'when required'
" 2>/dev/null; then
  log "REJECTED: invalid spec"
  mkdir -p "$ROOT/needs/rejected"
  { echo "rejected_at: $(date -u +%FT%TZ)"; echo "rejected_reason: invalid spec (name/when/driver.command)"; } >> "$NEEDS"
  mv "$NEEDS" "$ROOT/needs/rejected/$NAME.yaml"
  exit 1
fi

DL="$ROOT/scratch/dl-$NAME"
# 2. provenance (fail closed)
if ! "$A/verify.sh" "$NEEDS" "$DL"; then
  log "REJECTED: provenance verification failed"
  mkdir -p "$ROOT/needs/rejected"
  { echo "rejected_at: $(date -u +%FT%TZ)"; echo "rejected_reason: provenance failed (see LEDGER)"; } >> "$NEEDS"
  mv "$NEEDS" "$ROOT/needs/rejected/$NAME.yaml"
  exit 1
fi

# 3. install (scratch only, scrubbed env, 120s leash) — skipped when type=none
STYPE="$(python3 -c "import yaml; print(yaml.safe_load(open('$NEEDS')).get('source',{}).get('type','none'))")"
if [ "$STYPE" != "none" ]; then
  INST_SH="$ROOT/scratch/install-$NAME.sh"
  # v1: the install recipe comes from the proposal's install_recipe field, or a default unpack.
  python3 - "$NEEDS" "$INST_SH" "$DL" << 'EOF'
import yaml,sys
s=yaml.safe_load(open(sys.argv[1]))
recipe = s.get('install_recipe', 'tar -xf "$ART" -C "$DEST" --strip-components=1')
open(sys.argv[2],'w').write("#!/bin/bash\nset -u\nART='"+sys.argv[3]+"/artifact'\nDEST=\"$1\"\nmkdir -p \"$DEST\"\n"+recipe+"\n")
EOF
  chmod +x "$INST_SH"
  DEST="$ROOT/plugins/$NAME/bin"  # on-disk only, gitignored, never committed
  mkdir -p "$DEST"
  log "installing to $DEST (120s leash, scrubbed env)"
  # shellcheck disable=SC2086
  if ! env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
       timeout 120 "$INST_SH" "$DEST" > "$ROOT/scratch/install-$NAME.log" 2>&1; then
    log "REJECTED: install failed"
    mkdir -p "$ROOT/needs/rejected"
    { echo "rejected_at: $(date -u +%FT%TZ)"; echo "rejected_reason: install failed"; } >> "$NEEDS"
    mv "$NEEDS" "$ROOT/needs/rejected/$NAME.yaml"
    exit 1
  fi
fi

# 4. console probe (already done by wake, re-asserted per plugin)
"$A/probe-console.sh" --quiet || { log "REJECTED: not on console"; exit 1; }

# 5. render driver/probe/test/manifest
PDIR="$("$A/render.py" "$NEEDS" "$ROOT/plugins")" || { log "REJECTED: render failed"; exit 1; }
blog "rendered"
# link installed bin into PATH for the driver if the spec didn't already
if [ -d "$ROOT/plugins/$NAME/bin" ] && ! grep -q 'PLUGIN_DIR/bin' "$PDIR/driver.sh"; then
  sed -i 's|^"$PLUGIN_DIR/../../assembler/probe-console.sh" --quiet.*|&\nexport PATH="$PLUGIN_DIR/bin:$PATH"|' "$PDIR/driver.sh"
  chmod +x "$PDIR/driver.sh"
  log "PATH patched to include plugin bin/"
fi

# 6. acceptance test, bounded retries with judge consult
tries=0; MAXT=5
while [ $tries -lt $MAXT ]; do
  tries=$((tries+1))
  if timeout 120 "$PDIR/test.sh" > "$ROOT/scratch/test-$NAME-$tries.log" 2>&1; then
    log "acceptance test passed (try $tries)"
    blog "test-pass try=$tries"
    break
  fi
  log "acceptance test failed (try $tries)"
  blog "test-fail try=$tries"
  # mechanical fix rules (v1, tiny and explicit):
  if grep -q "command not found" "$ROOT/scratch/test-$NAME-$tries.log" && [ -d "$ROOT/plugins/$NAME/bin" ]; then
    log "mechanical fix: prepending bin/ to driver PATH"
    sed -i '1a export PATH="$PLUGIN_DIR/bin:$PATH"' "$PDIR/driver.sh"
    chmod +x "$PDIR/driver.sh"
    continue
  fi
  if grep -q "Permission denied" "$ROOT/scratch/test-$NAME-$tries.log"; then
    log "mechanical fix: chmod +x on plugin scripts"
    chmod +x "$PDIR/"*.sh
    continue
  fi
  # genuine ambiguity: ask the judge (one bounded call, fail-closed)
  Q="$ROOT/scratch/judge-q-$NAME.txt"
  { echo "Plugin '$NAME' acceptance test failed (try $tries of $MAXT)."; echo "Last lines:"; tail -5 "$ROOT/scratch/test-$NAME-$tries.log"; } > "$Q"
  VERDICT="$("$A/ask_judge.sh" "$NAME" "$Q")"
  log "judge verdict: $VERDICT"
  blog "judge try=$tries verdict=$VERDICT"
  case "$VERDICT" in
    "VERDICT: RETRY") continue ;;
    *) break ;;
  esac
done

if ! timeout 120 "$PDIR/test.sh" > /dev/null 2>&1; then
  log "REJECTED: acceptance test failed after $tries tries"
  mkdir -p "$ROOT/needs/rejected"
  { echo "rejected_at: $(date -u +%FT%TZ)"; echo "rejected_reason: acceptance test failed after $tries tries"; } >> "$NEEDS"
  mv "$NEEDS" "$ROOT/needs/rejected/$NAME.yaml"
  # keep the rendered dir for forensics, but it is NOT registered (no manifest move needed;
  # register.sh is the only path that files needs/done/)
  exit 1
fi

# 7. register (validates + files the proposal as done)
if ! "$A/register.sh" "$PDIR" "$NEEDS"; then
  log "REJECTED: registration validation failed"
  exit 1
fi
log "REGISTERED plugins/$NAME"
echo "assemble: $NAME OK"
