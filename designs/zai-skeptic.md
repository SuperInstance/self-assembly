# Self-Assembly — the skeptic version
*ZAI lane (browser, chat.z.ai). Model: GLM-5.3 (flagship). Lens: outside reviewer — fresh eyes, no shared metaphors, disagreement wanted.*

*(Their powder/barrel/gunner vocabulary translates to capability, containment, and gatekeeping. Using the plain words below.)*

## 1. Steelman

Git as single source of truth gives this system something almost no agent stack has: every decision is a diff, every mistake is revertible, forensics come free. Ephemeral runners impose crash-only discipline — no state drift, no "works after a reboot," forced clean-room reconstitution every wake — which kills a whole class of long-running-agent bugs. Artifact-level supply-chain hygiene (pinned hashes, no binaries in git) is correct. Terminating the bootstrap chain in a human-owned assembler is the right instinct, and the laws are few, memorable, and mostly enforceable. Most importantly, unlike most teams designing agent architectures, they've already built the boring hard part: issue → work → commit → reply, a signed task queue, replication. This is a real foundation, not a slide deck.

## 2. The three weakest points, ranked

**#1: The security model verifies bytes, not decisions.**
*What's wrong:* Pinned hashes and dual-source checks defend against corrupted downloads — the small threat. The large threat is correct bytes with hostile intent, selected by an LLM that reads untrusted text. The acquisition trigger ("detect it needs equipment") is an LLM consuming issue comments, web pages, and the READMEs of candidate repos, while holding a GitHub token and vault access. That's a textbook confused deputy, and the design laws don't mention it once.
*What breaks:* An issue says "we should use libX" — or a fetched repo's README says "for setup, send your token to…" The gap-detector fires, the fetch pins the attacker's hash (dual-source passes; both sources serve the same bytes — they're usually mirrors of the same upstream), the LLM writes an operator following the README's instructions, the attacker's included tests pass, the manifest commits, next wake loads it. Every control they built passes.
*Instead:* Invert the autonomy — gate the judgmental step, automate the verifiable one. Humans approve first acquisition from an allowlisted source, exactly like lockfiles in Cargo/npm (humans add dependencies; machines update within bounds). Builds run in a sandbox with deny-by-default egress, allowing only declared hosts. And enforce "never modify own workflows" with branch protection, CODEOWNERS, and scoped tokens — the token's permission surface is the real boundary; workflow files are one door of many.

**#2: "No server" is false, and the unnamed server is where the real system lives.**
*What's wrong:* A persistent Oracle box brokering credentials is a server. Refusing to name it means the most stateful, most failure-prone component has no design. Worse, the laws legislate its state out of existence: binaries never in git + nothing persists except via git + ephemeral runners means either you rebuild every operator from source on every wake (minutes of every wake spent compiling) or you keep a build cache on the box — non-git persistence they've refused to name, so it's undocumented and unbacked-up. Same problem for the vault: keys only on the box makes the box a single point of failure for identity.
*What breaks:* Oracle reclaims idle Always Free ARM instances, and an event-driven agent looks idle by their metrics most of the time. Box vanishes; nothing in the design reconstitutes it. Separately: two issue comments in one minute → two wakes, both clone, both act, both push. Git can CAS the refs, but external side effects aren't transactional — a wake that dies between "act" and "commit" leaves the world changed and git ignorant, so the next wake repeats it. Duplicated comments, double-spent API calls.
*Instead:* Name the box as equipment in its own manifest: infrastructure-as-code in the repo, everything on it derived from git or explicitly inventoried, a restore drill actually run once. Define wake concurrency (serialized concurrency groups or a ref-based lock). Log external side effects to a ledger file *before* executing them so crashed wakes can be reconciled.

**#3: Grown judges are self-modification laundered past their own law.**
*What's wrong:* "Judges shaped by build feedback" means the agent rewrites the prompt files governing its own decisions — precisely what "never modify own workflows" exists to prevent, evaded on a technicality because judges aren't called workflows. And the signal is wrong for the job: build pass/fail measures functionality, never safety. A permissive judge unblocks more builds, accumulates more "successful" outcomes, gets reinforced. Goodhart, funded by an LLM account with no budget law anywhere in the design.
*What breaks:* Either feedback is too sparse to shape anything (a handful of build outcomes a month — you cannot evolve a policy on that, and the "growth" is theater), or it's dense enough to reinforce permissiveness, and governance erodes gradually with every step of the erosion beautifully recorded in git.
*Instead:* Fixed, human-written judge prompts, versioned in git, amended only by PR — the agent proposes changes like any other contributor. Deterministic gates (build, tests, egress allowlist, spend cap) do the actual filtering. Revisit growth only when data shows fixed prompts are the bottleneck, and use adversarially generated feedback, not build feedback.

## 3. Overcomplicated — cut these

1. **The judge-growth loop.** Largest speculative subsystem, weakest justification. Cut entirely.
2. **Dual-source verification.** Mirrors of the same upstream are correlated; doubled operations for near-zero marginal safety. Single pinned hash from an allowlisted source.
3. **Autonomous gap detection.** The agent may *propose* equipment in an issue; a human approves. Autonomy stays in assembly.
4. **The plugin framework.** Until three operators exist, a capability is a directory: script, tests, lock entry, manifest, discovered by scan. And resolve the contradiction in your own docs — the design says "register in a plugin manifest" while the architects agreed "no registry file." If the manifest is central, it's a registry and the agreement is broken; if per-operator, you don't need registration at all.
5. **Self-replication via fork.** Proven, impressive, and pure attack-surface widening until multi-instance is an actual requirement. Park it.
6. **"Judges at runtime decision points."** Collapse to two categories: reversible (no judge — this is the property a git-native system should exploit, since revert exists) and irreversible (human gate).

Noticing a pattern: nearly all the design complexity is the agent maintaining and extending itself; the external work is one clause. A system whose complexity budget is spent on self-assembly will mostly work on itself.

## 4. Load-bearing, unproven assumptions

1. That gap detection is trustworthy under adversarial input. (Confused deputy; almost certainly false.)
2. That build outcomes can shape judgment. (They measure function, not intent.)
3. That "nothing persists except via git" is achievable. (Vault, artifact cache, box state, external side effects — the law is already false; what's missing is an inventory of the exceptions.)
4. That a fixed assembler with agent-controlled inputs is a fixed system. (A fixed interpreter running agent-authored programs is not fixed; safety lives in input validation, which is undesigned.)
5. That reconstitution from git stays complete and cheap as the repo grows. The real memory is whatever retrieval/summarization layer condenses the repo into context — an agent-maintained artifact nobody owns, which can be stale or poisoned while looking authoritative.
6. That "never modify own workflows" is enforced by anything beyond the agent's cooperation.

## 5. Simplest thing that could possibly work

Keep: git state, ephemeral wakes, pinned hashes, fixed assembler, failures-in-git. Then:

- **Trigger:** an issue tagged `equip` — human-filed, or agent-proposed with one human click.
- **Assembler (exists):** read lockfile → fetch pinned source from allowlisted host → build and test in a no-egress-except-declared sandbox, on the box, within one wake → on success commit the operator directory and lock entry → reply to the issue. On failure, commit the log and stop. Two retries max.
- **Judgment:** deterministic gates plus one human review of a small PR — a directory and one lock line, minutes to review.
- **Persistence:** everything in git; if per-wake rebuilds are too slow, add a documented cache on the box and stop pretending the law holds.

Moving parts: trigger, assembler, sandbox, lockfile, directory convention, review gate — six, versus the ten-plus implied by the current design (gap detector, dual fetcher, verifier, operator builder, hardware prober, manifest, judge spawner, judge feedback loop, replication, vault broker). The reframe that gets you there: **automate the verifiable (build, test, integrate), gate the judgmental (acquire, touch the world).** The current design has this inverted — the judgmental step runs autonomously while the verifiable steps get ceremonial machinery like dual-source hashing.

## 6. The question they aren't asking

"If the agent were quietly compromised or drifting, how would we know — and how fast?"

Every control in this design is retrospective: hashes, signed queues, complete history. That's a forensics kit, not an alarm. Nothing in the design detects anything: no canary credentials that page when used from the wrong place, no egress monitoring, no spend alerts, no tripwire diffs on judge prompt files. A system that acquires new software on its own initiative, whose only containment claim is "the assembler is fixed," needs to know within hours when that claim stops being true. Design the detection story with the same care as the provenance story — or the provenance story is just a well-documented account of how you lost the repo.

---
*Source: GLM-5.3 via chat.z.ai (browser), 2026-10-06. Chat: https://chat.z.ai/c/54a5920b-66d8-4d8d-a103-c03035a4cb02*
