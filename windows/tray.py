# Claude Code / Codex 사용량 트레이 (Windows)
# 트레이에 아이콘 2개: 주황=Claude Code, 파랑=Codex. 각 아이콘 안에 높은 사용률 숫자.
# 왼쪽 클릭: 웹 화면을 작은 창으로 열기 · 오른쪽 클릭: 메뉴
import json
import os
import subprocess
import sys
import threading
import urllib.request
from http.server import ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
# 소스 실행: 상위 폴더의 server.py / index.html 사용. exe 빌드: 번들 안의 파일 사용.
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, getattr(sys, "_MEIPASS", HERE))

import pystray  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import server  # noqa: E402  (사용량 수집 서버, 같은 프로세스에서 실행)

BASE = f"http://127.0.0.1:{server.PORT}"
NAMES = {"claude": "Claude Code", "codex": "Codex"}
COLORS = {"claude": (201, 100, 66), "codex": (61, 111, 217)}  # 주황 / 파랑
REFRESH_SEC = 60

stop = threading.Event()
wake = threading.Event()
icons = {}
win_proc = None


def start_server():
    """포트가 비어 있으면 이 프로세스에서 서버를 띄운다. 이미 떠 있으면 그대로 사용."""
    try:
        httpd = ThreadingHTTPServer((server.HOST, server.PORT), server.H)
    except OSError:
        return
    threading.Thread(target=httpd.serve_forever, daemon=True).start()


def fetch():
    try:
        with urllib.request.urlopen(BASE + "/api/usage", timeout=15) as r:
            return json.loads(r.read().decode())
    except Exception:
        return None


def load_font(size):
    for name in ("arialbd.ttf", "arial.ttf", "malgunbd.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default(size)


def make_icon(color, label, alert=False):
    """64px 둥근 사각형에 숫자를 그린다. 트레이에서는 자동으로 작게 줄어든다."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fill = color if label != "!" else (120, 120, 120)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=14, fill=fill)
    font = load_font(44 if len(label) <= 2 else 32)
    d.text((size / 2, size / 2 + 2), label, font=font, fill="white", anchor="mm")
    if alert:  # 90% 이상이면 오른쪽 위에 빨간 점
        d.ellipse((size - 20, 2, size - 2, 20), fill=(230, 40, 40), outline="white", width=3)
    return img


def summarize(svc):
    """서비스 하나의 (가장 높은 사용률, 툴팁 문구)를 돌려준다."""
    if not svc:
        return None, "연결 안 됨"
    if not svc.get("ok"):
        return None, f"오류: {svc.get('error', '?')}"
    f = (svc.get("five") or {}).get("pct") or 0
    w = (svc.get("week") or {}).get("pct") or 0
    return max(f, w), f"5시간 {round(f)}% · 1주일 {round(w)}%"


def update(data):
    for key in ("claude", "codex"):
        icon = icons.get(key)
        if icon is None:
            continue
        if data is None:
            icon.icon = make_icon(COLORS[key], "!")
            icon.title = f"{NAMES[key]}  서버 연결 실패"
            continue
        val, text = summarize(data.get(key))
        if val is None:
            icon.icon = make_icon(COLORS[key], "!")
        else:
            icon.icon = make_icon(COLORS[key], str(min(int(round(val)), 99)), alert=val >= 90)
        icon.title = f"{NAMES[key]}  {text}"


def find_browser():
    bases = [os.environ.get("ProgramFiles"), os.environ.get("ProgramFiles(x86)"),
             os.environ.get("LOCALAPPDATA")]
    rel = ["Google/Chrome/Application/chrome.exe", "Microsoft/Edge/Application/msedge.exe"]
    for b in bases:
        if not b:
            continue
        for r in rel:
            p = os.path.join(b, r)
            if os.path.exists(p):
                return p
    return None


def open_window(icon=None, item=None):
    """웹 화면을 주소창 없는 작은 앱 창으로 연다."""
    global win_proc
    if win_proc is not None and win_proc.poll() is None:
        return
    exe = find_browser()
    if exe:
        win_proc = subprocess.Popen([exe, f"--app={BASE}", "--window-size=300,340"])
    else:
        import webbrowser
        webbrowser.open(BASE)


def refresh_now(icon=None, item=None):
    wake.set()


def quit_app(icon=None, item=None):
    stop.set()
    wake.set()


def loop():
    while not stop.is_set():
        update(fetch())
        wake.wait(REFRESH_SEC)
        wake.clear()


def main():
    start_server()
    menu = pystray.Menu(
        pystray.MenuItem("웹 창 열기", open_window, default=True),
        pystray.MenuItem("새로고침", refresh_now),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("종료", quit_app),
    )
    for key in ("claude", "codex"):
        icons[key] = pystray.Icon(key, make_icon(COLORS[key], "…"), NAMES[key], menu=menu)
    for ic in icons.values():
        ic.run_detached()
    threading.Thread(target=loop, daemon=True).start()
    stop.wait()
    for ic in icons.values():
        ic.stop()


if __name__ == "__main__":
    main()
