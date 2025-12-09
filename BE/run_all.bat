@echo off
echo ============================================
echo  Starting Backend Server and ngrok
echo ============================================
echo.

REM Check if venv exists
if not exist "venv" (
    echo ERROR: Virtual environment not found!
    echo Please run complete_setup.bat first.
    echo.
    pause
    exit /b 1
)

REM Find ngrok
set NGROK_CMD=
where ngrok >nul 2>&1
if %errorlevel% equ 0 (
    set NGROK_CMD=ngrok
) else (
    if exist "D:\ngrok\ngrok.exe" (
        set NGROK_CMD=D:\ngrok\ngrok.exe
    ) else if exist "%LOCALAPPDATA%\ngrok\ngrok.exe" (
        set NGROK_CMD=%LOCALAPPDATA%\ngrok\ngrok.exe
    ) else if exist "%USERPROFILE%\ngrok\ngrok.exe" (
        set NGROK_CMD=%USERPROFILE%\ngrok\ngrok.exe
    ) else if exist "C:\ngrok\ngrok.exe" (
        set NGROK_CMD=C:\ngrok\ngrok.exe
    ) else (
        echo ERROR: ngrok not found!
        echo Please run complete_setup.bat first to verify ngrok installation.
        echo.
        pause
        exit /b 1
    )
)

REM Start the server in a new window
echo Starting FastAPI server...
start "Face Recognition API Server" cmd /k "cd /d %CD% && call venv\Scripts\activate.bat && python app.py"

REM Wait a bit for server to start
timeout /t 3 /nobreak >nul

REM Start ngrok in a new window
echo Starting ngrok tunnel...
start "ngrok Tunnel" cmd /k "%NGROK_CMD% http 5000"

echo.
echo ============================================
echo  Both services started!
echo ============================================
echo.
echo Check the opened windows:
echo   - Server window: API running on http://localhost:5000
echo   - ngrok window:  Public URL (look for "Forwarding")
echo.
echo Update the Flutter app with the ngrok URL from the ngrok window.
echo.
echo To stop: Close both windows
echo ============================================
