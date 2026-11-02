#!/bin/zsh
# 서버를 백그라운드로 띄우고 작은 앱 창으로 엽니다.
DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=${USAGE_PORT:-8787}
if ! curl -s -o /dev/null "http://127.0.0.1:$PORT/"; then
  nohup python3 "$DIR/server.py" >/dev/null 2>&1 &
  sleep 1
fi
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [[ -x "$CHROME" ]]; then
  "$CHROME" --app="http://127.0.0.1:$PORT" --window-size=300,330 >/dev/null 2>&1 &
else
  open "http://127.0.0.1:$PORT"
fi
