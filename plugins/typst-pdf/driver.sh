#!/bin/bash
# driver.sh: typst-pdf (rendered by assembler)
set -u
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
"$PLUGIN_DIR/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }
export PATH="$PLUGIN_DIR/bin:$PATH"
case "${1:-}" in "--version" | "--help") exec typst "$@";; esac
exec typst compile "$@"
