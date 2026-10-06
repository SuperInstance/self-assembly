# DEBT.md — the ledger of things we know are wrong

Debts are named, dated, and owned. A debt is not a bug; it is a known
compromise with a named next step. The run_shell hole is entry #1 by
charter — it goes on the ledger BY NAME on day one.

## #6 — PROVEN: install sandbox leaks the filesystem (OPEN, 2026-10-06)

Status upgrade: this was entry #1/#2 in theory; it is now PROVEN by
analysis (no live exploit was run — deliberately).

The v1 install sandbox is `env -i` + `timeout 120`. That stops *environment*
exfiltration. It does NOT stop filesystem reads. `install.sh` runs as the
`ubuntu` user, and everything the `ubuntu` user can read, it can read:

- `~/.self-assembly-cpu-secret` (mode 600, owned by ubuntu) — the CPU API
  bearer token. A malicious install recipe can `cat` it in one line.
- `~/.ssh/` keys, the git repo, LEDGER.md, every plugin's driver and ledger.
- Writable: /tmp, scratch/, the plugin's own `bin/` DEST, and anything else
  ubuntu owns in the tree.

Concretely: a typosquatted or compromised source that passes the pin check
(because the attacker controls the release artifact the pin was taken from —
see Kimi's "second source" requirement, which exists precisely for this)
would execute with full read access to the box's secrets during the 120 s
window. The 120 s leash bounds *compute*, not *reach*.

This is the concrete justification for the bench split as the next step:
fetched code must never execute as a user that can read the secrets it
should never see. Options in order: (a) bench split — separate uid / mount
namespace for fetched code, no secret files visible; (b) per-plugin unix
user with no home-dir overlap; (c) keep v1 sandbox but move ALL secrets
out of ubuntu-readable paths (defense in depth, not a fix). Until one of
these lands, treat every install as running with the reader's eyes open:
provenance is verified BEFORE execution, and that verification is the only
real gate. Do not install anything you have not reason to trust.

## #5 — CPU API reachability (OPEN, 2026-10-06)

`cpu-api.py` binds 127.0.0.1:8777 (localhost only) and the CPU path is proven
via local POST. GitHub-hosted runners cannot reach Oracle's loopback, so the
"runner POSTs to Oracle" leg is not yet physically possible. Options, in
order of preference: (a) Cloudflare Tunnel exposing the API with the bearer
token intact (no new auth design); (b) open 443/tcp on the OCI security list
+ TLS termination (certbot) in front of the API — never expose the bearer
token in cleartext; (c) invert the direction: the wake loop polls a
GitHub-hosted event inbox (abandons the POST design; needs a read token on
Oracle, which violates "Oracle never holds GitHub tokens" — weakest option).
Do NOT bind 0.0.0.0 without TLS. Until reachability is solved, Track A
keeps its current thinking loop and the CPU serves local proof + future
integration.

## #1 — the run_shell hole (OPEN, 2026-10-06)

Claude's warning, recorded verbatim on day one: the assembler and wake loop
execute shell next to credentials, and prompt-level discouragement is not
isolation. A malicious `install.sh` runs as the `ubuntu` user with the
ambient environment of the wake process.

v1 mitigations (real but partial):
- 120 s leash on every plugin/install invocation (`timeout 120`).
- Scrubbed env: assembler strips all `*_TOKEN`, `*_SECRET`, `*_KEY`,
  `VAULT_*`, `GH_*`, `AWS_*` variables before executing fetched code.
- Scratch-only writes for installs; repo writes only through the assembler.
- Pinned provenance (commit SHA + sha256 + dual-source) before anything runs.

None of this is isolation. The real fix is the bench split: fetched code
never runs in a job that can mint tokens (see
`~/workspace/self-assembly-versions/SYNTHESIS.md`, "Target"). Until then
this debt stays OPEN and named. It is the first thing a reviewer should ask
about, which is why it is entry #1.

## #2 — coarse sandboxing (OPEN, 2026-10-06)

No per-plugin unix user, no network namespace, no seccomp. v1 runs
everything as `ubuntu` and relies on provenance + review instead of
isolation (MiniMax's conscious debt, adopted). The bench split resolves
this too. Do not mistake "pinned hash" for "safe to run" — a pin proves
the bits are the bits that were tested, not that the bits are benign.

## #3 — lfm25 judge reliability (OPEN, 2026-10-06)

`assembler/ask_judge.sh` calls the on-box `lfm25-1.2b` for one bounded
judgment per decision point. Observed 2026-10-06: the model returns empty
output to single-word classification prompts and answers its own questions
instead of emitting structured output. v1 therefore treats the judge as
advisory-only and FAILS CLOSED: unparseable/empty verdict → ESCALATE →
ledger entry → human. The strong-brain path (vault LLM) is designed
(`assembler/ask_judge.sh` has the hook) but not fired without explicit
authorization. Revisit when the local model changes or the vault path opens.

## #4 — no dependency solver (OPEN, 2026-10-06)

One fetch shape per plugin (`none`, `tarball`, `git`). No pypi/npm
resolvers — each is a second trust story we have not written. If a plugin
needs a second tool, that is a second plugin or a human decision, recorded
in the manifest. Revisit with a lockfile design, not before.
