#!/usr/bin/env python3
"""cpu-api.py — the Oracle CPU's event API. stdlib only.

The GitHub runner (Track A senses/hands) POSTs events here; the CPU thinks
and returns an action plan. The runner executes GitHub-side effects with its
own token. Trust split: the runner never sees vault secrets; Oracle never
holds GitHub tokens.

Endpoints (all require auth except nothing — everything is authenticated):
  POST /event   {source, type, id, payload, reply_to} -> {thinking, actions, done}
  GET  /health  -> {"status": "ok", "plugins": [...]}

Auth: Authorization: Bearer <secret>, constant-time compare. The secret lives
in ~/.self-assembly-cpu-secret (mode 600), read once at startup, never logged.

v1 deployment note: binds 127.0.0.1:8777 (localhost only). The CPU path is
proven via local POST in the proof ritual. Reaching it from GitHub-hosted
runners (public ingress with TLS, or a tunnel, or inverted polling) is a
named open item — see DEBT.md #5. Do NOT bind 0.0.0.0 without TLS: the
bearer token would cross the wire in cleartext.

The server never crashes on bad input: malformed JSON -> 400, bad auth ->
401, unknown path -> 404, unexpected exception -> 500 JSON (logged).
"""
import json, hmac, os, sys, traceback
from http.server import BaseHTTPRequestHandler, HTTPServer

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from think import think, load_plugins, ledger

SECRET_FILE = os.path.expanduser("~/.self-assembly-cpu-secret")
PORT = 8777

def load_secret():
    try:
        with open(SECRET_FILE) as f:
            s = f.read().strip()
        assert len(s) >= 32, "secret too short"
        return s.encode()
    except Exception as e:
        print(f"FATAL: cannot read secret at {SECRET_FILE}: {e}", file=sys.stderr)
        sys.exit(1)

SECRET = load_secret()

class Handler(BaseHTTPRequestHandler):
    server_version = "SelfAssemblyCPU/0.1"

    def log_message(self, fmt, *args):
        sys.stderr.write(f"cpu-api: {self.address_string()} {fmt % args}\n")

    def _authed(self):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return False
        return hmac.compare_digest(auth[7:].encode(), SECRET)

    def _send(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _require_auth(self):
        if not self._authed():
            self._send(401, {"error": "unauthorized"})
            return False
        return True

    def do_GET(self):
        try:
            if self.path == "/health":
                if not self._require_auth():
                    return
                self._send(200, {"status": "ok",
                                 "plugins": [p["name"] for p in load_plugins()]})
            else:
                self._send(404, {"error": "not found"})
        except Exception as e:
            traceback.print_exc()
            self._send(500, {"error": "internal"})

    def do_POST(self):
        try:
            if self.path != "/event":
                self._send(404, {"error": "not found"})
                return
            if not self._require_auth():
                return
            try:
                length = int(self.headers.get("Content-Length", 0))
            except ValueError:
                length = 0
            if length <= 0 or length > 1_000_000:
                self._send(400, {"error": "bad body"})
                return
            try:
                event = json.loads(self.rfile.read(length))
            except Exception:
                self._send(400, {"error": "malformed json"})
                return
            if not isinstance(event, dict) or "type" not in event:
                self._send(400, {"error": "event must be an object with a 'type'"})
                return
            plan = think(event)
            self._send(200, plan)
        except Exception:
            traceback.print_exc()
            try:
                self._send(500, {"error": "internal"})
            except Exception:
                pass

if __name__ == "__main__":
    ledger("cpu-api starting on 127.0.0.1:8777")
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
