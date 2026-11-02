# Usage Monitor · 사용량 모니터

Claude Code와 Codex의 **5시간 / 1주일 사용량**을 한눈에 보는 작은 도구입니다.
Mac은 메뉴바, Windows는 트레이에 표시됩니다.

- Mac: 메뉴바에 `C 4% · X 96%`처럼 표시 (높은 사용률 기준)
- Windows: 트레이에 주황(Claude Code)·파랑(Codex) 아이콘 2개, 안에 숫자 표시
- 아이콘을 클릭하면 사용량 화면이 작은 창으로 열립니다.

---

## 한국어

### 준비
- `claude`(Claude Code)와 `codex`에 **로그인**되어 있어야 합니다.
  - Mac: Claude 로그인 정보는 키체인에서 읽습니다.
  - Windows: `%USERPROFILE%\.claude\.credentials.json`에서 읽습니다.
  - Codex: `~/.codex/auth.json`에서 읽습니다. (Windows는 `%USERPROFILE%\.codex\auth.json`)
- 로그인 정보는 조회에만 쓰고 저장하거나 밖으로 보내지 않습니다.

### Mac
```sh
git clone https://github.com/mwKim197/usage-monitor.git
cd usage-monitor
zsh mac/build.sh          # UsageMonitor.app 생성
open UsageMonitor.app     # 메뉴바에 표시됨
```
- 왼쪽 클릭: 사용량 화면 열기 / 오른쪽 클릭: 새로고침·종료 메뉴
- 로그인 시 자동 실행: 시스템 설정 > 일반 > 로그인 항목에 `UsageMonitor.app` 추가
- 서버만 따로 실행하려면 `zsh start.sh` (주소: http://127.0.0.1:8787)

### Windows
1. [Python 3.10 이상](https://www.python.org/downloads/)을 설치합니다. 설치 화면에서 **"Add python.exe to PATH"** 를 체크하세요.
2. `windows\build.bat`를 더블클릭합니다.
3. 완료되면 `windows\dist\UsageMonitor.exe`를 실행합니다.
4. 트레이(작업표시줄 오른쪽 `^` 안)에 아이콘 2개가 뜹니다.

서명되지 않은 실행 파일이라 SmartScreen 경고가 뜰 수 있습니다. "추가 정보 > 실행"을 누르면 됩니다.

### 파일 구성
| 파일 | 설명 |
|---|---|
| `server.py` | 사용량 수집 서버 (127.0.0.1:8787) |
| `index.html` | 사용량 화면 |
| `mac/UsageMonitor.swift`, `mac/build.sh` | Mac 메뉴바 앱 |
| `windows/tray.py`, `windows/build.bat` | Windows 트레이 앱 |
| `start.sh` | Mac에서 서버 + 창 실행 |

### 주의
- 사용량은 Anthropic과 OpenAI의 **내부 조회 API**로 가져옵니다. 공식 문서에 없어서 서비스가 바뀌면 동작하지 않을 수 있습니다.
- 토큰이 만료되면 `claude` 또는 `codex`를 한 번 실행해 다시 로그인하세요.

---

## English

### Requirements
- You must be **logged in** to `claude` (Claude Code) and `codex`.
  - macOS: Claude credentials are read from the Keychain.
  - Windows: Claude credentials are read from `%USERPROFILE%\.claude\.credentials.json`.
  - Codex: read from `~/.codex/auth.json` (Windows: `%USERPROFILE%\.codex\auth.json`).
- Credentials are only used to query usage. They are never stored or sent elsewhere.

### macOS
```sh
git clone https://github.com/mwKim197/usage-monitor.git
cd usage-monitor
zsh mac/build.sh          # builds UsageMonitor.app
open UsageMonitor.app     # shows up in the menu bar
```
- Left-click: open the usage view / Right-click: refresh or quit
- Launch at login: add `UsageMonitor.app` under System Settings > General > Login Items
- To run only the server: `zsh start.sh` (http://127.0.0.1:8787)

### Windows
1. Install [Python 3.10+](https://www.python.org/downloads/). Check **"Add python.exe to PATH"** during setup.
2. Double-click `windows\build.bat`.
3. Run `windows\dist\UsageMonitor.exe` when the build finishes.
4. Two icons appear in the tray (under the `^` arrow in the taskbar).

The executable is unsigned, so SmartScreen may warn you. Click "More info > Run anyway".

### Files
| File | Description |
|---|---|
| `server.py` | Usage collection server (127.0.0.1:8787) |
| `index.html` | Usage view |
| `mac/UsageMonitor.swift`, `mac/build.sh` | macOS menu bar app |
| `windows/tray.py`, `windows/build.bat` | Windows tray app |
| `start.sh` | Starts the server and window on macOS |

### Notes
- Usage is fetched from **internal endpoints** of Anthropic and OpenAI. They are not officially documented, so this may stop working if those services change.
- If a token expires, run `claude` or `codex` once to log in again.
