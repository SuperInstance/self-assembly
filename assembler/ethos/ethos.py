#!/usr/bin/env python3
"""ethos.py — the hardware agent.

Every clone's first act on a new box: probe it, tune itself, sign off.
Deterministic by design — the thing that defines the box must be auditable,
not clever. (A future LLM pass may refine tuning; v1 is rules.)

Usage: ethos.py [--out DIR]   (default: the tree root)
Reads ETHOS_FAKE="arch=..,cores=..,mem_gb=..,disk_gb=..,gpu=..,network=.." for
simulated runs (testing only — never on a real boot).

Writes:
  .tuned.yaml       machine-readable local spec + tuned:true (in git)
  CONSOLE.local.md  human-readable local spec sheet (in git)
Ensures: scratch/{dl,build,judge,install}, ledger/archive/ exist.
Prints: "I'm on X, tuned for Y" summary to stdout.
"""
import os, sys, yaml, shutil, socket, datetime

def parse_args():
    out = None
    for i, a in enumerate(sys.argv[1:]):
        if a == "--out" and i + 2 <= len(sys.argv[1:]):
            out = sys.argv[1:][i + 1]
    return out

ROOT = parse_args() or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ETHOS_DIR = os.path.dirname(os.path.abspath(__file__))
REF = yaml.safe_load(open(os.path.join(ETHOS_DIR, "reference.yaml")))

def probe_real():
    import subprocess
    arch = os.uname().machine
    cores = os.cpu_count() or 1
    mem_kb = int(open("/proc/meminfo").read().split("MemTotal:")[1].split()[0])
    mem_gb = round(mem_kb / 1024 / 1024)
    disk_gb = round(shutil.disk_usage("/").total / 1024**3)
    gpu = "present" if (os.path.exists("/dev/nvidia0") or
                        shutil.which("nvidia-smi")) else "absent"
    try:
        socket.create_connection(("github.com", 443), timeout=8).close()
        network = "direct"
    except Exception:
        network = "none"
    return dict(arch=arch, cores=cores, mem_gb=mem_gb, disk_gb=disk_gb,
                gpu=gpu, network=network)

def probe():
    fake = os.environ.get("ETHOS_FAKE", "")
    if not fake:
        return probe_real(), False
    d = {}
    for kv in fake.split(","):
        k, v = kv.split("=", 1)
        d[k.strip()] = v.strip()
    base = probe_real()
    for k in ("arch", "gpu", "network"):
        if k in d:
            base[k] = d[k]
    for k in ("cores", "mem_gb", "disk_gb"):
        if k in d:
            base[k] = int(d[k])
    return base, True

def asset_arch(arch):
    return {"aarch64": "arm64", "arm64": "arm64",
            "x86_64": "amd64"}.get(arch, "unknown")

def tune(p):
    cores = p["cores"]; mem = p["mem_gb"]; disk = p["disk_gb"]
    reserve = max(1, round(mem * 0.13))
    return dict(
        judge_parallelism=max(1, cores - 1),
        reserve_gb=reserve,
        plugin_mem_gb=max(1, (mem - reserve) // 4),
        install_mem_gb=max(2, (mem - reserve) // 2),
        disk_floor_gb=max(5, int(disk * 0.2)),
        scratch_max_gb=max(1, int(disk * 0.1)),
        asset_arch=asset_arch(p["arch"]),
    )

def main():
    probed, simulated = probe()
    t = tune(probed)
    ref_match = all(probed.get(k) == REF.get(k)
                    for k in ("arch", "cores", "mem_gb"))
    spec = dict(tuned=True,
                probed_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                simulated=simulated,
                arch=probed["arch"], cores=probed["cores"], mem_gb=probed["mem_gb"],
                disk_gb=probed["disk_gb"], gpu=probed["gpu"], network=probed["network"],
                reference_match=ref_match, **t)
    with open(os.path.join(ROOT, ".tuned.yaml"), "w") as f:
        yaml.safe_dump(spec, f, sort_keys=False)

    for sub in ("scratch/dl", "scratch/build", "scratch/judge", "scratch/install",
                "ledger/archive"):
        os.makedirs(os.path.join(ROOT, sub), exist_ok=True)

    delta = "matches the reference console exactly — zero drama" if ref_match else \
        "DIFFERS from reference: " + ", ".join(
            f"{k}={probed[k]}(ref {REF[k]})" for k in ("arch", "cores", "mem_gb")
            if probed.get(k) != REF.get(k))
    md = f"""# CONSOLE.local.md — this box, as tuned by the ethos agent
<!-- Derived from the reference console (assembler/ethos/reference.yaml).
     Do not hand-edit: re-run assembler/ethos/ethos.sh to re-probe. -->
- probed_at: {spec['probed_at']}{' (SIMULATED)' if simulated else ''}
- arch: {probed['arch']} (asset selector: {t['asset_arch']})
- cores: {probed['cores']} → judge parallelism: {t['judge_parallelism']}
- RAM: {probed['mem_gb']} GB (reserve {t['reserve_gb']} GB) → per-plugin ≤ {t['plugin_mem_gb']} GB, install ≤ {t['install_mem_gb']} GB
- disk: {probed['disk_gb']} GB → floor {t['disk_floor_gb']} GB, scratch ≤ {t['scratch_max_gb']} GB
- gpu: {probed['gpu']} | network egress: {probed['network']}
- reference: {delta}
- tuned: true
"""
    with open(os.path.join(ROOT, "CONSOLE.local.md"), "w") as f:
        f.write(md)

    print(f"ethos: I'm on {probed['arch']}/{probed['cores']} cores/{probed['mem_gb']}GB"
          f" (gpu {probed['gpu']}, net {probed['network']}), "
          f"tuned for judge_parallelism={t['judge_parallelism']}, "
          f"plugin_mem={t['plugin_mem_gb']}GB, asset_arch={t['asset_arch']}. "
          f"Reference match: {ref_match}.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
