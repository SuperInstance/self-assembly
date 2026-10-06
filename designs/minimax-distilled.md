# Self-Assembly — the distilled version
*MiniMax lane, second pass. Lens: distillation. If the whole architecture fits on one page, what's on it?*

## 1. The essence

The agent dies every fifteen minutes and is reborn from git. That single fact is the architecture: it deletes hot-reload, updaters, repair paths, and uninstallers in one stroke, because the next wake *is* the reload and `git revert` *is* the uninstall. What survives the deletion is almost nothing — a directory of equipment, a receipt per tool saying what was fetched and with what hash, and one rule: **the gunner never builds the gun.** The assembler is fixed, human-owned, and hash-checked at every wake; it grows equipment but is never itself grown. Everything the other three versions added beyond this is commentary — some of it good commentary, but commentary.

## 2. The load-bearing ideas

**Ephemerality is the design, not a constraint.** The 15-minute death cycle does the work of four mechanisms the other versions built anyway. Any proposal that adds machinery for something a fresh wake already provides is spending the budget twice. (This was the pragmatic version's best line, and it should have been the whole version.)

**The fixed assembler, verified before it touches anything.** "Human-owned" is sentiment; a hash check at wake is a mechanism. The invariant: fetched code may extend the agent's *capabilities*, never its *control*. The cheapest test is the obvious one — compare the assembler's hash to the known-good value before it runs. If that check fails, nothing else matters; if it holds, the rest is details.

**Provenance is a receipt, not an infrastructure.** The rule is one sentence: a hash counts only if the assembler fetched it from somewhere the agent didn't write. Dual-source verification is this sentence wearing a uniform. No token systems, no second workflows — the sentence is the mechanism.

**Failures are the curriculum.** Scar tissue, replayable records, judgment-vs-mechanical tags — one idea in three dialects: every miss is written down where the next attempt can read it. The judge is never designed; it accretes. The corollary: failures stay in git, because a system that forgets what didn't work pays tuition twice.

## 3. What the others overcomplicate

**Claude's two-workflow bench split.** Correct direction, wrong size for v1. The actual requirement is "fetched code never runs in a job that can mint a vault token." That's achievable by *cutting the network from the shell the installer runs in* plus a fetch recipe that never sees secrets — not by raising a second CI organism that needs feeding, versioning, and its own human-installed bootstrap. The bench answers the wrong question; the question is "where do secrets live," not "how many workflows."

**Kimi's install apparatus.** Dual-source verification is a one-line rule; Kimi wraps it in an 8-step bounded loop with max-iteration caps, concurrent-proposal limits, and per-plugin scoped OIDC tokens that are "new infrastructure" by their own admission. The scoped token is the tell: a second trust system, built because the first one wasn't trusted. If the receipt is sound you don't need the token; if it isn't, the token won't save you.

**Kimi's capability grants.** A grant list enforced by the fixed core, on a box where the runner's shell can already do anything the user can. Either enforcement is real — in which case you need actual sandboxing and the grants table is redundant — or it's advisory, in which case the provenance receipt does the same job cheaper. A permission table the enforcer can't enforce is a wish list with a schema.

**The pragmatic version's registry.yaml.** A central registry is a single file whose corruption breaks every plugin at once — the pragmatic version confesses this by specifying "malformed registry → boot with zero plugins," a design admitting its own liability. See §5.

*(For the record: asked to merge three mechanisms into one, MiniMax proposed an "Adaptive Security and Integrity Module" — the exact over-abstraction instinct this page exists to kill. Asked for the weakest assumption, it answered "trust the initial codebase," a tautology in a hi-vis vest. Only the invariant survived: the gunner never builds the gun.)*

## 4. The minimal manifest

One file per plugin, inside the plugin directory. No central registry — the directory listing is the registry.

`plugins/ffmpeg/manifest.json`:
```json
{
  "name": "ffmpeg",
  "why": "cut mp4 for the radio hour",
  "source": "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz",
  "sha256": "<64 hex chars>",
  "second_source": "https://<independent-mirror>/SHA256SUMS",
  "install": "tar xf vendor/pkg.tar.xz -C vendor/",
  "use": "vendor/ffmpeg -i {in} -ss {start} -t {dur} {out}",
  "tests": [
    "vendor/ffmpeg -version | grep -q '7\\.'",
    "cut fixture.mp4 0-10s → out.mp4 exists, duration within 5% of 10s"
  ]
}
```

Fetch, hash, install, use, tests. The receipt is the interface.

## The minimal loop

1. **Want.** Agent writes `needs/<name>.md` — the capability and why.
2. **Gate.** One line: source host in `allowlist.txt` and operation read-only → proceed; else open an issue and wait. The human gate is load-bearing, not a placeholder.
3. **Build.** The fixed assembler (hash-checked at wake) fetches the tarball, verifies the sha256 against *two* independently fetched sources, installs per the manifest, runs the manifest's tests.
4. **Learn.** Tests pass → commit; the loader picks it up next wake. Tests fail → the miss goes into `misses.md` in the plugin dir, two more attempts max, then park it with an issue. The miss is the curriculum.
5. **Run.** Loader walks `plugins/*/manifest.json` at wake. Nothing else.

Total new machinery: a directory walker, a hash check, a gate line. The death cycle handles the rest.

## 5. The cut: the registry file

The synthesis claimed "no registry file" was unanimous — but the pragmatic verbatim kept `plugins/registry.yaml`, holding triggers, grants, hardware requirements, and operator paths. That's the thing I'd cut. A central registry is a single point of corruption that then demands its own defense budget: malformed-registry handling, schema versioning, merge conflicts when two proposals land in the same wake. Every field it holds either lives naturally in the per-plugin manifest (use, tests, install) or was ceremony all along — triggers are the agent reading `why`; hardware requirements are a test like any other ("nproc ≥ 2" belongs in `tests`, not in a schema). Kill the registry and an entire liability class disappears: there is no file whose corruption takes down all equipment at once, because there is no file. The directory is the registry. The manifest is the receipt. That's the whole system.
