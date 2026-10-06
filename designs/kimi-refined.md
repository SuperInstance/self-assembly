# Kimi — Refined Design + Stress Test (verbatim, via kimi.ai 2026-10-06)

# Self-Assembling Equipment: Refined Design + Stress Test

I'm going to be adversarial about my own design as I go. The single most important decision, stated up front because everything hangs on it:

**The assembler is never grown.** Only equipment is grown. A fixed, hardcoded assembler module (part of the 10-tool core, living outside `plugins/`) does all fetching, verification, and registration. If the assembler can be modified by plugins, the trust boundary is circular and the whole thing collapses. Every failure mode below that touches trust reduces to: *can a plugin reach something outside `plugins/`?* If no, you're safe; if yes, nothing else matters.

## 1. Plugin Manifest Format

### Where things live

```
plugins/
  ffmpeg-trim/
    manifest.yaml
    driver.md            # prompt fragment
    probe.sh             # hardware/verify check
    test.sh              # acceptance test against real input
    cases/               # committed test fixtures (small, text/binary under 1MB)
    ledger/              # per-plugin run log (append-only)
```

No index file. No `plugins.yaml`, no registry JSON. The core walks `plugins/*/manifest.yaml` at wake. A single index file is a corruption target and a merge-conflict generator; a directory listing is neither. This is the first cut I'll defend aggressively.

### manifest.yaml

```yaml
name: ffmpeg-trim            # must equal directory name (verified)
version: 0.1.0
source:
  type: git                 # git | tarball | pypi | npm
  url: https://github.com/FFmpeg/FFmpeg
  pin: a1b2c3d...           # full commit SHA, not a tag — tags are mutable
  sha256: 9f86d0...         # of the artifact to be installed
verify:
  second_source: https://...  # independent URL confirming the same pin+hash
grants:                      # tools the plugin's driver may call
  - run_shell                # with the plugin's own sandbox profile
  - write_scratch
  - read_file:plugins/**
  - api_github:issues:write
install: ./install.sh        # runs from write_scratch dir, never repo root
health: ./probe.sh
accept: ./test.sh
inner_agents: []             # filled in during build, see §3
```

**Deliberately absent:** dependencies on other plugins, hooks/lifecycle events, config schemas, version ranges. Each of these is a moving part that earns nothing at this scale. Plugin conflict (§4 failure modes) is resolved by namespacing and fail-closed registration, not by a dependency graph.

### Why each field survives

- **pin + sha256:** non-negotiable per your provenance law.
- **second_source:** this is my answer to the *bootstrap pinning problem* — the agent shouldn't be able to invent a hash and install it. A hash counts as verified only if it appears at two independent URLs the assembler fetched itself (e.g., the project's release notes + a GitHub release asset checksum), or was approved in a signed task / human issue comment. A plugin proposal that can't produce two agreeing sources goes to a human via `create_issue`. Cheap, no new machinery — reuses the existing signed task queue.
- **grants as a list with no `write_file` on `plugins/../` escape and never `.github/`:** the manifest is a capability request the *fixed core* enforces, not something the plugin enforces on itself. The core's `run_shell` wrapper sets `GIT_DIR` nowhere, `HOME` to scratch, and `PATH` to a plugin-local bin. Defense in depth: even a malicious `install.sh` gets 120 seconds, no secrets except the scoped OIDC token, scratch disk only.
- **ledger/ per-plugin:** the agent's memory of "how did this equipment actually behave" lives beside the equipment, in git, per your ephemerality law.

## 2. Self-Assembly Loop Mechanics

### Sequence (concrete, in order)

Wake with a stated desire: "I need video editing." The agent doesn't have `ffmpeg-trim`. Here's the loop, mapped to the fixed core loop:

1. **Detect** — the planner (the LLM in the fixed loop) notices the task needs a capability not in the set of currently registered plugins. Detection is just prompting: the system prompt lists registered plugins; the model says "need: video trimmer." No capability registry to query — the manifest directory *is* the registry, listed in the prompt at load time. Ephemeral body means every wake rebuilds this list from git for free.
2. **Propose** — agent writes `plugins/ffmpeg-trim/proposal.yaml` (wanted capability, candidate sources found by `api_github`/web via vault) and commits. Nothing is installed yet. The proposal is visible in git history — the audit trail starts *before* anything runs.
3. **Pin & dual-verify** — assembler (fixed code) fetches both `source.url` at pin and `verify.second_source`, compares hash. Mismatch or no second source → open an issue, halt. This step runs with only the vault-scoped network token, no GitHub write yet.
4. **Isolated install** — assembler clones the pinned source into `write_scratch` (which lives *outside* the repo — scratch is ephemeral and never committed), builds/installs into a plugin-local prefix, records what was installed in `ledger/install.log`.
5. **Probe** — runs `probe.sh`, which must emit a small JSON report: arch, core count, GPU presence, and the installed tool's `--version` output. Probe output is committed to `ledger/probe.json`. The probe runs **twice** on different runners (ephemeral runners differ; a single probe lies easily — see failure modes).
6. **Build the driver** — the agent writes `driver.md` (prompt fragment: how to invoke, what inputs it takes, what failure smells like) and `test.sh` with real fixtures committed in `cases/`. This is where the build loop iterates: run test → read failure → revise driver → rerun. Bounded: max 5 iterations, then issue + halt (prevents infinite burn of a bad idea).
7. **Accept or reject** — `test.sh` exits 0 → assembler fills `manifest.yaml`, moves proposal to `plugins/ffmpeg-trim/manifest.yaml`, commits. Exit nonzero at iteration cap → `proposal.yaml` gets `status: rejected` + reason committed, scratch dies with the runner. Rejected proposals stay in git — they are intelligence too. *Accumulated specificity includes knowing what didn't work.*
8. **Use** — the planner now sees `ffmpeg-trim` in its plugin list and emits calls like `plugin:ffmpeg-trim.trim(input, start, end)`. The core translates that to `run_shell` with the plugin's sandbox profile + appends to `ledger/`. The tool never becomes a new hardcoded tool; plugins are always realized through the fixed 10.

### What code runs where

| Component | Lives in | Fixed or grown |
|---|---|---|
| Assembler (verify, install, register, enforce grants) | repo root `assembler/` | Fixed. Committed by humans, PR-reviewed. |
| Proposal/probe/test/driver per plugin | `plugins/<name>/` | Grown by agent |
| Installed binaries | scratch only, never committed | Ephemeral — reinstalled at need |

The last row matters: **binaries do not go in git.** Git-native memory is for *state and knowledge*, not blobs. On any wake that needs a plugin, the assembler re-runs steps 3–4 (verify + install) if `scratch/<name>` is absent — typically every wake, since scratch dies. Verify is cheap (network + hash); builds are cached by the source pin in a scratch dir keyed by sha256. Nothing persists but the pin.

## 3. Inner Agent Pattern

### Where inner agents come from — build feedback, not design

During step 6's test iterations, the agent tags *why* each failure needed judgment. Concretely, `test.sh` failures get classified in `driver.md`'s revision log with one of two labels:

- **mechanical** — wrong flag, wrong path, timeout → fix the driver, no inner agent.
- **judgment** — "output quality acceptable?", "which of these 4 candidate parameters?", "is this diff a regression?" → a decision point that resisted mechanical fixing across ≥2 iterations.

A decision point marked *judgment* twice becomes a `decision_point` entry in the manifest:

```yaml
inner_agents:
  - id: quality-judge
    triggered_when: "trim output duration mismatch OR user says 'looks wrong'"
    grants: [read_file:plugins/ffmpeg-trim/**, write_scratch, run_shell]  # narrower than parent
    context: plugins/ffmpeg-trim/driver.md + ledger of past judgments
    verdict_format: {pass: bool, reason: str, confidence: 0-1}
```

The inner agent is the same ReAct loop as the outer, spawned via a fixed tool — I'll call it `spawn_judge` realized as: the core writes a temp prompt file and calls the vault LLM directly with (driver.md + decision-point context + current artifact), not by giving it a full runner. Narrower, better-shaped: it gets the plugin's memory, not the agent's; the plugin's tools, not the ten.

### Invocation at runtime

Parent hits the trigger condition → core assembles the judge prompt → judge returns structured verdict JSON → parent's planner sees `{pass, reason, confidence}` and proceeds. The whole exchange is committed to `ledger/ffmpeg-trim/judgments.jsonl` (append-only). Cost: one LLM call. If the judge call fails/times out, the operation fails closed (halts, comments, asks human).

**Default power: advisory.** The parent may override a judge verdict, but the override is committed with a stated reason to the ledger — the ledger is where *taste accumulates* (your "intelligence = accumulated specificity"). A judge that's overridden often is a signal at the next build iteration: either tighten its context or grow a second judge and let them volley (cheap calls in formation) before the parent decides — but only where the manifest marks the decision point as `formation: true`. Match grain to target: one cannon (full planner) for ambiguity, volley (2–3 judges) only where testing proved single judges unreliable.

### Failure modes for inner agents

- **Inner disagrees with outer:** default advisory + logged override. If a decision point is safety-relevant (deletes, force-push, external messages), the manifest must mark it `veto: inner` — inner can block, only human (issue comment) can unblock. The override asymmetry is deliberate: agents can overrule judges on taste, never on vetoed operations.
- **Inner agent drift / hallucinated verdict:** verdict requires `reason` citing a file path or probe number; the core spot-checks that citation exists (one `read_file`). Verdicts without checkable citations are discarded. Confidence < 0.5 → escalate to human comment, don't guess.
- **Judge poisoning via ledger:** judgments are append-only and the judge only reads `ledger/` of its own plugin — a compromised plugin can teach its judge bad taste, but the blast radius is one plugin. Cross-plugin ledgers are read-only to other plugins. Confined wanting.
- **Recursion:** inner agents cannot spawn. Hardcoded in `spawn_judge`. One level. ReAct all the way down is aspirational; in an ephemeral body, deep recursion is a stack overflow you commit to git. Cut it.

## 4. Minimum Viable First Build

Grow `ffmpeg-trim`. One capability, end to end.

Scope it brutally: trim a video between timestamps. That's it. No filters, no concat, no codec wizardry.

1. Agent receives (or heartbeats into) a task: "trim the intro off `cases/input.mp4`."
2. Detects no video capability → proposal → pins FFmpeg at a release commit → dual-source hash check (project site + GitHub release checksums — FFmpeg conveniently publishes both).
3. Assembles in scratch (~90s build on a runner, inside the 120s shell budget? — **No.** This is the first real stress test: FFmpeg builds exceed 120s. Solution: the install runs across multiple wakes — the fixed core loop already supports this because state is in git. `install.sh` is resumable: checks for `scratch/build-done` marker, resumes if absent. The ephemeral body wasn't a constraint on *long* work, only on *uncommitted* work. Commit progress markers, not artifacts.)
4. Probe twice on two runners → `probe.json`.
5. Build `driver.md` + `test.sh` with committed `cases/input.mp4` (1MB cap — enough for a trim test).
6. Iterate test failures; one judgment point appears ("is the cut frame-accurate enough?") → grow `quality-judge` inner agent from exactly that log.
7. Register, use it on the real task, commit the judgment ledger.

**Success criterion:** from "I need video editing" to a registered, tested plugin with one grown judge — all steps visible in git history, nothing surviving except committed files. If the loop works for one capability, it's the loop for all capabilities. FFmpeg is the right first target precisely because it's annoying: big build, real probe surface, easy verification. A toy plugin would prove nothing.

## 5. Deliberately Left Out

- **Plugin marketplace / remote registry.** Pins come from the agent's own research + dual-source verification + human escalation. A registry is a trust concentration you'd have to secure, and your agent's whole epistemology is "verify, don't trust."
- **Binary artifacts in git, or a release/cache store.** Pin + reinstall beats blob storage. Git history stays text and small; repo stays cloneable by the fork-replication pathway.
- **Inter-plugin dependencies and a resolver.** Two plugins that need each other are one plugin that wasn't shaped right. Conflicts get resolved at registration, in the open, by a human comment — slow, but conflicts should be rare and loud, not managed by machinery.
- **Dynamic loading of plugin code into the core loop.** Plugins are never imported; they're always invoked through `run_shell` behind the grant list. Code you import can do anything code can do; code you exec in a sandbox with a 120s leash and scoped token can only do what the sandbox allows.
- **Self-modifying assembler.** Stated up front; repeated because it's the cut that protects all others.
- **The shell wardrobe.** Per your brief — separate project. If the assembler ever grows into it, that's a rewrite, not an extension.
- **Uninstall automation.** Deleting a plugin is a human PR. An agent that can grow equipment should not also be able to erase the record of having grown it.

## Failure-Mode Summary

| Scenario | Defense | Residual risk |
|---|---|---|
| Fetched software is malicious | Pinned commit + dual-source hash + scratch sandbox + scoped token + no `.github/` write + 120s leash. Malicious `install.sh` can burn 120s and scratch disk. That's the whole budget. | Supply chain inside the build (FFmpeg fetches its own deps) — mitigate by vendoring deps into the pinned source or recording their hashes in `ledger/install.log` and failing on drift. |
| Hardware probe lies | Probe twice on different runners; probe output includes actual measured throughput (2s CPU burn, timed 1MB memcpy), not just `nproc` claims. Manifest declares requirements; registration fails if two probes disagree. | A fleet-wide runner misconfiguration would lie consistently — accept; wrong perf assumptions degrade quality, they don't breach trust. |
| Inner agent disagrees with outer | Advisory by default + logged override; `veto: inner` only for marked destructive ops; citations required in verdicts; confidence floor escalates to human. | Override log could become rubber-stamp — surfaced at build iterations; a judge overridden >3× without justification triggers a review issue automatically. |
| Two plugins conflict | Namespaced tools (`ffmpeg-trim.trim`), no shared writable state outside ledger append, duplicate names rejected fail-closed at registration, alphabetical load order for reads. A conflict blocks registration and files an issue; nothing silently wins. | Name squatting inside `plugins/` prevented by manifest name == directory name, directory creation through proposal commit path. |
| Manifest corrupted | No index file; each manifest validated against schema at wake; malformed manifest = plugin skipped + issue filed + git history pinpoints breaking commit (recoverable by checkout, attributable by blame). | |
| Proposal spam / burn loop | Max 3 concurrent proposals; dual-source check before install; assembly iterations per wake capped (8); desire stays cheap, assembly stays expensive. | |
| Vault token exfiltrated by plugin | OIDC token scoped per-plugin at spawn time (audience = plugin name, TTL = 120s). A plugin holding its own token can't impersonate the agent to GitHub. New infrastructure — earns its place as the difference between "plugin compromised" and "agent compromised." | |

### The one-sentence core

Grow equipment in a sandbox the fixed assembler verifies and registers; grow judges only where testing proves judgment is missing; let git history — proposals, probes, verdicts, rejections — be the accumulated specificity; and keep the assembler human-owned so the agent can want anything but can only touch what was earned through a checked, logged, reversible door.

### Suggested next stress test

Attack the dual-source verification with a typosquatted second URL in a proposal and see if the proposal path files an issue or installs. That's the seam where everything else holds or breaks.
