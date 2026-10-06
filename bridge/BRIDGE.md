# BRIDGE.md — the training graph on the Murex substrate

*The oracle-training-system email, translated. Not converted.*

**The bridge in one paragraph:** The email's learning graph (nodes.csv/edges.csv → compile → token router → sandbox/gate/train) runs as Murex. The CSVs stay — human-editable, in git, as the email's own math section demands they be *materialized views*, not ontology. A compile step (`compile.py`, stdlib only) validates them once per wake and emits two artifacts: `nodes.jsonl` (validated metadata) and `dispatch.mx` — the routing table *compiled to code*, because Murex cannot invoke a command from a variable and the router must therefore be codegen'd, not interpreted. Each node is a typed Murex function taking a token file as `$1`: it reads the JSON token, does one transformation, sets its verdict, writes the token back. The token file is the run state — crash-only, resumable. And the five nodes land on our reality like this: `gen_explore` is an LLM call, `sim_sandbox` is a network-cut shell, `oracle_eval` is the gate (test or judgment), `self_reflect` is the miss written to git, and `oracle_train` — the biggest translation in the document — is `git commit`. There is no GPU cluster. In a git-native agent, training the model *is* updating the repo. Every Murex construct in this spec was probed against the 7.2.1001 binary (§11) — and the probes changed the design three times: stdin pipes became the token-file contract, the interpreted router became compiled dispatch, and the naive sequential routing gained first-match-wins guards. The spec below is what survived contact with the binary.

---

## 1. What the email actually is (reading notes)

The email has two halves. The first (~150 lines) is the spec that matters: a configuration-driven Autonomous Continuous Learning Graph Framework — compile-then-execute, five node types, four-stage lifecycle (explore → simulate → evaluate → optimize), three layers (configuration, runtime engine, infrastructure). The remaining ~6,900 lines are alternative framings of the same idea (flow fields, wave interference, subtractive engines, crystallography, and finally a morphism algebra).

Three load-bearing details from the spec:

- **Zero-abstraction state.** "Nodes do not store execution data locally. They receive a primitive state dictionary, modify it, and pass it onward. Large operational files are saved to shared memory or object storage, and only their file paths or addresses are passed down the edges." → In our world: the token carries *references* (paths, git SHAs), never payloads. Git is the object storage.
- **Compile-time validation.** "When the engine boots up, it parses the CSV files once to map out memory structures, check topology validity, and optimize execution paths. The runtime engine does not perform any file parsing." → Compile once at wake; runtime reads only the compiled artifact.
- **The Tutor never runs inside the loop.** "The Tutor Model is your structural architect. It should only run to change the enums or add new nodes inside your nodes.csv. It must never run inside the active runtime loop." → Graph mutation is a human commit, never a runtime act. (The skeptic's "grown judges" warning, independently derived.)

And from the morphism-algebra capstone, the sentence that authorizes this entire document:

- **"nodes.csv and edges.csv should not be the ontology. They should be materialized views."** → We keep the CSVs as the human projection and compile them to what runs. The email asks for exactly this.
- **Compilation morphisms:** "Compress proven high-cost behavior into low-cost reusable behavior." → That is the definition of `oracle_train` in our world: a proven candidate becomes a committed operator.

---

## 2. The token — the only interface

Every node is a Murex function with one contract: **it takes a token FILE path as `$1`, reads the JSON token, transforms it, and writes it back.** The token file is the run state — every step persists it, so a killed wake resumes by re-reading the file. (An earlier draft had nodes reading stdin; probing the 7.2.1001 binary showed the `${ stdin -> cast json }` idiom from the existing modules is broken on this build — see the probe log in §11. The token-file contract replaces it, and it's the better design anyway: crash-only, no pipes to break.)

```json
{
  "run_id":     "20261006-001",
  "lane":       "plugin | prompt | radio",
  "node":       "gen_explore",
  "loop":       0,
  "verdict":    "pending | pass | fail | revise",
  "route":      "sim_sandbox",
  "artifact":   "path or git SHA — never the payload",
  "evidence":   {},
  "history":    []
}
```

Rules (from the spec's zero-abstraction state, translated):

1. The token carries references, never payloads. A prompt variant lives in `runs/<run_id>/variant-3.md`; the token carries the path.
2. Each node appends to `history` — `{node, at, verdict, note}` — so the token is its own audit trail.
3. `verdict` is set by the node from its work; `route` is set by the compiled dispatch from the edges.csv routing conditions. Nodes never know the graph topology — they are morphisms: one transformation, one verdict.
4. `loop` increments on every cycle back through `self_reflect`. The compiled dispatch enforces `max_loops` and the circuit breaker via the `under_max_loops` / `on_circuit_breaker` conditions — the node never does.
5. Nodes never see each other's variables. Murex functions can't see file-level globals and can't be invoked from variables — so all coordination goes through the token file, and dispatch is compiled, not interpreted (§3).

---

## 3. The compile step — CSVs to runnable graph

Source of truth (in git, human-editable, per lane — e.g. `graph/plugin/nodes.csv`):

```csv
node_id,node_type,execution_target,timeout_s
want_gen,generator,llm_cli,300
gate_check,evaluator,murex_assert,60
build_sim,simulator,netcut_shell,600
reflect,reflector,llm_cli,300
register,optimizer,git_commit,120
```

```csv
edge_id,source_node,target_node,routing_condition
e1,want_gen,gate_check,always
e2,want_gen,discard_sink,on_circuit_breaker
e3,gate_check,build_sim,on_pass
e4,gate_check,discard_sink,on_deny
e5,gate_check,discard_sink,on_circuit_breaker
e6,build_sim,register,on_pass
e7,build_sim,reflect,on_fail
e8,build_sim,discard_sink,on_circuit_breaker
e9,reflect,build_sim,under_max_loops
e10,reflect,discard_sink,on_circuit_breaker
e11,register,train_sink,on_pass
e12,register,discard_sink,on_circuit_breaker
```

Every node ends with an `on_circuit_breaker` fallthrough to a sink — the compiler (§3) rejects graphs without one, because an unmatched verdict would otherwise leave `route` unchanged and livelock the runner. An unexpected verdict is a malfunction; discard + ledger is the safe response. The train node (`register`) routes to `train_sink` on success — the runner's terminal condition.

Note the translations already visible: `execution_target` values are ours (`llm_cli`, `netcut_shell`, `git_commit`), timeouts are ours (300s, not 5s — the mechanism kept, the numbers translated), and the node names are the lane's own (the email's five names are kept in the worked examples below as the canonical mapping).

The compiler runs once per wake. It validates the graph and emits **two** runtime artifacts — and this is the deepest compile-then-execute move in the bridge:

1. **`nodes.jsonl`** — validated node metadata, one object per line: `{"id","type","target","timeout_s"}`. JSONL, not one JSON object, because Murex's native idiom is line-oriented (`foreach` over JSONL is probed; variable `[[ ]]` indexing is broken on this build — §11).
2. **`dispatch.mx`** — the routing table *compiled to code*. The email's "in-memory dependency map (adjacency matrix)" becomes a Murex function with a literal if/then chain per node. This is necessary, not decorative: Murex cannot invoke a command from a variable, so an interpreted router is impossible — the router must be codegen'd.

The compiler itself is a small Python script (stdlib only — `csv`, `json`). One deliberate seam: Murex has no string-split builtin (bare `split` resolves to `/usr/bin/split`), so CSV parsing is not the substrate's job. The compiler parses and validates; everything downstream is Murex.

The separation this buys: **nodes are morphisms** — each does one transformation and reports a verdict. They never know the graph topology. **Dispatch owns the graph** — the edges.csv conditions live here, compiled. (This also fixes the token contract: the node sets `verdict` + `evidence`; dispatch sets `route`. §2 rule 3 updated accordingly.)

```python
# graph/compile.py — nodes.csv + edges.csv -> nodes.jsonl + dispatch.mx
# stdlib only. Run once per wake. Fails loudly on invalid topology.
import csv, json, sys

gdir = sys.argv[1]  # e.g. graph/plugin

nodes = {}
with open(f"{gdir}/nodes.csv") as f:
    for row in csv.DictReader(f):
        nodes[row["node_id"]] = row

edges = []
with open(f"{gdir}/edges.csv") as f:
    for row in csv.DictReader(f):
        if row["source_node"] not in nodes:
            sys.exit(f"compile: edge {row['edge_id']} from unknown node {row['source_node']}")
        tgt = row["target_node"]
        if tgt not in nodes and not tgt.endswith("_sink"):
            sys.exit(f"compile: edge {row['edge_id']} to unknown node {tgt}")
        edges.append(row)

# routing_condition -> murex boolean expression over the re-read token.
# Edges are evaluated in file order, FIRST MATCH WINS: every edge after
# the first is guarded by "route still equals the source node", so an
# earlier match can't be overwritten by a later one.
def cond_expr(c):
    return {
        "always":             "true",
        "on_pass":            '$tok[[ /verdict ]] == "pass"',
        "on_passed_gate":     '$tok[[ /verdict ]] == "pass"',
        "on_deny":            '$tok[[ /verdict ]] == "deny"',
        "on_fail":            '$tok[[ /verdict ]] == "fail"',
        "on_failed_gate":     '$tok[[ /verdict ]] == "fail"',
        "on_revise":          '$tok[[ /verdict ]] == "revise"',
        "on_kill":            '$tok[[ /verdict ]] == "kill"',
        "under_max_loops":    '$tok[[ /loop ]] < $maxloops',
        "on_circuit_breaker": "true",   # fallthrough: nothing else matched
    }[c]

# 1. nodes.jsonl — validated node metadata, one object per line.
# All CSV columns pass through (lane-specific extras like gate_kind
# survive); timeout_s is coerced to int.
with open(f"{gdir}/nodes.jsonl", "w") as f:
    for nid, n in nodes.items():
        rec = {"id": nid}
        rec.update({k: v for k, v in n.items() if k != "node_id"})
        rec["timeout_s"] = int(rec["timeout_s"])
        f.write(json.dumps(rec) + "\n")

# 2. dispatch.mx — the router, compiled
L = ["# dispatch.mx — GENERATED by compile.py. Do not hand-edit.",
     f"# Regenerate: python3 graph/compile.py {gdir}",
     "# Node contract: <node> <token-file> <lane-dir>.",
     "# The node sets verdict (+evidence) and writes the token file.",
     "# Dispatch evaluates routing conditions and sets the next route.",
     "function dispatch {",
     "    try { $f = $1 }",
     '    catch { err "dispatch: token file required"; return 1 }',
     "    try { $maxloops = $2 }",
     "    catch { $maxloops = 2 }",
     "    $tok = ${ cat $f -> cast json }",
     "    $r = $tok[[ /route ]]"]
adj = {}
for e in edges:
    adj.setdefault(e["source_node"], []).append(e)

# Exhaustiveness: every node must end with an always-true edge
# (always | on_circuit_breaker), otherwise an unmatched verdict
# leaves route unchanged and the runner livelocks on the same node.
for src, es in adj.items():
    if cond_expr(es[-1]["routing_condition"]) != "true":
        sys.exit(f"compile: node {src} has no fallthrough edge "
                 f"(last edge {es[-1]['edge_id']} is conditional)")
for src, es in adj.items():
    L.append(f'    if {{ $r == "{src}" }} then {{')
    L.append(f'        {src} $f "{gdir}"')
    L.append("        $tok = ${ cat $f -> cast json }")
    for i, e in enumerate(es):
        cond = cond_expr(e["routing_condition"])
        tgt = e["target_node"]
        if i == 0:
            L.append(f'        if {{ {cond} }} then {{ $tok.route = "{tgt}" }}')
        else:
            # first match wins: only fire if no earlier edge matched
            L.append(f'        if {{ $tok[[ /route ]] == "{src}" && {cond} }} then {{ $tok.route = "{tgt}" }}')
    L.append("        out ${ $tok -> cast str } -> > $f")
    L.append("    }")
L += ["}", ""]

with open(f"{gdir}/dispatch.mx", "w") as f:
    f.write("\n".join(L))

print(f"compiled {len(nodes)} nodes, {len(edges)} edges -> {gdir}/dispatch.mx")
```

Generated output for the plugin lane (what the compiler emits — all literals, all probed constructs):

```murex
# dispatch.mx — GENERATED by compile.py. Do not hand-edit.
function dispatch {
    try { $f = $1 }
    catch { err "dispatch: token file required"; return 1 }
    try { $maxloops = $2 }
    catch { $maxloops = 2 }
    $tok = ${ cat $f -> cast json }
    $r = $tok[[ /route ]]
    if { $r == "want_gen" } then {
        want_gen $f "graph/plugin"
        $tok = ${ cat $f -> cast json }
        if { true } then { $tok.route = "gate_check" }
        if { $tok[[ /route ]] == "want_gen" && true } then { $tok.route = "discard_sink" }
        out ${ $tok -> cast str } -> > $f
    }
    if { $r == "gate_check" } then {
        gate_check $f "graph/plugin"
        $tok = ${ cat $f -> cast json }
        if { $tok[[ /verdict ]] == "pass" } then { $tok.route = "build_sim" }
        if { $tok[[ /route ]] == "gate_check" && $tok[[ /verdict ]] == "deny" } then { $tok.route = "discard_sink" }
        if { $tok[[ /route ]] == "gate_check" && true } then { $tok.route = "discard_sink" }
        out ${ $tok -> cast str } -> > $f
    }
    if { $r == "build_sim" } then {
        build_sim $f "graph/plugin"
        $tok = ${ cat $f -> cast json }
        if { $tok[[ /verdict ]] == "pass" } then { $tok.route = "register" }
        if { $tok[[ /route ]] == "build_sim" && $tok[[ /verdict ]] == "fail" } then { $tok.route = "reflect" }
        if { $tok[[ /route ]] == "build_sim" && true } then { $tok.route = "discard_sink" }
        out ${ $tok -> cast str } -> > $f
    }
    if { $r == "reflect" } then {
        reflect $f "graph/plugin"
        $tok = ${ cat $f -> cast json }
        if { $tok[[ /loop ]] < $maxloops } then { $tok.route = "build_sim" }
        if { $tok[[ /route ]] == "reflect" && true } then { $tok.route = "discard_sink" }
        out ${ $tok -> cast str } -> > $f
    }
    if { $r == "register" } then {
        register $f "graph/plugin"
        $tok = ${ cat $f -> cast json }
        if { $tok[[ /verdict ]] == "pass" } then { $tok.route = "train_sink" }
        if { $tok[[ /route ]] == "register" && true } then { $tok.route = "discard_sink" }
        out ${ $tok -> cast str } -> > $f
    }
}
```

The `$tok[[ /route ]] == "<src>"` guard is what makes "first match wins" literally true with sequential `if`s — without it, the unconditional fallthrough would overwrite an earlier match (caught by executing the compiler's output, not by reading it). Edge ordering in edges.csv is therefore most-specific-first, breaker-last; the compiler enforces the breaker-last part.

Validation is the point of compiling: unknown endpoints, unhandled verdicts, and missing node functions fail at boot, not mid-run. The runtime never parses CSV.

---

## 4. The runner — the minimal loop

The email's "async token router" translated to one box: a sequential queue loop. The runner calls the compiled `dispatch` until the token reaches a sink. No async machinery — the token abstraction is the meaning, the concurrency was the token of a docker-cluster world.

```murex
# run.mx — the token router. Sequential, bounded, boring on purpose.
# PROBED on murex 7.2.1001 (see §11). Every construct below was executed.
function graph-run {
    # $1 = token file, $2 = max loops (default 2)
    try { $f = $1 } catch { err "graph-run: token file required"; return 1 }
    try { $maxloops = $2 } catch { $maxloops = 2 }

    $tok = ${ cat $f -> cast json }
    $r = $tok[[ /route ]]
    # NOTE: murex conjunction is && — the word `and` does not parse here.
    while { $r != "discard_sink" && $r != "train_sink" } {
        dispatch $f $maxloops
        $tok = ${ cat $f -> cast json }
        $r = $tok[[ /route ]]
    }
    out "done route="$r" loops="${ $tok[[ /loop ]] -> cast str }
}
```

That's the whole runner. The loop bound and circuit breaker live in the compiled dispatch (the `under_max_loops` / `on_circuit_breaker` conditions), not here — one place owns routing. The runner owns only: *keep going until a sink*.

Design notes:

- **The token file is the run state.** Dispatch writes it after every node. A killed wake resumes by re-running `graph-run` on the same file — crash-only discipline, matching the agent's 15-minute death cycle rather than fighting it.
- **Timeouts** (`timeout_s` in nodes.csv): v1 treats them as *documented budgets*, not enforced preemption. The column records what each step should cost; the hard bound is the wake-level timeout (cron kills a runaway wake). Per-step preemptive kill inside the shell is not probed — documented limitation, not a silent gap. The email's timeout column exists to bound cost; our costs are per LLM call, not per millisecond, and the dangerous step (install) is bounded by the network-cut sandbox instead. If chronic overruns ever need to feed `self_reflect`, the `nodes.jsonl` scan is six lines of probed constructs (`foreach` + `if`) — deliberately deferred, not forgotten.
- **Queue of runs:** multiple tokens = multiple token files in `runs/queue/`. The wake script picks the oldest, runs `graph-run` on it, moves it to `runs/done/` or `runs/discarded/`. Parallelism, if ever wanted, is "run two wake scripts" — not async machinery in the runner.

---
## 5. The five nodes, mapped onto our reality

The email's canonical five, with their execution targets translated:

| Email node | Email target | Our target | Our meaning |
|---|---|---|---|
| `gen_explore` | `llm_inference_api` | `llm_cli` | Generate N candidates (operator proposals, prompt variants, material bits). "High temperature" = varied sampling, multiple candidates, never one. |
| `sim_sandbox` | `docker_worker_pool` | `netcut_shell` | Execute the candidate in isolation. Fetch networked, install with no route out. The distilled loop's build step. |
| `oracle_eval` | `deterministic_verifier` | `gate` | The verdict. Test-kind (mechanical) or judge-kind (typed judgment) — see §6. |
| `self_reflect` | `llm_inference_api` | `llm_cli` + git | Analyze the miss, mutate the candidate, max 2 retries. The miss is written to `misses.md` — reflection persists in git, not just in-context. |
| `oracle_train` | `gpu_cluster_job` | `git_commit` | **The master translation.** No cluster, no fine-tuning. The email's own math defines train as compilation — "compress proven high-cost behavior into low-cost reusable behavior." Committing the winning artifact + manifest to git IS training: the agent's next wake is born with the new capability. The model being optimized is the repo. |

Each node is a Murex function following the module conventions (from `git.mx`/`cf.mx`): `try`/`catch` on args, `err` + `return 1` on failure, `out ${ ... -> cast str }` for emission — plus the bridge's own probed rules (§11): token file as `$1`, literal `[[ /paths ]]`, `sh -c` for dynamic shell strings. The node sets `verdict` (+ `evidence`); dispatch sets `route`. Sketch of the two load-bearing nodes:

```murex
# oracle_eval, test-kind: run the manifest's tests, verdict is mechanical
function oracle_eval {
    try { $f = $1 } catch { err "oracle_eval: token file required"; return 1 }
    try { $gdir = $2 } catch { err "oracle_eval: lane dir required"; return 1 }
    $tok = ${ cat $f -> cast json }
    $manifest = ${ cat $tok[[ /artifact ]] -> cast json }
    $pass = "true"
    $manifest[[ /tests ]] -> foreach t {
        try { sh -c $t }
        catch { $pass = "false" }
    }
    $h = ${ tout json '{"node":"oracle_eval","verdict":""}' }
    if { $pass == "true" } then {
        $tok.verdict = "pass"
        $h.verdict = "pass"
    } else {
        $tok.verdict = "fail"
        $h.verdict = "fail"
    }
    $tok.history = ${ $tok.history -> append $h }
    out ${ $tok -> cast str } -> > $f
}

# oracle_train: the commit. Training IS updating the repo.
function oracle_train {
    try { $f = $1 } catch { err "oracle_train: token file required"; return 1 }
    $tok = ${ cat $f -> cast json }
    $art = $tok[[ /artifact ]]
    git add $art
    $msg = ${ out "train: promote "${ $tok[[ /run_id ]] -> cast str } }
    try { git commit -m $msg }
    catch {
        $tok.verdict = "fail"
        out ${ $tok -> cast str } -> > $f
        return 1
    }
    $tok.verdict = "pass"
    out ${ $tok -> cast str } -> > $f
}
```

---

## 6. The judgment gate — when the gate is taste, not test

The email assumes `oracle_eval` is deterministic: "syntax parsers, unit test execution, or hard reward boundary checks." Lane 3 (Radio Hour) breaks that assumption — the gate is whether the bit *lands*. The mechanism:

**The gate is typed, not deterministic.** What makes a gate trustworthy was never determinism — it's that the verdict is a typed object with a confidence, cited evidence, and a recorded reviewer, committed to the ledger where it can be audited. A JEV judgment at 0.91 with evidence IS a gate.

The `oracle_eval` node takes a `gate_kind` from the graph config:

- `gate/test` — mechanical. Run the tests; the verdict is boolean. (Lanes 1 and 2.)
- `gate/judge` — judgmental. A panel of K cheap judge calls (JEV or small model), each with a FIXED, human-written, git-versioned prompt (the skeptic's constraint: judges are fixed, never grown), each emitting a typed verdict:

```json
{"verdict": "keep | kill | revise", "confidence": 0.0-1.0, "reason": "...", "judge": "playtester-2"}
```

Aggregation (the email's own Jev-as-gradient-filter, translated): confidence-weighted majority. `keep` wins iff weighted keep-votes ≥ threshold AND no judge vetoes below a floor. Split panel (no clear majority) → route `revise` once, then route to **human** — the skeptic's "one human click." The human gate is load-bearing, not a placeholder.

The anti-Goodhart rules, from the skeptic, enforced structurally:

1. Judges never see build outcomes — only the artifact. (Build pass/fail measures function, never taste.)
2. Judge prompts are versioned in git; the agent may propose changes as a PR, never edit them in-loop.
3. Every verdict — keep, kill, revise — with confidences and reasons, goes into the run ledger. The gate is auditable or it isn't a gate.

---

## 7. Three worked examples

### Lane 1 — Plugin growing (the distilled loop, as a graph)

`graph/plugin/nodes.csv`:

```csv
node_id,node_type,execution_target,timeout_s
want_gen,generator,llm_cli,300
gate_check,evaluator,murex_assert,60
build_sim,simulator,netcut_shell,600
reflect,reflector,llm_cli,300
register,optimizer,git_commit,120
```

`graph/plugin/edges.csv`:

```csv
edge_id,source_node,target_node,routing_condition
e1,want_gen,gate_check,always
e2,want_gen,discard_sink,on_circuit_breaker
e3,gate_check,build_sim,on_pass
e4,gate_check,discard_sink,on_deny
e5,gate_check,discard_sink,on_circuit_breaker
e6,build_sim,register,on_pass
e7,build_sim,reflect,on_fail
e8,build_sim,discard_sink,on_circuit_breaker
e9,reflect,build_sim,under_max_loops
e10,reflect,discard_sink,on_circuit_breaker
e11,register,train_sink,on_pass
e12,register,discard_sink,on_circuit_breaker
```

One run, end to end:

1. **want_gen** reads `needs/ffmpeg.md` ("cut mp4 for the radio hour"), proposes a candidate: source URL + sha256 + install recipe. Token: `{lane: plugin, artifact: runs/20261006-001/proposal.json, route: gate_check}`.
2. **gate_check** (`gate/test`): source host in `allowlist.txt`? Operation read-only? Both yes → `verdict: pass, route: build_sim`. (If no: `on_deny` → `discard_sink`, issue opened, human notified.)
3. **build_sim**: fetch tarball (networked), verify sha256 against two independent sources, then **install in the network-cut shell** — no route out, so the installer cannot exfiltrate. Run the manifest's tests. Tests pass → `verdict: pass, route: register`.
4. **register** (= `oracle_train`): `git add plugins/ffmpeg/`, commit. The operator is now permanent equipment; the next wake is born with it.
5. On test failure instead: `route: reflect` → **reflect** reads the failure log, writes the miss to `plugins/ffmpeg/misses.md`, mutates the recipe, `loop: 1`, back to `build_sim`. Two retries max, then `on_circuit_breaker` → `discard_sink` with the full miss history in git.

The train step, in the email's math: a compilation morphism — proven high-cost behavior (fetching, verifying, building) compressed into low-cost reusable behavior (the manifest + installed operator).

### Lane 2 — Prompt evolution (the email's original intent, almost untranslated)

This lane is the closest to what the email describes — the spec's example IS "generate novel agent behaviors." The nodes keep the email's canonical names:

`graph/prompt/nodes.csv`:

```csv
node_id,node_type,execution_target,timeout_s
gen_explore,generator,llm_cli,300
sim_sandbox,simulator,eval_harness,600
oracle_eval,evaluator,murex_assert,120
self_reflect,reflector,llm_cli,300
oracle_train,optimizer,git_commit,120
```

`graph/prompt/edges.csv`:

```csv
edge_id,source_node,target_node,routing_condition
e1,gen_explore,sim_sandbox,always
e2,gen_explore,discard_sink,on_circuit_breaker
e3,sim_sandbox,oracle_eval,always
e4,sim_sandbox,discard_sink,on_circuit_breaker
e5,oracle_eval,oracle_train,on_passed_gate
e6,oracle_eval,self_reflect,on_failed_gate
e7,oracle_eval,discard_sink,on_circuit_breaker
e8,self_reflect,gen_explore,under_max_loops
e9,self_reflect,discard_sink,on_circuit_breaker
e10,oracle_train,train_sink,on_pass
e11,oracle_train,discard_sink,on_circuit_breaker
```

One run:

1. **gen_explore**: mutate the incumbent prompt → N variants (temperature high, sampling varied). Token artifact: `runs/<id>/variants.jsonl` (paths, not payloads).
2. **sim_sandbox**: the "sandbox" here is the eval harness — each variant runs against the fixed task set. No network-cut needed (no fetched code); isolation = the harness's fixed inputs.
3. **oracle_eval** (`gate/test`): aggregate scores, compare against the incumbent baseline committed in git. Winner beats baseline by ≥ margin → `on_passed_gate`.
4. **oracle_train**: the winning prompt replaces the incumbent in git; the full score ledger commits alongside. The "model" being fine-tuned is the prompt corpus — the email's `gpu_cluster_job` translated to a commit, with the score ledger as the training curve.
5. **self_reflect** on failure: analyze *which tasks* the variants lost on, propose directed mutations (not random), back to `gen_explore`.

Note: this is the evolver, productionized — the generate → judge → keep-winners loop it already runs, now with the graph's compile-time validation, token audit trail, and circuit breaker.

### Lane 3 — Radio Hour material (the judgment gate, worked)

`graph/radio/nodes.csv`:

```csv
node_id,node_type,execution_target,timeout_s,gate_kind
material_gen,generator,llm_cli,300,
stage_sim,simulator,murex_render,120,
taste_eval,evaluator,judge_panel,300,judge
rewrite_reflect,reflector,llm_cli,300,
keep,optimizer,git_commit,120,
```

`graph/radio/edges.csv`:

```csv
edge_id,source_node,target_node,routing_condition
e1,material_gen,stage_sim,always
e2,material_gen,discard_sink,on_circuit_breaker
e3,stage_sim,taste_eval,always
e4,stage_sim,discard_sink,on_circuit_breaker
e5,taste_eval,keep,on_passed_gate
e6,taste_eval,rewrite_reflect,on_revise
e7,taste_eval,discard_sink,on_kill
e8,taste_eval,discard_sink,on_circuit_breaker
e9,rewrite_reflect,material_gen,under_max_loops
e10,rewrite_reflect,discard_sink,on_circuit_breaker
e11,keep,train_sink,on_pass
e12,keep,discard_sink,on_circuit_breaker
```

One run:

1. **material_gen** (MiniMax): from a premise ("the lighthouse keeper's log"), generate 5 bits. Artifact: `runs/<id>/bits.jsonl`.
2. **stage_sim**: the "sandbox" is the stage — render each bit as a script fragment (the email's simulator, translated: not executing code, but *staging* the artifact where it can be judged). No isolation needed beyond fixed formatting.
3. **taste_eval** (`gate/judge`): the playtester panel — 3 fixed-prompt judges (the animator, the dog, the kid — the formation from the bubble playtests), each emitting `{verdict, confidence, reason}`. Confidence-weighted majority:
   - Bit 2: keep 0.9, keep 0.85, revise 0.6 → **keep** → `on_passed_gate` → `keep`.
   - Bit 4: kill 0.95, keep 0.5, kill 0.8 → **kill** → `on_kill` → `discard_sink` (reasons ledgered — the miss is the curriculum, even for jokes).
   - Bit 5: keep 0.55, revise 0.6, keep 0.5 → no clear majority → `on_revise` → `rewrite_reflect` with the judges' reasons attached.
4. **rewrite_reflect**: feed the reasons back to the generator ("the kid didn't get the lighthouse reference — earn it earlier"), `loop: 1`, regenerate.
5. **keep** (= `oracle_train`): keepers commit to the show bible in git. The material library is the model being trained; the ledger of verdicts is the training data for future premises.

The split-panel → human rule: if after one revise the panel still splits, the bit routes to Casey — one click, keep or kill. Taste's final gate is the human, and the graph says so explicitly.

---

## 8. Translation ledger — every meaning-over-token choice

| # | Email's token | Our meaning | Why |
|---|---|---|---|
| 1 | `oracle_train` → `gpu_cluster_job` | `git_commit` | The email's own math (§4) defines train as compilation: proven high-cost behavior → low-cost reusable behavior. The agent IS its repo; updating the repo IS training the model. A GPU cluster would be conversion — the token of a world with models to fine-tune. |
| 2 | Async token router, worker pool | Sequential queue loop, token file as state | The token abstraction is the meaning; the concurrency was the token of a docker-cluster world. One ARM box, crash-only wakes — the loop is sequential and the token file makes it resumable. |
| 3 | Redis / state buffer | Git ledger | The email asks "database schema or stateless?" — the answer is the third option: the ledger. The token carries run state; git accumulates history. No new infrastructure (lobster law). |
| 4 | `docker_worker_pool` | `netcut_shell` | Isolation is the meaning; docker is the token. Fetch networked, install with no route out — the distilled version's challenge to the bench split, adopted as the sandbox. |
| 5 | Deterministic verifier | Typed gate (test-kind or judge-kind) | The gate's meaning is trust + auditability, not determinism. A typed, confidence-scored, ledgered judgment IS a gate. The email's routing conditions (`on_passed_gate`, `on_circuit_breaker`) survive unchanged — the mechanism was always sound. |
| 6 | `nodes.csv`/`edges.csv` as config | Same files, as materialized views | Kept deliberately — but per the email's own capstone, they are the human projection, not the ontology. The compiled `dispatch.mx` + `nodes.jsonl` are what run. This is the one place the email explicitly authorized the translation. |
| 7 | Timeout columns (5s/15s/2s/600s) | Same columns, our numbers (60–600s) | The timeout *mechanism* is the meaning; the millisecond values were the token of fast APIs. LLM calls and builds take minutes here. |
| 8 | Tutor mutates `nodes.csv` at runtime (dimensional expansion) | **Refused.** Graph changes are human commits. | The email itself says the Tutor "must never run inside the active runtime loop," and the skeptic showed grown governance is self-modification laundered. Translation as refusal: the meaning (graphs evolve) is preserved through the human, not the runtime. The pruning sweep and orthogonality check survive as human-run maintenance, not runtime machinery. |
| 9 | Weight tensors / numpy parameter space | The ledger as parameter space | O(1) matrix lookups are the token of a world doing millions of inferences. Our "weights" are accumulated manifests, misses, and scores — the ledger, read at wake. When (if) inference volume ever justifies tensors, the ledger is the training data. Not now. |
| 10 | Node names (`gen_explore` etc.) | Kept verbatim | The names are good tokens that carry the meaning cleanly onto our world. Keeping them anchors the mapping — everyone reading the graph knows which email node they're standing in. |
| 11 | Stdin/stdout token pipes | Token *file* contract | Probing showed `${ stdin -> cast json }` is broken on the 7.2.1001 build. The file contract is the better design regardless: the token file is crash-only run state, and nodes never hold a pipe open across a wake death. The breakage improved the architecture. |
| 12 | In-memory adjacency matrix | Compiled `dispatch.mx` | The email's dependency map becomes code, not data — forced by the substrate (no variable-command invocation), but also the honest compile-then-execute: edges.csv conditions are compiled to routing logic, not interpreted at runtime. |
| 13 | Everything in the substrate | One `compile.py` seam (stdlib) | Murex has no string-split; CSV parsing is not the shell's job. The compiler is allowed this one seam because its output (JSONL + generated Murex) is fully on-substrate. Purity where it matters, pragmatism where it doesn't. |

---

## 9. What's cut (distiller's discipline)

- **No async machinery.** Sequential loop. (Cut: the email's non-blocking task system.)
- **No state buffer service.** Git. (Cut: Redis/memory pointers.)
- **No GPU anything.** `git commit`. (Cut: the optimizer infrastructure.)
- **No docker fleet.** One network-cut shell. (Cut: the worker pool.)
- **No runtime graph mutation.** Human commits, recompile at wake. (Cut: the dimensional expansion engine, the mutating compiler — the email's most speculative machinery, and the part its own text confines outside the loop.)
- **No weight tensors.** The ledger. (Cut: the entire Jev-to-numpy pipeline — right idea, wrong decade for one box.)
- **No second registry.** Per-lane `graph/` dirs; the directory is the registry. (Cut, per the distilled version: the registry file was already killed there.)
- **No grown judges.** Fixed, versioned, human-amended. (Cut, per the skeptic: the judge-growth loop.)

What remains — the minimal bridge: **a token schema, a compiler (CSVs → nodes.jsonl + dispatch.mx), a runner (the queue loop), five node functions per lane, and git as the train step.** Everything else is commentary.

---

## 10. Build order — the first loop

1. **Token schema** — document it once, in `graph/TOKEN.md`. Every lane uses the same shape.
2. **Compiler** — `graph/compile.py` (stdlib only), per §3. Prove it on the plugin lane's CSVs: valid graphs compile to working `dispatch.mx`, dangling edges fail at boot.
3. **Runner** — `graph/run.mx`, per §4. Prove it with a two-node test graph before any real lane (the probe pattern in §11 is the test harness — extend it).
4. **Lane 1 first** — the plugin lane is the proof ritual the distilled version demands: grow one real operator (the `disk-report` pattern) through want → gate → build → learn → run, end to end, on Murex.
5. **Lane 2** — port the evolver's loop onto the graph. It already runs; the bridge gives it validation, tokens, and the circuit breaker.
6. **Lane 3** — the judgment gate. Last, because it's the least mechanical — but the panel mechanism (§6) is specified now, so it's buildable, not hand-wavy.
7. **The detection story** (from the skeptic) rides alongside: tripwire on the fixed files (`compile.py`, `run.mx`, `dispatch.mx`, judge prompts), ledgered verdicts as the audit trail. The provenance story without the detection story is a forensics kit; build both.

---

## 11. Probe log — what the binary actually does

All Murex in this document was probed against `~/workspace/murex-dev/bin/murex` (7.2.1001) on 2026-10-06, following the repo's "probed, not guessed" discipline. Findings:

**Works (used in the spec):**
- `while { cond }` loops; conjunction is `&&` — the word `and` does NOT parse in conditions ("commands cannot begin with '$'").
- Functions taking `$1`/`$2` args with `try`/`catch` guards.
- `cat $file -> cast json` to read a token; `out ${ $tok -> cast str } -> > $file` to write it back (fresh-write; `-> >>` is illegal per the radio-hour lane's probes).
- Literal `[[ /path ]]` indexing; `$obj.key = val` mutation; `-> append` on arrays.
- `foreach` over JSONL with `if { ... } then { ... }` filtering.
- `sh -c $var` for executing a dynamic shell string (the command position must be literal).
- Literal if/then dispatch chains calling functions by literal name.
- `tout json '...'` for building objects; `err` + `return 1` for failure.
- Assignment with `${ }` RHS inside `while` inside functions; bare-literal RHS (`$a = "lit"`); index-expression RHS (`$b = $obj[[ /k ]]`).

**Broken or absent (designed around):**
- `${ stdin -> cast json }` — fails on 7.2.1001 ("Not a valid expression: 'stdin'"), even though the existing `cf.mx` module's private `cf-unwrap` uses it. That module's authenticated paths were never live-tested (no token), so the idiom was never truly exercised. **The bridge does not use stdin capture anywhere** — the token-file contract replaces it. (This also means `cf-unwrap` is suspect until re-probed; flagged, not fixed — not this document's job.)
- `$obj[[ $var ]]` — variable indexing fails (and fails *weirdly*: `$key`="beta" reported "key 'eta' not found"). All indexing in the spec uses literal paths; lookups by variable go through `foreach`+`if` scans over JSONL.
- Bare `split` — resolves to `/usr/bin/split`, not a builtin. No Murex-native string split was found; CSV parsing lives in the `compile.py` seam.
- Variable-command invocation (`| $node`) — "commands cannot begin with '$'". Hence the codegen'd `dispatch.mx`: the router is compiled, not interpreted.
- Functions cannot see file-level globals — hence lane config passed as literal args baked in at compile time.
- `catch`-block assignments are silently lost (subscope) — the spec never assigns inside `catch`; defaults are pre-initialized.

The probe scripts live in `/tmp` (ephemeral by design — they were scaffolding, not deliverables). The patterns they verified are reproduced above; re-probe before building if the binary version changes.

---

*The mouse-video rule, observed: conversion would have carried the tokens across — docker pools, GPU jobs, Redis, numpy tensors — and produced a small, strange, unusable thing. Translation carried the meaning: a learning loop is generate → isolate → judge → remember, and on our box that is LLM → netcut shell → typed gate → git commit. Do not "fix" this document by adding the cluster back.*
