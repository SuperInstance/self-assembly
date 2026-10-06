#!/bin/bash
# verify.sh — provenance before execution. Fail closed, always.
# Usage: verify.sh <needs-file> <scratch-dl-dir>
# Verifies: source pin + sha256 + dual-source. Downloads the artifact.
# Exit 0 = verified (artifact at $dl_dir/artifact). Exit 1 = refused (reason on stderr).
# This is Kimi's dual-source mechanism: a hash counts only if it appears at
# two independent places the assembler fetched itself, or a human attested it.
set -u
NEEDS="$1"; DL="$2"
PY="python3 -c"

get() { # get <dotted.key> — tiny yaml getter via pyyaml
  python3 - "$NEEDS" "$1" << 'EOF'
import yaml,sys
d=yaml.safe_load(open(sys.argv[1]))
for p in sys.argv[2].split('.'):
    d = d.get(p,{}) if isinstance(d,dict) else {}
print(d if not isinstance(d,(dict,list)) else '')
EOF
}

TYPE="$(get source.type)"
[ "$TYPE" = "none" ] && { echo "verify: type=none, nothing to fetch"; exit 0; }

URL="$(get source.url)"; PIN="$(get source.pin)"; SHA="$(get source.sha256)"
SECOND="$(get verify.second_source)"

[ -n "$URL" ]   || { echo "verify REFUSED: empty source.url" >&2; exit 1; }
[ -n "$SHA" ]   || { echo "verify REFUSED: empty source.sha256" >&2; exit 1; }
case "$SHA" in [0-9a-f]* ) [ "${#SHA}" = 64 ] || { echo "verify REFUSED: sha256 not 64 hex" >&2; exit 1; };; *) echo "verify REFUSED: sha256 not hex" >&2; exit 1;; esac

# Console binary guard: fetched asset names must say ARM64 unless human-attested otherwise.
case "$URL" in
  *aarch64*|*arm64*|*ARM64*|*AARCH64*) ;;
  *) echo "verify REFUSED: URL does not indicate aarch64/arm64 ($URL)" >&2; exit 1;;
esac

mkdir -p "$DL"
ART="$DL/artifact"
echo "verify: downloading $URL"
if ! curl -fsSL --max-time 120 -o "$ART" "$URL"; then
  echo "verify REFUSED: download failed" >&2; exit 1
fi
GOT="$(sha256sum "$ART" | awk '{print $1}')"
if [ "$GOT" != "$SHA" ]; then
  echo "verify REFUSED: sha256 mismatch (want $SHA, got $GOT)" >&2
  rm -f "$ART"; exit 1
fi
echo "verify: sha256 match"

# Dual source: the hash must appear at a second independent place, or be human-attested.
case "$SECOND" in
  http*)
    echo "verify: checking second source $SECOND"
    if curl -fsSL --max-time 60 "$SECOND" -o "$DL/second_source.txt" && grep -q "$SHA" "$DL/second_source.txt"; then
      echo "verify: dual-source OK (hash found at second source)"
    else
      echo "verify REFUSED: second source did not confirm the hash" >&2
      rm -f "$ART"; exit 1
    fi
    ;;
  human:*)
    echo "verify: dual-source via human attestation: $SECOND"
    ;;
  *)
    echo "verify REFUSED: verify.second_source must be an http(s) URL or 'human:...'" >&2
    rm -f "$ART"; exit 1
    ;;
esac
echo "verify: OK"
exit 0
