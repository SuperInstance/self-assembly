# plugins/ — the registry is the listing

There is no index file. No `plugins.yaml`, no registry JSON. A plugin is
registered by existing as `plugins/<name>/manifest.yaml`. The wake loop
walks the directory at every wake. A single index file is a corruption
target and a merge-conflict generator; a directory listing is neither.
(Unanimous across all three architects.)

```
plugins/
  <name>/
    manifest.yaml    # the lock: name, when, source pin+hash, grants, inner_agents
    driver.sh        # sole entrypoint: driver.sh [args...]; the capability
    probe.sh         # health checks (run every wake); exit 0 = healthy
    test.sh          # acceptance tests (run at assembly); exit 0 = accepted
    cases/           # committed test fixtures (small)
    bin/             # installed binaries (ON DISK ONLY, gitignored, never committed)
    ledger/          # per-plugin run log (append-only, in git)
    JUDGE.md         # grown judge prompt, if any (see JUDGE-NOTES.md scar tissue)
    JUDGE-NOTES.md   # test misses folded into the judge spec during build
    BUILD.jsonl      # append-only build ledger (round, sha, failures, change, why)
```

Malformed manifests never break the boot: the plugin is skipped, the skip
is ledgered, and the wake continues. (MiniMax's rule, kept.)
