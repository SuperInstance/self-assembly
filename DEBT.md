# DEBT.md — the ledger of things we know are wrong

Debts are named, dated, and owned. A debt is not a bug; it is a known
compromise with a named next step. The run_shell hole is entry #1 by
charter — it goes on the ledger BY NAME on day one.

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
