# Self-Assembling Plugins — the pragmatic builder's version
*MiniMax lane. Lens: what would I actually build first. Minimum moving parts.*

## 0. The one idea

The agent already reboots every 15 minutes and reconstitutes itself from git. That ephemerality is not a limitation to work around — it **deletes half the design space**. No hot-reload (next wake picks it up). No plugin daemon. No upgrade protocol (reinstall = new commit). No uninstaller (`git revert`). The plugin system is a directory, a YAML file, and ~60 lines of loader. Everything else is ceremony we don't need.

## 1. Plugin manifest format

One registry, one directory per plugin. That's it.

```
plugins/
  registry.yaml          # the genome: which equipment is installed
  ffmpeg-operator/
    OPERATE.md           # driver: what it does, how to invoke it, flags that matter
    operate.py           # the actual operator script
    JUDGE.md             # inner-judge prompt (narrow, typed)
    TESTS.md             # 3–5 concrete assertions; must pass before registration
    probe.json           # hardware facts baked at build time
    source.json          # provenance record: what was fetched, pinned hash
```

`registry.yaml` — the whole schema:

```yaml
# plugins/registry.yaml
# Edited by the agent (via PR/commit) or by Casey. Loaded at agent boot.
# v1: no versions, no dependencies, no upgrades. Reinstall = replace the directory.

allowlisted_sources:           # the trust root. Casey edits this, not the agent.
  - "https://github.com/*"     # glob match on fetch URL
  - "https://johnvansickle.com/*"

plugins:
  - name: ffmpeg-operator
    purpose: "transcode / cut / thumbnail video with ffmpeg"
    triggers:                  # when the agent should consider wearing this shell
      - "task mentions video"
      - "file *.mp4 in workspace"
    operator: "plugins/ffmpeg-operator/operate.py"
    judge_prompt: "plugins/ffmpeg-operator/JUDGE.md"
    grants:                    # extends check_permission() in agent.py. Deny-by-default.
      - "shell:ffmpeg"
      - "write:scratch"
      - "net:judge"            # may call the brain at decision points
    hardware_required:         # checked against probe.json at load; skip if mismatch
      arch: "x86_64"
      min_cores: 2
```

`source.json` — the provenance receipt, written at fetch time, never hand-edited:

```json
{
  "fetched_at": "2026-10-06T01:40:00Z",
  "kind": "static-tarball",
  "url": "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz",
  "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "verified_by": "sha256sum match at install",
  "installed_via": "plugins/ffmpeg-operator/install.sh"
}
```

Loader (in `agent.py`, ~60 lines): parse `registry.yaml` → for each plugin, check `probe.json` against `hardware_required` → append `OPERATE.md` contents to the system prompt under `## Equipment` → extend the permission table with `grants`. If the registry is malformed, boot with zero plugins and log it. **A broken manifest must never break the boot.**

## 2. Self-assembly loop mechanics

The agent does NOT auto-install in v1. The loop is **propose → approve → build → register**, and the human gate is a feature, not a placeholder.

### Step 0 — Need detection (in the think loop)
The agent's think output may include a `needs:` block:
```json
{"needs": {"equipment": "video-transcode", "why": "task requires cutting mp4",
           "proposed_source": "https://johnvansickle.com/ffmpeg/releases/...tar.xz"}}
```
The harness writes this to `needs/<name>.md` and stops. It does not fetch. Two paths forward:
- **Fast path:** source matches `allowlisted_sources` AND the operation is read-only (probe/transcode/summarize — declared in the proposal). The agent may proceed on the next wake without asking.
- **Slow path:** anything else → opens an issue (`create_issue`) titled `Equipment request: <name>` with the proposal. Casey approves by commenting `approved`. The next think wake sees the approval and proceeds.

### Step 1 — Fetch + provenance (one wake, `run_shell`, 120s budget)
```
1. curl -sSL <url> -o /tmp/equip.tar.xz            # allowlist checked BEFORE curl
2. sha256sum /tmp/equip.tar.xz  →  compare to published hash
3. MISMATCH → abort, write needs/<name>.md status: rejected-hash, open issue. Never proceed.
4. MATCH → extract to plugins/<name>/vendor/ ; write source.json
```
Split across wakes if the download exceeds the shell timeout: the state file `needs/<name>.md` records `status: fetching` so the next wake resumes instead of restarting.

### Step 2 — Hardware probe (same wake or next)
Five commands, baked to `probe.json`. No frameworks:
```
uname -m ; nproc ; ffmpeg -version | head -1 ; ls /dev/dri 2>/dev/null ; df -h /tmp | tail -1
```
The driver reads `probe.json` at runtime (e.g., picks thread count from cores). If `hardware_required` in the registry isn't met at a later boot, the plugin is skipped silently — the agent degrades, it doesn't crash.

### Step 3 — Operator crafting (the real work)
The agent writes `operate.py`, `OPERATE.md`, `JUDGE.md`, and `TESTS.md`, then **runs the tests**. The tests are the product, not the driver:
```md
# TESTS.md — must all pass before registration
1. operate.py --probe → exits 0, prints valid probe.json summary
2. operate.py transcode fixture.mp4 --to 720p → output exists, duration within 5% of input
3. operate.py thumbnail fixture.mp4 --at 3s → jpg exists, non-zero size
4. judge dry-run: JUDGE.md + sample context → returns valid {"decision": ...} JSON
```
Fail → iterate the driver (max 3 rounds per wake, state in `needs/<name>.md`) → still failing → open issue with the log, park it. **An operator that can't pass its own tests never registers.** This is the quality gate the whole system rests on.

### Step 4 — Registration (one commit)
```
1. Write the registry.yaml entry (append to plugins: list)
2. git add plugins/ needs/<name>.md
3. git commit -m "equipment: <name> (probed <arch>/<cores>c, tests 4/4)"
4. needs/<name>.md → status: registered ; move on
```
Next wake, the loader picks it up. The crab wakes with new equipment. Rollback is `git revert`.

### What breaks in practice (and the defense)
- **apt/pip on the runner is slow and flaky** → prefer static tarballs with published hashes (the ffmpeg example). One file, one hash, no solver.
- **120s shell timeout kills long installs** → the `needs/<name>.md` state file makes every step resumable. Idempotent steps or it doesn't ship.
- **LLM-written drivers are wrong in boring ways** → TESTS.md is the gate, not vibes. If the tests are weak, the operator is weak; review the tests, not the driver.
- **Judge calls add latency to long runs** → batch judgments (see §3), never one call per frame.

## 3. Inner agent pattern

No nested ReAct. No new infrastructure. The operator is a script; at decision points it asks the brain **one typed question** and moves on.

`plugins/ffmpeg-operator/JUDGE.md` (narrow, written from build feedback — §3.1):

```md
# Judge: ffmpeg-operator
You are the runtime judge for a video transcode pipeline. Answer ONLY with JSON:
{"decision": "<one of the allowed values>", "reason": "<12 words max>"}
Allowed decisions depend on the question asked. Never explain outside the JSON.
Context you receive: segment id, duration, a 1-line content summary, what the
pipeline did last. You do NOT see the video. Be conservative: when unsure, KEEP.
```

Decision point in `operate.py` (the whole pattern):

```python
def judge(question, context, allowed, default, timeout=15):
    """One typed question to the brain. Always returns a valid decision."""
    prompt = open("plugins/ffmpeg-operator/JUDGE.md").read()
    body = {"system": prompt,
            "user": json.dumps({"question": question, "allowed": allowed,
                                "context": context})}
    try:
        r = vault_llm(body, timeout=timeout)          # same vault_call as the agent
        d = json.loads(extract_json(r))["decision"]   # strict parse
        return d if d in allowed else default
    except Exception:
        return default                                # brain failed → safe default

# at a decision point:
if judge("cut boring segment?", {"seg": 12, "dur": 8.2, "summary": "static slide, no speech",
                                 "last": "kept seg 11"},
         allowed=["cut", "keep"], default="keep") == "cut":
    cut_segment(12)
```

Rules that make it safe:
- **JSON-only, strict parse.** Keyword-matching the reply ("boring" in text) is fragile — cut it. If the JSON doesn't parse or the decision isn't in `allowed`, it's the default. No exceptions, no retries beyond one.
- **Safe defaults are declared per decision point, and they differ by type.** Destructive decisions (cut, delete, overwrite) default to the conservative action (`keep`). Liveness decisions (corrupt frame: skip or abort?) default to `abort` — fail safe, fail loud, the pipeline stops and the log says why.
- **Batch, don't stream.** Collect candidate segments, judge them in groups of ~10 per call where the decisions are independent. One call per frame is how you burn the budget and learn nothing.
- **Every judgment is logged** to `scratch/judge-<run>.jsonl`: question, context, decision, latency. That's the feedback corpus.

### 3.1 How build feedback shapes the judge
During Step 3 testing, the agent runs the judge in dry-run mode against fixtures and records misses (it said `cut` on the segment with the punchline). Each miss gets appended to a `JUDGE-NOTES.md` in the plugin dir, and before registration the agent folds the notes into `JUDGE.md` ("Be conservative: when unsure, KEEP" was born from exactly such a miss). The inner agent is never designed — it's **grown from the scar tissue of testing**. The notes file stays in git as the provenance of the prompt.

## 4. Minimum viable first build (this week)

**Day 1–2 — the loader.** `plugins/registry.yaml` + ~60 lines in `agent.py`: parse, hardware-check, inject `OPERATE.md` fragments into the system prompt, extend `check_permission` with `grants`. Malformed registry → boot with zero plugins. Test: hand-written registry with a fake plugin, agent lists it in its boot log.

**Day 3 — one plugin, built by hand.** The ffmpeg operator, exactly as specified above: real static tarball, real `probe.json`, real `TESTS.md` with 4 tests, real `JUDGE.md`. *We* build it, not the agent — compilers all the way down; the first one is hand-written. Prove the format works before the agent ever touches it.

**Day 4 — the proposal path.** `needs/` handling in the think loop: parse `needs:` blocks from think output, write `needs/<name>.md`, fast-path/slow-path routing, issue creation for approvals. No fetching yet.

**Day 5 — the build path.** Fetch → provenance → probe → craft → test → register, executed across wakes via the `needs/<name>.md` state file. Then delete the hand-built ffmpeg plugin from git and have the agent **re-grow it from a `needs:` proposal**. If the regrown operator passes its own tests, the loop is real.

Total new code: ~200 lines (loader 60, needs-handling 60, build steps 80). Everything else is files in git.

## 5. What I'd LEAVE OUT and why

- **Dependency resolution.** One level only: the plugin declares system packages or a tarball URL. No transitive solver. *Why:* the solver is a project by itself; static tarballs make it unnecessary for v1.
- **Version upgrades.** Reinstall = replace the directory in a new commit. *Why:* with 1–5 plugins, "upgrade" is a 3-line operation. A protocol for it is premature.
- **Sandboxing beyond the runner.** The runner IS the sandbox; `grants` are enforced in `check_permission()`. *Why:* real sandboxing (containers, seccomp) is a second system. The trust boundary that matters — never touch workflows, vault-held creds — already exists.
- **Plugin marketplace / discovery.** Plugins are git directories; "install" is merging a PR. *Why:* distribution without curation is a malware vector; curation is a human job we're not staffed for.
- **Inter-plugin APIs.** Plugins never talk to each other; they talk to the agent. *Why:* every plugin-to-plugin interface is a compatibility promise. The agent is the bus.
- **Hot-reloading.** *Why:* the agent dies every 15 minutes anyway. The next wake is the reload.
- **Auto-rollback.** `git revert`, by human or by the agent in a later wake. *Why:* rollback automation needs health signals we don't have; the git log is the signal.
- **Auto-install without approval.** The fast path (allowlisted + read-only) is as far as v1 goes. *Why:* an agent that fetches and executes arbitrary code on its own is a supply-chain attack with extra steps. The human gate is load-bearing.
- **Telemetry beyond git.** The commit log, the judge jsonl files, the `needs/` state files — that IS the telemetry. *Why:* a metrics pipeline is a product; `git log --oneline -- plugins/` answers "what changed and when" today.

### The 3 cuts most likely to hurt later (debt I'm taking on purpose)
1. **No dependency resolution** — at ~10 plugins, manual management gets silly. The fix later is a lockfile, not a solver.
2. **No inter-plugin APIs** — the day two plugins genuinely need to compose (transcribe *then* cut), we'll hand-roll the composition in the agent prompt. That's fine twice; the third time we design the interface.
3. **Coarse sandboxing** — a malicious or buggy plugin runs with the runner's full user privileges. The mitigation is provenance (allowlist + hashes) and review, not isolation. If we ever run untrusted plugins, this becomes the first thing to fix.
