# needs/ — where desires land

A desire is a YAML file: `needs/<name>.yaml`. The wake loop picks up the
oldest unprocessed desire (max 1 assembly per wake, max 3 concurrent) and
the assembler grows it into `plugins/<name>/` — or rejects it with a reason
committed to `needs/rejected/`.

## Proposal format

```yaml
name: disk-report
desire: "Report disk usage for any path"
when: "report disk usage of a path"      # one-line trigger (goes in manifest)
source:
  type: none                             # none | tarball | git
  url: ""
  pin: ""                                # full commit SHA (git) or release tag (tarball)
  sha256: ""                             # 64 hex of the fetched artifact
verify:
  second_source: ""                      # independent URL confirming pin+hash,
                                         # or "human:<who>:<date>:<note>"
driver:
  command: "df -h"                       # argv from the caller is appended
  path_extra: ""                         # dir prepended to PATH (e.g. bin/)
probe:                                   # health checks, run every wake
  - args: "/"
    expect_contains: "Filesystem"
    timeout_s: 10
tests:                                   # acceptance tests, run at assembly
  - name: "root fs listed"
    args: "/"
    expect_contains: "/dev/"
```

## Lifecycle

- `needs/<name>.yaml` — proposed, awaiting assembly.
- `needs/<name>.yaml.building` — assembly in progress (marker, gitignored).
- `needs/done/<name>.yaml` — assembled and registered; the proposal that worked.
- `needs/rejected/<name>.yaml` — rejected, with `rejected_reason:` and
  `rejected_at:` appended. Rejections stay in git: knowing what didn't work
  is intelligence.

The assembler never edits a proposal in place. It reads it, acts, and files
it under `done/` or `rejected/`.
