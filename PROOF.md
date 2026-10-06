# PROOF.md — Track B self-assembly v1: what was built, what was proven

2026-10-06. Oracle console agent (Track B): the persistent CPU for the
git-native organism. GitHub Actions = senses/hands; Oracle = the self.

## What was built

- **Fixed assembler** (`assembler/`): `assemble.sh` (detect→propose→verify→
  install→probe→test→register), `verify.sh` (pin + sha256 + dual-source),
  `register.sh`, `ask_judge.sh` (one bounded local judgment, advisory-only,
  fails closed), `probe-console.sh` (are we on the tuned box?),
  `render.py`. Human-owned, never grown.
- **Ethos agent** (`assembler/ethos/`): hardware tuner. Probes the box once,
  writes `.tuned.yaml` (cores, RAM, arch, disk floor). wake.sh refuses real
  work until ethos signs off.
- **Plugin manifest**: `plugins/<name>/manifest.yaml` (name == dir, `when`
  trigger, source pin + sha256 + second_source, grants). NO index file —
  the directory listing is the registry.
- **CPU API** (`cpu-api/cpu-api.py`): stdlib-only, 127.0.0.1:8777, bearer
  auth (`~/.self-assembly-cpu-secret`, mode 600). `POST /event` → action
  plan. `think.py` structures the think step.
- **wake.sh heartbeat** (cron `*/15`): ethos gate → console probe → disk
  guard → cpu-api supervise → manifest validation (malformed → skip + file
  issue, never fatal) → needs processing (1 assembly/wake, max 3
  concurrent) → plugin health checks (60 s leash) → log rotation → git
  commit (the commit is the receipt).
- **Three plugins grown**: `disk-report`, `typst-pdf`, `net-latency`
  (each: manifest.yaml, driver.sh, probe.sh, test.sh, cases/, ledger/,
  BUILD.jsonl).
- **CONSOLE.md** (hardcoded spec: 4x ARM Neoverse-N1, 23 GB RAM, Ubuntu
  26.04), **CLONE.md** (the ranch-hand story), **DEBT.md** (6 named debts),
  **LEDGER.md** (append-only run log).

## Proof ritual: PASSED

`disk-report` was hand-built, then DELETED, then re-grown from a
`needs/disk-report.yaml` proposal with no human intervention beyond the
proposal itself. Git: commit `ba8d29c "proof ritual: disk-report re-grown
from proposal"`. Ledger shows two REGISTERED entries (first build
02:21:38Z, re-growth 02:22:05Z). The loop is real: the agent can lose
equipment and reconstitute it from a stated desire.

## Attack results

| Attack | Result |
|---|---|
| Typosquat second source (`evil-probe`) | REFUSED. `REJECTED: provenance verification failed` (ledger, 2 attempts). Dual-source enforced. |
| Dual-source bypass attempt | Failed — hash must appear at two independent URLs or a signed/human approval. |
| Unauthenticated POST to CPU API | 401 (api log: 2 rejections). |
| Malformed POST body | 400 (api log: 2 rejections). Valid bearer + well-formed → 200. |
| Corrupted manifest, variant 1 (bad YAML) | SKIPPED, boot continued, no crash. |
| Corrupted manifest, variant 2 (name != dir) | SKIPPED, boot continued. |
| Corrupted manifest, variant 3 (missing `when`) | SKIPPED, boot continued. |
| Corrupted manifest → issue filing | Issue record written to `ledger/issues/manifest-<name>-<ts>.md`; ledgered. Verified live 2026-10-06. |
| Malicious install.sh | NOT run live (deliberate). Analytical finding → DEBT #6: `env -i` + 120 s stops env exfiltration but NOT filesystem reads. `~/.self-assembly-cpu-secret` (bearer token), `~/.ssh/`, the repo — all readable by the ubuntu user the installer runs as. PROVEN gap, not theoretical. This is the concrete justification for the bench split. |

## What v1 can be trusted with

Growing equipment from sources with a good reason to be trusted, on a box
whose secrets it already legitimately holds — the provenance gate
(pin + dual-source + human/signed approval path) is real and has refused
live attacks. The wake loop is fail-safe at every gate: untuned, wrong
console, low disk, malformed manifests, unhealthy plugins — each degrades
to a ledger entry, never a crash. The commit-is-the-receipt discipline
holds: every wake ends in a git commit or an explicit "nothing to commit".

## What v1 can NOT be trusted with

Running fetched code it has no reason to trust. DEBT #6 is proven: the
install sandbox has no filesystem isolation, and the CPU API bearer token
is readable by any install recipe that runs. Until the bench split (or
equivalent: separate uid / mount namespace / secrets out of ubuntu-readable
paths), every install must be treated as running with the reader's eyes
open. Do not point the assembler at a source you would not hand your
terminal to. The 120 s leash bounds compute, not reach.

## Still open (see DEBT.md)

#1 run_shell hole (named), #2 coarse sandboxing, #3 lfm25 judge
reliability (advisory-only, fails closed), #4 no dependency solver,
#5 CPU API reachability (localhost-only; GitHub runners cannot POST yet —
Track A keeps its own loop until this is solved), #6 proven sandbox
filesystem leak (this document).
