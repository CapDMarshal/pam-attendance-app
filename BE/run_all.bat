@echo off
echo ============================================
echo  Face Recognition API - Starting Services
echo ============================================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Activate virtual environment
if exist "venv\Scripts\activate.bat" (
    echo [1/4] Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo WARNING: Virtual environment not found!
    echo Using global Python installation.
    echo.
)

REM Check Python and dependencies
echo [2/4] Checking Python environment...
python --version 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Python not found!
    echo Please install Python or activate the virtual environment.
    pause
    exit /b 1
)

REM Check if facenet_model.py exists
if not exist "facenet_model.py" (
    echo ERROR: facenet_model.py not found!
    echo Please ensure FaceNet migration is complete.
    pause
    exit /b 1
)

REM Find ngrok
echo [3/4] Finding ngrok...
set NGROK_CMD=
where ngrok >nul 2>&1
if %errorlevel% equ 0 (
    set NGROK_CMD=ngrok
    echo Found: ngrok in PATH
) else (
    if exist "D:\ngrok\ngrok.exe" (
        set NGROK_CMD=D:\ngrok\ngrok.exe
        echo Found: D:\ngrok\ngrok.exe
    ) else if exist "%LOCALAPPDATA%\ngrok\ngrok.exe" (
        set NGROK_CMD=%LOCALAPPDATA%\ngrok\ngrok.exe
        echo Found: %LOCALAPPDATA%\ngrok\ngrok.exe
    ) else if exist "%USERPROFILE%\ngrok\ngrok.exe" (
        set NGROK_CMD=%USERPROFILE%\ngrok\ngrok.exe
        echo Found: %USERPROFILE%\ngrok\ngrok.exe
    ) else if exist "C:\ngrok\ngrok.exe" (
        set NGROK_CMD=C:\ngrok\ngrok.exe
        echo Found: C:\ngrok\ngrok.exe
    ) else (
        echo WARNING: ngrok not found!
        echo Server will start but ngrok tunnel won't be available.
        echo To install ngrok, visit: https://ngrok.com/download
        echo.
        set NGROK_CMD=
    )
)

echo.
echo [4/4] Starting services...
echo.

REM Start the server in a new window (no venv activation needed, already activated)
echo Starting FastAPI server on http://localhost:5000...
start "Face Recognition API - FaceNet v3.0" cmd /k "cd /d %CD% && python app.py"

REM Wait for server to start
echo Waiting 5 seconds for server to initialize...
timeout /t 5 /nobreak >nul

REM Start ngrok if available
if defined NGROK_CMD (
    echo Starting ngrok tunnel...
    start "ngrok Tunnel - Port 5000" cmd /k "%NGROK_CMD% http --url=hypocycloidal-intensely-raven.ngrok-free.dev 5000"
    echo.
    echo ============================================
    echo  Services Started Successfully!
    echo ============================================
    echo.
    echo [Server Window] - Face Recognition API
    echo   Local:  http://localhost:5000
    echo   Docs:   http://localhost:5000/docs
    echo.
    echo [ngrok Window] - Public Tunnel
    echo   Look for "Forwarding" line with public URL
    echo   Example: https://xxxx-xx-xx-xx-xx.ngrok-free.app
    echo.
    echo NEXT STEPS:
    echo 1. Check the server window for any errors
    echo 2. Copy the public URL from ngrok window
    echo 3. Update Flutter app API endpoint with ngrok URL
    echo.
) else (
    echo.
    echo ============================================
    echo  Server Started (No ngrok)
    echo ============================================
    echo.
    echo [Server Window] - Face Recognition API
    echo   Local:  http://localhost:5000
    echo   Docs:   http://localhost:5000/docs
    echo.
    echo NOTE: ngrok not available - local access only
    echo To enable remote access, install ngrok first.
    echo.
)

echo To stop: Close the opened windows
echo ============================================
echo.
pause
