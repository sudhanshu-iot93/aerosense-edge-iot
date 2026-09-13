@echo off
REM ============================================================
REM  AeroSense Edge — One-Click Launch Script (Windows)
REM  Starts the Edge Core Daemon on port 8090
REM ============================================================

echo.
echo  AeroSense Edge AI v1.2.0
echo  Arduino UNO Q ^| Qualcomm QRB2210 + STM32U585
echo  =====================================================
echo.

REM Navigate to project root (folder containing this script)
cd /d "%~dp0"

REM Check Python is available
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] Python not found in PATH.
    echo  Please install Python 3.9+ from https://python.org
    pause
    exit /b 1
)

REM Install dependencies if needed (optional: comment out for offline use)
REM pip install -r requirements.txt --quiet

REM Launch the daemon
echo  Starting Edge Daemon on http://localhost:8090 ...
echo  Press Ctrl+C to stop.
echo.
python edge_core\app.py 8090
pause
