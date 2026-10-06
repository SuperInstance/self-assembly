#!/usr/bin/env python3
# render.py — renders a plugin directory from a needs/ proposal.
# Usage: render.py <needs-file> <plugins-dir>
# Writes plugins/<name>/{manifest.yaml, driver.sh, probe.sh, test.sh}
# and prints the plugin dir. Exits nonzero on bad spec.
import sys, os, yaml, stat

needs_file, plugins_dir = sys.argv[1], sys.argv[2]
spec = yaml.safe_load(open(needs_file))
name = spec['name']
assert name.replace('-', '').replace('_', '').isalnum(), "bad plugin name"
pdir = os.path.join(plugins_dir, name)
os.makedirs(os.path.join(pdir, 'cases'), exist_ok=True)
os.makedirs(os.path.join(pdir, 'ledger'), exist_ok=True)

src = spec.get('source', {})
drv = spec.get('driver', {})
path_extra = drv.get('path_extra', '')
env_line = f'export PATH="{path_extra}:$PATH"\n' if path_extra else ''

def sh_body(checks, label):
    lines = ["#!/bin/bash", f"# {label}: {name} (rendered by assembler)", "set -u",
             'D="$(cd "$(dirname "$0")" && pwd)"',
             '"$D/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }',
             env_line.rstrip(), "fail=0"]
    for c in checks:
        args = c.get('args', '')
        want = c['expect_contains']
        to = c.get('timeout_s', 30)
        nm = c.get('name', args)
        lines += [
            f'echo "  [{nm}]"',
            f'if out=$(timeout {to} "$D/driver.sh" {args} 2>&1); then',
            f'  if printf "%s" "$out" | grep -q "{want}"; then echo "    PASS";',
            '  else echo "    FAIL: missing expected text"; echo "$out" | head -5; fail=1; fi',
            'else echo "    FAIL: driver exited nonzero"; echo "$out" | head -5; fail=1; fi',
        ]
    lines += ['exit $fail', '']
    return "\n".join(l for l in lines if l is not None)

driver_sh = "\n".join([
    "#!/bin/bash", f"# driver.sh: {name} (rendered by assembler)", "set -u",
    'PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"',
    '"$PLUGIN_DIR/../../assembler/probe-console.sh" --quiet || { echo "FATAL: not on the console" >&2; exit 3; }',
    env_line.rstrip(),
    f'exec {drv["command"]} "$@"', ""
])

files = {
    'driver.sh': driver_sh,
    'probe.sh': sh_body(spec.get('probe', []), 'probe'),
    'test.sh': sh_body(spec.get('tests', []), 'acceptance test'),
    'manifest.yaml': yaml.safe_dump({
        'name': name,
        'version': '0.1.0',
        'when': spec['when'],
        'source': {k: src.get(k, '') for k in ('type', 'url', 'pin', 'sha256')},
        'verify': {'second_source': spec.get('verify', {}).get('second_source', '')},
        'grants': ['run_shell'],
        'install': './install.sh' if src.get('type', 'none') != 'none' else '',
        'health': './probe.sh',
        'accept': './test.sh',
        'inner_agents': [],
    }, sort_keys=False),
}
for fn, content in files.items():
    p = os.path.join(pdir, fn)
    open(p, 'w').write(content)
    if fn.endswith('.sh'):
        os.chmod(p, os.stat(p).st_mode | stat.S_IXUSR | stat.S_IXGRP)
open(os.path.join(pdir, 'BUILD.jsonl'), 'a').write(
    '{"event":"rendered","at":"%s","from":"%s"}\n' % (__import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat(), needs_file))
print(pdir)
