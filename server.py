#!/usr/bin/env python3
"""Claude Code / Codex 사용량 모니터 (로컬 전용, 외부 의존성 없음).

실행:  python3 ~/usage-monitor/server.py   → http://127.0.0.1:8787
"""
import json
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST, PORT = "127.0.0.1", int(os.environ.get("USAGE_PORT", "8787"))
CACHE_SEC = 60
HERE = os.path.dirname(os.path.abspath(__file__))

_cache = {"t": 0, "data": None}
_lock = threading.Lock()


def _get(url, headers):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read().decode())


def _iso_to_epoch(s):
    return datetime.fromisoformat(s).timestamp() if s else None


def fetch_claude():
    try:
        raw = ""
        if sys.platform == "darwin":  # Mac: 키체인에 저장됨
            raw = subprocess.run(
                ["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
                capture_output=True, text=True, timeout=5,
            ).stdout
        if not raw.strip():  # Windows 및 키체인 실패 시: 파일에서 읽기
            with open(os.path.expanduser("~/.claude/.credentials.json")) as f:
                raw = f.read()
        token = json.loads(raw)["claudeAiOauth"]["accessToken"]
        d = _get("https://api.anthropic.com/api/oauth/usage", {
            "Authorization": "Bearer " + token,
            "anthropic-beta": "oauth-2025-04-20",
        })
        def win(k):
            w = d.get(k) or {}
            if not w:
                return None
            return {"pct": w.get("utilization") or 0, "reset_at": _iso_to_epoch(w.get("resets_at"))}
        return {"ok": True, "five": win("five_hour"), "week": win("seven_day")}
    except urllib.error.HTTPError as e:
        hint = " (토큰 만료: claude 를 한 번 실행하세요)" if e.code == 401 else ""
        return {"ok": False, "error": f"HTTP {e.code}{hint}"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def fetch_codex():
    try:
        a = json.load(open(os.path.expanduser("~/.codex/auth.json")))
        t = a.get("tokens") or {}
        d = _get("https://chatgpt.com/backend-api/wham/usage", {
            "Authorization": "Bearer " + t.get("access_token", ""),
            "ChatGPT-Account-Id": t.get("account_id", ""),
            "User-Agent": "codex-cli",
        })
        rl = d.get("rate_limit") or {}
        def win(k):
            w = rl.get(k)
            if not w:
                return None
            return {"pct": w.get("used_percent") or 0, "reset_at": w.get("reset_at")}
        return {"ok": True, "plan": d.get("plan_type"),
                "five": win("primary_window"), "week": win("secondary_window")}
    except urllib.error.HTTPError as e:
        hint = " (토큰 만료: codex 를 한 번 실행하세요)" if e.code == 401 else ""
        return {"ok": False, "error": f"HTTP {e.code}{hint}"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def get_usage(force=False):
    with _lock:
        if force or not _cache["data"] or time.time() - _cache["t"] > CACHE_SEC:
            _cache["data"] = {"claude": fetch_claude(), "codex": fetch_codex(), "fetched_at": time.time()}
            _cache["t"] = time.time()
        return _cache["data"]


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype):
        b = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        if self.path.startswith("/api/usage"):
            self._send(200, json.dumps(get_usage("force=1" in self.path)), "application/json")
        elif self.path in ("/", "/index.html"):
            self._send(200, open(os.path.join(HERE, "index.html"), "rb").read(), "text/html; charset=utf-8")
        else:
            self._send(404, "not found", "text/plain")


if __name__ == "__main__":
    print(f"Usage monitor → http://{HOST}:{PORT}")
    ThreadingHTTPServer((HOST, PORT), H).serve_forever()
