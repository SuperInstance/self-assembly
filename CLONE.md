# CLONE.md — fresh box in, tuned agent out

The agent is cloneable to any hardware: a workstation, any Oracle server,
anywhere. The ethos agent is the port — the design is proven on the
reference console, and every clone tunes itself on first boot.

## Manual clone steps

```bash
# 1. land the tree (scp, git clone, whatever carries files)
scp -r <source>:/home/ubuntu/playground/self-assembly /home/ubuntu/playground/self-assembly
cd /home/ubuntu/playground/self-assembly

# 2. the ethos agent probes THIS box and tunes itself
./assembler/ethos/ethos.sh
cat CONSOLE.local.md          # review the tuning — it's your box's identity

# 3. CPU API secret (the box's own; never copy from another box)
openssl rand -hex 32 > ~/.self-assembly-cpu-secret
chmod 600 ~/.self-assembly-cpu-secret

# 4. heartbeat (the agent refuses real work until ethos signed off,
#    so a bad tune fails safe here, not silently)
./assembler/probe-console.sh  # must print CONSOLE-OK
(crontab -l 2>/dev/null; echo "*/15 * * * * /home/ubuntu/playground/self-assembly/wake.sh") | crontab -

# 5. first wake (runs immediately, doesn't wait for cron)
./wake.sh
```

## What the ethos agent does on boot

1. Probes: arch, cores, RAM, disk, GPU presence, network egress.
2. Derives tuning from the reference console (`assembler/ethos/reference.yaml`):
   judge parallelism = cores−1, per-plugin memory = (RAM − reserve)/4,
   binary asset arch, scratch/storage layout, disk floor.
3. Writes `.tuned.yaml` (`tuned: true`, machine-readable) and
   `CONSOLE.local.md` (human-readable). Both committed to git — the box's
   identity is versioned.
4. Creates the storage layout: `scratch/{dl,build,judge,install}`,
   `ledger/archive/`.

If the probe matches the reference exactly, local == reference, zero drama.
If it differs, the tuning differs and the ledger says so.

## Guarantees

- No real work before `tuned: true`. `probe-console.sh` refuses; `wake.sh`
  runs ethos first and halts if it fails.
- Re-tuning: `./assembler/ethos/ethos.sh` re-probes and rewrites the local
  spec. `wake.sh --retune` forces it.
- The reference console (Oracle free tier) stays the development target:
  tune there, port everywhere.
