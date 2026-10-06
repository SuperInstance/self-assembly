# Claude Opus — System Mechanics Version (verbatim, via claude.ai 2026-10-06)

This is a design for review, and nothing is built. I assumed GitHub-hosted Linux runners with Docker and took your brief as the full requirements.

### The invariant everything hangs on

**Fetched code never runs in a job that can mint a vault token or push to the repo.**

A hash pin proves the software is the same as what was tested, not that it is safe, so isolation has to do that work. That forces a second fixed workflow, `bench.yml`, which a human installs once.

The harness changes, all made once by a human:

- **`.github/workflows/bench.yml`**: its gate script is inline, because the platform rejects workflow-file pushes from the runner's token. By comparison, `write_file`'s deny rule is a courtesy.
- **Wake workflow**: add a `workflow_run` trigger on bench completion.
- **Core loop**: load each operator's `when` line at wake, add one tool (`ask_judge`), and add one fixed prompt paragraph (the growth rule).

### 1. Plugin manifest

There is no registry file. An operator is a directory, and being registered means existing under `equipment/`.

```
equipment/<name>/
  operator.json   lock + one-line trigger
  driver.sh       sole entrypoint: driver.sh <verb> [args]; reads $IN, writes $OUT/result.json
  USE.md          prompt fragment, read on demand
  probe/*.sh      executable checks that call the driver on real inputs; exit 0 = pass
  judges/         <arg>.md + <arg>.cases.jsonl, only if grown
  BUILD.jsonl     append-only build ledger
```

```json
{
  "when": "typeset a PDF from markup",
  "sources": [
    { "name": "typst", "arch": "x86_64",
      "fetch": "gh:<owner>/<repo>/releases/<tag>/<asset>",
      "sha256": "<64 hex>" }
  ]
}
```

| Piece | Remove it and… |
|---|---|
| `when` | The gunner forgets what it owns and regrows it, or every `USE.md` loads on every wake. |
| `fetch` + `sha256` | The body reconstitutes from whatever upstream serves that day. |
| `arch` | One operator cannot live on two bodies, so a fork on arm needs a separate operator. |
| Driver contract | `bench.yml` needs per-operator knowledge, which means the agent needs to edit a workflow. |
| `probe/` | "Verified" becomes a claim instead of a rerunnable fact. |
| `BUILD.jsonl` | A multi-wake build has no state, and judges have no evidence to be grown from. |

I cut four fields on purpose:

- **Name**: the directory is the name.
- **Version**: the pin is the version.
- **Verified flag**: an agent-written claim proves nothing.
- **Grants**: none exist. An operator is granted hardware, never tools, network or secrets.

### 2. Self-assembly loop

**Think job** (existing workflow, holds vault and push rights): the gunner. It downloads, hashes, edits, commits and dispatches, and never executes fetched code.

**Bench job** (`contents: read`, no `id-token`, no secrets):

```
inputs: path  ^(forge|equipment)/[a-z0-9-]+$
        sha, runner (choice list fixed in the file), verb, args
1 checkout @sha, persist-credentials: false
2 GATE     parse operator.json; fetch must match the gh: release grammar;
           download; sha256 -c; unpack to /op/<name>;
           write facts.json (arch, cores, mem, gpu)
3 SANDBOX  docker run --network none, base image pinned by digest;
           /op and operator dir read-only, $OUT writable;
           run probe/*.sh; if all pass and verb is set, run driver.sh <verb>
4 upload artifact: facts.json, probe results, stderr tails, $OUT
```

The sequence, as a multi-wake state machine with its state in git:

1. **W0, detect.** A task arrives and no `when` line covers it. The growth rule says not to improvise with `run_shell`, but to `create_issue "grow: <capability>"` and block the task on it. The task's own input becomes probe #1.
2. **W1, scout.** Pick a candidate and hash its release asset with `curl | sha256sum`, which downloads without executing. Write `forge/<name>/` with the lock, a one-verb driver and two probes, then commit and dispatch bench.
3. **W2…n, iterate.** Each wake is triggered by `workflow_run`. Pull the artifact as data, append `{round, sha, run_id, facts, failures, change, why}` to `BUILD.jsonl`, edit, commit and redispatch. After 8 rounds, comment on the grow issue and stop.
4. **Wn, promote.** When all probes are green, run the argument audit from section 3, then `git mv forge/<name> equipment/<name>`. That commit is the registration.
5. **Use.** Dispatch bench with a verb. Probes rerun first, every time.

Because probes rerun on every use, three mechanisms are unnecessary:

- **Updater**: an update is an edited pin.
- **Repair path**: a failed use re-enters step 3.
- **Hardware compatibility table**: a changed body fails probes and triggers repair.

### 3. Inner agent: a judge, not an agent

I would grow a judge: one bounded LLM call with no tools, no loop and no memory beyond its cases. An inner agent with its own loop is a second gunner.

**Growth.** During the build, anything the gunner chose by looking at a specific input must be a driver argument, never a constant in `driver.sh`. At promotion, every argument is classified in `BUILD.jsonl`:

- **intent**: supplied by the request.
- **constant**: the same across all probes, so inline it.
- **rule**: computable from the driver's `inspect` facts, so code it and re-probe.
- **judge**: a rule was written and failed a probe.

A judge exists only where a rule was tried and failed, and the failing probe is its first case. That is what keeps it bottom-up.

```
judges/audio_stream.md
---
fills:   audio_stream               # the driver argument it supplies
sees:    inspect.streams            # the only slice of result.json it is shown
returns: one of sees[].index | "escalate"
---
<a few lines written by the gunner from the failed rule>
```

The companion file `audio_stream.cases.jsonl` holds `{facts, answer, why, origin}` records.

**Invocation.**

1. Bench runs `inspect` and returns facts.
2. The next wake calls `ask_judge(op, arg)`. The harness builds the prompt from the judge file, the cases and the `sees` slice, then makes one vault call and validates the output against `returns`.
3. An invalid answer or `escalate` goes to the gunner, whose answer is appended as a new case.
4. Bench runs the real verb with the intent and judged arguments.

Three properties follow:

- **Seams only**: judgment happens at verb boundaries, because the sandbox cannot reach the vault.
- **Testable**: replay the cases whenever the judge file or the vault's model changes.
- **Removable**: if the gunner later finds a rule that reproduces every case, delete the judge.

### 4. Minimum viable first build

1. **Prove the barrel alone.** Install the harness changes, hand-write one operator, run bench, then delete the operator.
2. **Open one issue**: "Send me this note as a PDF." The target is a single static binary with GitHub release assets, such as typst or pandoc, with no judge.

Pass criteria:

- **Detection**: the agent opens the grow issue unprompted.
- **Registration**: `equipment/<name>/` lands within 8 rounds.
- **Kill test**: a later issue with a different note is served in one bench run from git alone.
- **Tamper test**: one flipped hex digit in `sha256` makes the gate refuse before anything executes.
- **Isolation test**: a probe that tries the network and looks for the OIDC variables gets nothing.

Grow a judge only with the second operator, when a real task produces an argument no rule settles.

### 5. Deliberately left out

- **Package managers and source builds**: each is a second resolver with its own trust story, so v1 has one fetch shape.
- **Cache**: correctness never depends on it. Add it when fetch time hurts.
- **Network or secrets for operators**: anything needing credentials is a tool and belongs in the vault, added by a human.
- **Operator-to-operator calls**: the gunner composes across seams.
- **Judges that edit themselves or are designed up front**: they grow by accumulating cases.
- **Sharing or a marketplace**: forks already inherit `equipment/`.
- **Large private inputs**: these need a presigned URL through the vault, so they are deferred.
- **Speculative verbs**: a driver grows a verb only when a task demands one.

### Residual risks

- **`run_shell` hole**: it still executes arbitrary code next to the vault token, and the growth rule only discourages that at prompt level. The real fix is cutting its network or moving it to bench.
- **URL rot**: a pinned release asset can disappear upstream.
- **Untrusted output**: operator output flows into the gunner's context, so it should read `result.json` fields rather than raw stdout.
- **Latency**: every seam costs a workflow run, roughly a minute.

### Decision for you

The bench split is the one piece to confirm. The alternative is a Docker sandbox inside the think job, which is faster and needs no second workflow. I would not take it, because isolation would then depend on the model choosing to use the sandbox.
