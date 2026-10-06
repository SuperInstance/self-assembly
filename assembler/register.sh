#!/bin/bash
# register.sh — validate a rendered plugin and file the proposal as done.
# Usage: register.sh <plugin-dir> <needs-file>
# Validations (fail-closed): manifest parses, name == directory name,
# required fields present, test.sh exits 0. On success the needs file moves
# to needs/done/ with registered_at appended. Nothing here installs anything.
set -u
PDIR="$1"; NEEDS="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$PDIR")"

vfail() { echo "register REFUSED: $1" >&2; return 1; }

[ -f "$PDIR/manifest.yaml" ] || vfail "no manifest.yaml"
MN="$(python3 -c "import yaml; print(yaml.safe_load(open('$PDIR/manifest.yaml')).get('name',''))")"
[ "$MN" = "$NAME" ] || vfail "manifest name '$MN' != directory '$NAME'"
for f in when health accept; do
  python3 -c "import yaml,sys; d=yaml.safe_load(open('$PDIR/manifest.yaml')); sys.exit(0 if d.get('$f') else 1)" \
    || vfail "manifest missing '$f'"
done
[ -x "$PDIR/test.sh" ] || vfail "test.sh not executable"
[ -x "$PDIR/driver.sh" ] || vfail "driver.sh not executable"

echo "register: running acceptance test for $NAME"
if ! timeout 120 "$PDIR/test.sh" > "$ROOT/scratch/register-$NAME.log" 2>&1; then
  echo "register REFUSED: test.sh failed (see scratch/register-$NAME.log):" >&2
  tail -5 "$ROOT/scratch/register-$NAME.log" >&2
  exit 1
fi

mkdir -p "$ROOT/needs/done"
{ echo ""; echo "registered_at: $(date -u +%FT%TZ)"; echo "registered_by: assembler"; } >> "$NEEDS"
mv "$NEEDS" "$ROOT/needs/done/$NAME.yaml"
echo "{\"event\":\"registered\",\"at\":\"$(date -u +%FT%TZ)\"}" >> "$PDIR/BUILD.jsonl"
echo "register: $NAME OK"
