#!/usr/bin/env python3
"""think.py — the CPU's think function. Imported by cpu-api.py.

v1 contract:
  think(event) -> {"thinking": str, "actions": [action...], "done": bool}

The thinker is deliberately narrow in v1:
  1. Validate + ledger the event (never crash on malformed input).
  2. Match event text against plugins' `when` trigger lines using keyword
     overlap (documented v1 heuristic; LLM semantic routing is future work).
  3. On match: run the plugin driver LOCALLY on the console (120 s leash,
     scrubbed env) and fold its output into a runner-side action plan.
  4. On no match: if the event looks like an equipment desire, file a
     needs/<name>.yaml stub and tell the runner to say so. Else no-op.

Runner-side action vocabulary (executed later by the slimmed GitHub
workflows — documented here, not implemented here):
  {"tool": "comment_issue", "args": {"issue": N, "body": "..."}}
  {"tool": "create_issue",  "args": {"title": "...", "body": "..."}}
  {"tool": "no-op",          "args": {}}
"""
import os, re, json, subprocess, datetime
import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STOP = set("a an the is are was were be been to of in on for with and or i you he she it we they this that these those my your his her its our their me him us them what when where which who how can could should would do does did not no yes please thanks thank".split())

def ledger(msg):
    line = f"## {datetime.datetime.now(datetime.timezone.utc).isoformat()} — cpu: {msg}\n"
    with open(os.path.join(ROOT, "LEDGER.md"), "a") as f:
        f.write(line)

def load_plugins():
    """Walk plugins/*/manifest.yaml. Malformed manifests are skipped + ledgered, never fatal."""
    plugins = []
    pdir = os.path.join(ROOT, "plugins")
    if not os.path.isdir(pdir):
        return plugins
    for name in sorted(os.listdir(pdir)):
        mp = os.path.join(pdir, name, "manifest.yaml")
        if not os.path.isfile(mp):
            continue
        try:
            m = yaml.safe_load(open(mp))
            assert isinstance(m, dict) and m.get("name") == name and m.get("when"), "schema"
            m["_dir"] = os.path.join(pdir, name)
            plugins.append(m)
        except Exception as e:
            ledger(f"plugin '{name}' skipped: malformed manifest ({e})")
    return plugins

def keywords(s):
    return set(w for w in re.findall(r"[a-z0-9]+", s.lower()) if w not in STOP and len(w) > 2)

def match_plugin(text, plugins):
    """Keyword overlap against `when` lines. Returns (plugin, score) or (None, 0)."""
    tk = keywords(text)
    best, best_score = None, 0
    for p in plugins:
        wk = keywords(p.get("when", ""))
        score = len(tk & wk)
        if score > best_score:
            best, best_score = p, score
    return (best, best_score) if best_score >= 2 else (None, 0)

def scrubbed_env():
    env = {k: v for k, v in os.environ.items()
           if not any(t in k.upper() for t in ("TOKEN", "SECRET", "KEY", "VAULT", "GH_", "AWS_", "PASSWORD"))}
    env["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    return env

def run_plugin(plugin, args):
    drv = os.path.join(plugin["_dir"], "driver.sh")
    try:
        r = subprocess.run([drv] + list(args), capture_output=True, text=True,
                           timeout=120, env=scrubbed_env(), cwd=plugin["_dir"])
        return r.returncode, (r.stdout or "")[:4000], (r.stderr or "")[:1000]
    except subprocess.TimeoutExpired:
        return 124, "", "timeout after 120s"
    except Exception as e:
        return 125, "", f"exec failed: {e}"

def looks_like_desire(text):
    t = text.lower()
    return any(k in t for k in ("i need", "grow:", "we need", "add support for", "can you", "please add"))

def desire_name(text):
    ws = keywords(text)
    return "-".join(sorted(ws)[:3]) or "unnamed"

def think(event):
    etype = event.get("type", "?")
    payload = event.get("payload", {}) or {}
    text = f"{payload.get('title','')} {payload.get('body','')}".strip()
    issue = (event.get("reply_to") or {}).get("issue")
    ledger(f"event type={etype} issue={issue} len={len(text)}")

    plugins = load_plugins()
    plugin, score = match_plugin(text, plugins)
    if plugin:
        args = payload.get("suggest_args", []) or []
        rc, out, err = run_plugin(plugin, args)
        ledger(f"plugin '{plugin['name']}' ran rc={rc} score={score}")
        if rc == 0:
            body = f"Ran `{plugin['name']}` ({plugin.get('when','')}):\n\n```\n{out.strip()}\n```"
        else:
            body = (f"`{plugin['name']}` failed (rc={rc}).\n\n```\n{err.strip()}\n```\n"
                    f"Logged to the console ledger for review.")
        actions = ([{"tool": "comment_issue", "args": {"issue": issue, "body": body}}]
                   if issue is not None else [{"tool": "no-op", "args": {}}])
        return {"thinking": f"matched plugin '{plugin['name']}' (keyword score {score}); rc={rc}",
                "actions": actions, "done": True}

    if looks_like_desire(text):
        name = desire_name(text)
        stub = os.path.join(ROOT, "needs", f"{name}.yaml")
        if not os.path.exists(stub):
            with open(stub, "w") as f:
                f.write(f"name: {name}\ndesire: {text[:200]!r}\nwhen: \"\"\n"
                        f"source:\n  type: none\n  url: \"\"\n  pin: \"\"\n  sha256: \"\"\n"
                        f"verify:\n  second_source: \"\"\ndriver:\n  command: \"\"\n"
                        f"probe: []\ntests: []\n# STUB filed by cpu thinker — spec needs human or future-loop fill\n")
            ledger(f"desire filed as needs/{name}.yaml (stub, needs spec)")
        body = (f"No registered equipment matches. I've logged this as an equipment "
                f"desire (`needs/{name}.yaml`) — it needs a spec before the assembler can grow it.")
        actions = ([{"tool": "comment_issue", "args": {"issue": issue, "body": body}}]
                   if issue is not None else [{"tool": "no-op", "args": {}}])
        return {"thinking": f"no plugin match; filed desire stub needs/{name}.yaml",
                "actions": actions, "done": True}

    ledger("no match, no desire — no-op")
    return {"thinking": "no plugin matched and no equipment desire detected",
            "actions": [{"tool": "no-op", "args": {}}], "done": True}
