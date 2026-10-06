# Self-Assembly Architecture — Three-Version Line-up + Synthesis

2026-10-06. Four lanes dispatched; three returned (GLM/ZAI still 429, DeepSeek closed — no paid seat).
Full verbatims: `claude-opus-mechanics.md`, `kimi-refined.md`, `minimax-pragmatic.md`.

## Unanimous agreements (the settled core)

1. **No registry/index file.** Directory listing IS the registry. All three independently.
2. **The assembler/grower is fixed and human-owned, never grown.** Only equipment is grown.
3. **Provenance before execution:** pinned hashes (commit SHA, not tags), verification before anything runs.
4. **Binaries never in git.** Pin + reinstall every wake. Git is for state and knowledge, not blobs.
5. **Inner judges grown bottom-up from build feedback**, never designed top-down. All three.
6. **Failures stay in git.** Rejected proposals, scar tissue, test misses — knowing what didn't work is intelligence.
7. **First plugin hand-built by a human, then deleted and re-grown** as the proof ritual.

## The fights

### 1. Isolation strictness (the big one)
- **Claude (strictest):** two-workflow split. Fetched code NEVER runs in a job that can mint a vault token or push. Operators get hardware, never tools/network/secrets. New `bench.yml` installed once by a human.
- **Kimi (middle):** scratch sandbox + per-plugin scoped OIDC token (audience = plugin name, TTL 120s). Admits the scoped token is new infra.
- **MiniMax (loosest):** "coarse sandboxing (provenance + review instead of isolation)" — explicitly labeled conscious debt.

### 2. Grants
- **Claude:** none exist. Hardware only.
- **Kimi:** capability grant list, enforced by the fixed core (not self-enforced).
- **MiniMax:** allowlist, Casey-edited.

### 3. Auto-install vs human approval
- **MiniMax:** no auto-install in v1 — agent proposes via `needs/`, Casey approves via issue comment.
- **Kimi:** agent-driven 8-step loop, bounded (max iterations, max concurrent proposals).
- **Claude:** growth rule opens a `grow:` issue and blocks the task on it.

### 4. The `run_shell` hole
- **Claude** names it as the top residual risk: run_shell still executes arbitrary code next to the vault token; the growth rule only discourages it at prompt level. Real fix = cut its network or move it to bench.
- Others don't go this far. This belongs on the debt ledger by name.

## Cleverest single mechanisms

- **Kimi's dual-source verification:** a hash counts only if it appears at two independent URLs the assembler fetched itself (or a signed task / human comment). Solves the bootstrap pinning problem — the agent can't invent a hash — with zero new infrastructure, reusing the signed task queue.
- **Claude's "probes rerun on every use":** deletes three mechanisms at once — no updater (an update is an edited pin), no repair path (a failed use re-enters the build loop), no hardware table (a changed body fails probes and triggers repair). Best minimum-moving-parts move in the round.
- **MiniMax's scar tissue:** JUDGE-NOTES.md → JUDGE.md — test misses folded into the judge spec before registration.
- **Kimi's resumable install:** the ephemeral body constrains only *uncommitted* work, not *long* work — commit progress markers, not artifacts.

## Recommended composite

- **Target:** Claude's two-job split (think = gunner with vault+push, never executes fetched code; bench = sandboxed executor, no secrets).
- **v1 stepping stone:** MiniMax's single-workflow + coarse sandboxing, explicitly labeled debt, with the run_shell network cut on the debt ledger by name.
- **Manifest:** Kimi's manifest.yaml (pin + sha256 + second_source) + Claude's one-line `when` trigger.
- **No index file** (unanimous). **Assembler human-owned** (unanimous).
- **Inner judges:** grown from failures tagged judgment-vs-mechanical (Kimi), one level max, advisory + logged override with `veto: inner` for destructive ops (Kimi), cases accumulate as replayable records (Claude), scar tissue folded in (MiniMax). Same idea in three dialects — take all three phrasings.
- **MVP ritual:** hand-build one operator → run it → delete it → watch the agent re-grow it from a proposal. Then first real target.

## Open decisions for Casey

1. **Bench split now or later?** Build the v1 single-workflow now with the bench split as the named next step, or go straight to the two-workflow split? (Recommendation: v1 now, split named — but the run_shell hole gets a name on the ledger today.)
2. **First operator target:** typst→PDF (Claude's pick: static binary, easy, proves the loop) vs ffmpeg-trim (Kimi's pick: annoying on purpose — big build, real probe surface; proves more).
