# VENDOR-NOTE — what was excluded from this public push and why

The running operator in `plugins/media-trim/` originally shipped with a
vendored static ffmpeg (`vendor/`, ~500MB of binaries, docs, and man
pages). It is excluded from this public push for size, not secrecy —
nothing in it is private.

To reconstitute the running operator exactly as the loop built it:

1. Fetch the tarball pinned in `plugins/media-trim/manifest.json`
   (`source` + `sha256`).
2. Confirm the pin against the second source listed in the manifest
   (dual-source rule — this is the loop's provenance law, not paranoia).
3. Extract into `plugins/media-trim/vendor/` and run
   `./fixture.sh && ./trim.sh fixture.mp4 2 4 cut.mp4`.

Also excluded: `poc/experiments/` (red-team fixtures, canary tokens, and
network-cut experiment material — controlled attack artefacts, kept
private), the loop's `.gitignore`, and scratch logs. The inert-payload
proof of the hardened gate (`scratch/proof-inert/`) is included: every
payload there is inert text in JSON, rejected before execution, by
construction.
