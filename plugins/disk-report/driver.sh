#!/bin/bash
# driver.sh: disk-report (rendered by assembler)
set -u
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
"$PLUGIN_DIR/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }

exec df -h "$@"
