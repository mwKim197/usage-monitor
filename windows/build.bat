@echo off
rem Windows용 UsageMonitor.exe 빌드 (Python 3.10 이상 필요)
rem 결과: windows\dist\UsageMonitor.exe  (더블클릭하면 트레이에 아이콘 2개가 뜸)
cd /d "%~dp0"

python -m pip install --upgrade pystray pillow pyinstaller
if errorlevel 1 goto :fail

python -m PyInstaller --noconsole --onefile --name UsageMonitor ^
  --paths .. --add-data "..\index.html;." tray.py
if errorlevel 1 goto :fail

echo.
echo 완료: %cd%\dist\UsageMonitor.exe
pause
exit /b 0

:fail
echo.
echo 빌드 실패. 위 오류 메시지를 확인하세요.
pause
exit /b 1
