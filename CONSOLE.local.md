# CONSOLE.local.md — this box, as tuned by the ethos agent
<!-- Derived from the reference console (assembler/ethos/reference.yaml).
     Do not hand-edit: re-run assembler/ethos/ethos.sh to re-probe. -->
- probed_at: 2026-10-06T02:24:36.978448+00:00
- arch: aarch64 (asset selector: arm64)
- cores: 4 → judge parallelism: 3
- RAM: 23 GB (reserve 3 GB) → per-plugin ≤ 5 GB, install ≤ 10 GB
- disk: 45 GB → floor 9 GB, scratch ≤ 4 GB
- gpu: absent | network egress: direct
- reference: matches the reference console exactly — zero drama
- tuned: true
