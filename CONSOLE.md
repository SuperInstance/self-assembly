# CONSOLE.md — the REFERENCE console spec sheet

> **Reference vs local.** This file is the *reference*: the Oracle free-tier
> box everything is designed for. It never changes. The ethos agent
> (`assembler/ethos/`) derives the *local* spec for the actual box and writes
> it to `CONSOLE.local.md` + `.tuned.yaml` on first boot. If the probe
> matches this reference exactly, local == reference, zero drama.

This is not a compatibility matrix. It is a console spec sheet.
Everything in this tree assumes EXACTLY this machine. If
`assembler/probe-console.sh` fails, the wake loop halts. We do not adapt;
we verify. (Like building a video game for one console: no sliders, no
"hope your graphics card keeps up." The playtesters live on the same box
the agent runs on.)

- Model: Oracle Cloud Infrastructure, Ampere A1 (free tier, perpetual)
- CPU: 4x ARM Neoverse-N1 (`aarch64`), 4 cores
- RAM: 23 GB total (~20 GB available after system)
- Disk: 45 GB root (`/dev/sda1`), ~20 GB free at scaffold time
- OS: Ubuntu 26.04 LTS (kernel 7.0.0-1013-oracle)
- Network: direct egress (no proxy required on-box)
- Host: ubuntu@147.224.38.131 (us-sanjose-1)

## Budgets (hardcoded, not discovered)

| Resource | Total | Reserved (system + crabs) | Per-plugin / per-wake max |
|---|---|---|---|
| CPU | 4 cores | 1 core | 3 parallel workers max across assembly + judge work |
| RAM | 23 GB | 3 GB | install+build ≤ 2 GB; single op runtime ≤ 1 GB |
| Disk (scratch) | ~20 GB free | 10 GB floor (never go below) | all plugins' scratch ≤ 5 GB total |
| Judge calls | — | — | sequential, 60 s timeout each, ≤ 3 per wake |
| Assembly | — | — | ≤ 1 proposal per wake, ≤ 3 concurrent, ≤ 5 test iterations each |
| Shell leash | — | — | every plugin/install invocation: 120 s timeout, scrubbed env (no secrets) |

## Binary selection

- `aarch64` only. The assembler refuses any fetched asset whose name does not
  indicate ARM64/aarch64, unless the manifest's `arch` field says otherwise
  and a human attested it. There is no x86_64 on this console. There will
  never be.

## Console adaptation of the synthesis (documented deviations)

The synthesis was written for ephemeral GitHub Actions runners. The console
is persistent disk, so two rules adapt:

1. **"Binaries never in git"** means: installed plugin binaries live on disk
   under `plugins/<name>/bin/` (gitignored), NOT committed. Each wake
   re-verifies presence + `--version`/hash; on drift or absence the assembler
   re-runs install. Pin + verify, reinstall on drift — same trust, less waste.
2. **"Reinstall every wake"** becomes **"re-verify every wake."** The
   provenance check (pin + sha256 + dual-source) ran at assembly time and is
   recorded in the manifest; the per-wake probe confirms the installed bits
   still match. A changed body fails probes and triggers repair (Claude's
   rule, kept).
