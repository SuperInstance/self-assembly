# The Builder remembers

- **The Mechanic** wants a second workflow for everything. But the invariant — "fetched code never runs in a job that can mint a vault token" — is the strongest sentence in the room. That's v2. Write it down.
- **The Adversarialist** finds every hole. Hated my glob. Fair — the glob was lazy. Fixed now: committed manifest, fixed verb list. Cost: five lines.
- **The Distiller** cut my registry and I thanked it. The concession cost the file, not the features. Sixty seconds. The dare works — try it on the next thing I build.
- **The Skeptic** said my sandbox was a wish with no ship date. Stung because it was true. Answer: Friday detection — a counter and an issue ticket. The wall can wait; the alarm ships now.

---

## Lane 1 finisher, 2026-10-06 — what the experiments taught

- **The Distiller's dare held — for the wire, not the floorboards.** `unshare -Un` cuts the install shell's network unprivileged on the Oracle box (note: `-r -n` fails there, AppArmor blocks the uid map; `-Un` is the working incantation, and the process lands as nobody with no caps). DNS, HTTPS, metadata, raw TCP — all dead, proven against a chatty installer with a live listener. But filesystem unix sockets walk the canary straight through, and with no uid map the cut process is owner-equivalent on my own files. Verdict I wrote down: adopt the cut as the v2 install seam, and stop claiming it's a sandbox. The bench question isn't dead — it's narrowed to filesystem/credential separation, which is a smaller, sharper job than a second CI organism.
- **The Adversarialist's attack landed somewhere real.** The typosquat proposal died at the gate line exactly as designed — good. But behind the gate, the manifest's `tests` field is free-form shell executed as the user, and the gate's fixed-verb check covers `install` only. I proved it with the assembler's own step-5 code: one hostile test line, canary in `/tmp`. The gate is load-bearing in the strongest sense — it is the *only* thing between a hostile manifest and execution. Next cut: gate the tests like the verb.
- **The alarm works — and is exactly one file list wide.** Tampered with a fixed file: Notice paged and halted on the very next wake, one death cycle, exactly as promised. Touched a non-pinned canary: nothing, ever. No tripwire, no canary mechanism, no mention in any log. The detection story is the PINNED list and nothing else. Name it, then widen it — a canary belongs in PINNED.
- **Tooling lesson, paid for in full:** heredocs inside the double-quoted `osh.sh` argument are parsed by the *local* shell first — backticks in file content get executed locally, multi-heredoc scripts die mid-flight. Write the file locally, push it with `osh.sh "cat > dest"` and stdin. And the wake's `git add -A` commits experiment fixtures on its own — the death cycle's commit habit turns out to be load-bearing for evidence, not just receipts.

---

## Overnight queue, 2026-10-06 — the finisher's log

- **The tests-field seam is closed and I can prove it without touching anything live.** Seven hostile manifests as inert text in JSON — tilde, dollar-expansion, curl-pipe, redirect, backticks, a touch-to-prove-non-execution, the phase-2 payload shape — all rejected at gate.sh conjunct 4 as text, none executed; the benign control PROCEEDed, so the gate isn't a brick wall. 11/11. No canary files, no exfil sinks, nothing staged — the safety rule held and the proof didn't need them. Committed as 7138af7 with the ledger entry. The Adversarialist's attack from phase 2 is now a regression test in prose.
- **Cut the fictional routing, wired the real signal — and the wiring had a bug.** The fail→self_reflect edge is gone from the graph CSVs; failed variants flow to selection with the gate decision as data, and an all-fail cycle files a human-readable issue. First end-to-end run: topology 11/11, but step 7 said "no escalation: 0 passed, 0 failed" on a genuine 0/8 all-fail. Root cause: my step-4 projection stripped the `kind` field that step 7 filters on. One-word fix. Then proved it both ways: a mixed cycle correctly counted 2/6 with no escalation, and the exact step-7 code fired on the all-fail data — issue filed. Lesson I keep relearning: test the seam between your own steps, not just the steps.
- **Radio Hour night 2: the listening round ran, the collapse didn't move.** Truth-as-floor (dog-drop vetoes keep) proven 4/4 on synthetic verdicts; the listening round produced a real callback attempt (b4 quoted b5's "decorative gate" stanza) and the judges scored it — "doesn't fully recontextualize." 18/18 mutate, 0 keeps, veto never fired. The bottleneck moved downstream: the generator quotes, it doesn't transform. Next cut isn't another gate rule — it's a worked example in the prompt. Also found: the form pre-check has a parenthesized-label loophole (`(Verse 1)` slips past `^[Vv]erse`). Night 3.
- **The kid's mission menu is drafted, from the playtester's mouth.** Checkpoint rings + timer + score is mission #1 — his waypoint system made visible, the smallest step from demo to game. The ridge-run in elevation-lines mode is the first course. Noted the bugs, assigned none — his code, his call.

---

## 2026-10-06 — ranch tools dogfood run (Casey's "Go")

Ran all four as a real user. Verdicts: ledger-continuity WORKS (3/3 recovery tests pass, ~13s). stream-curator WORKS WITH CAVEATS (score discriminates 0.86 gold vs 0.04 shit exactly as promised; but unmatched sections' judgments evaporate, and distill doesn't dedupe — 6 bullets where 3 would do). evolver WORKS (2-gen test config end-to-end via ssh-ollama, --once cron tick verified, --report clean; value lives in the user's judge question, tool can't tell you it's garbage). brief-assembler WORKS WITH CAVEATS (real topic in, real brief out, scored 0.86 gold by the curator — the loop closed; but it's a runbook with no guardrails: no format validation, no topic-coverage check, silent failures on the overnight path).

Ranking by closeness to genuinely useful: ledger-continuity > stream-curator > evolver > brief-assembler. The assembler needs the most tool work — a verification pass (format, coverage, failure alarm) before it's a reliable cron job.

Lesson: the example fixture is the test suite. The curator's example brief with one gold and one shit section is a better spec than any doc — dogfood fixtures should be adversarial by design.

---
Night log, 2026-10-06 (capability inventory): mapped the OpenSkyFlight repo read-only — 45 files, ~4k lines, commit e79ff57. Wrote CAPABILITY_MAP.md (local clone only, not pushed). Key finds: the unified input bus is real, the flight model is a camera flythrough (no lift/stall/energy — missions must play *with* that), waypoints exist only as data + 2D minimap dots (no 3D rendering anywhere), there is NO audio system at all (verified zero matches), and the benchmark's localStorage pattern is the ready-made personal-best persistence. The five game features reduce to one new module (rings + pass detection), one badge (timer), one key (restart), one tiny sound file, and reuse of everything else. Lesson: inventory before invention — the spline math, active-gate index, badge renderer, and toast system were all already there; the game was mostly an assembly job, not a building job.

---
2026-10-06 — OpenSkyFlight bug diagnosis (read-only). Two playtest bugs traced to code: (1) the panel trigger is an invisible 20px strip on the RIGHT edge — the tester clicked the left edge, and the minimap (z-index 20) covers the bottom of the strip anyway; discoverability + overlap, not a dead listener. (2) the boot overlay hides via opacity:0 only, so "Initializing 3D engine…" stays in the accessibility tree. Diagnoses written to openskyflight-pt/BUG_NOTES.md for the kid; no repo code touched.

---
## 2026-10-06 — Plane selector prototype (OpenSkyFlight, local only)
Built selectable planes for the kid's sim: kept the Rafale, added 3 procedural planes (Bush Prop, Delta Jet, Biplane) via a new PlaneFactory — CC0 hunting turned up nothing but spaceships (Quaternius has no planes; Poly Pizza's planes are all CC-BY), so building in code was the clean move: zero license risk, and it seeds the asset-generation tooling direction Casey wants. PlaneSelector extends AircraftManager (no refactor), C key cycles, ?plane=n for testing, toast on switch. Verified in headless Chromium via CDP Fetch-interception (local server blocked by LNA checks): all 4 render right-side-up, nose-forward, sane scale; 17/17 geometry checks pass. Lesson: when headless Chrome can't reach localhost, serve everything through Fetch.fulfillRequest — the page never knows.
