@echo off
echo ============================================
echo  Face Recognition Backend - Complete Setup
echo ============================================
echo.

REM Check if Python is installed
echo [1/5] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Python not found in PATH
    echo.
    echo Please install Python 3.8 or higher:
    echo 1. Download from https://www.python.org/downloads/
    echo 2. During installation, check "Add Python to PATH"
    echo 3. Restart this script
    echo.
    pause
    exit /b 1
)
echo    ✓ Python found
python --version
echo.

REM Check if ngrok is installed
echo [2/5] Checking ngrok installation...

REM Try to find ngrok in PATH
set NGROK_CMD=
where ngrok >nul 2>&1
if %errorlevel% equ 0 (
    set NGROK_CMD=ngrok
    echo    ✓ ngrok found in PATH
    goto :ngrok_found
)

REM Check common installation locations
if exist "D:\ngrok\ngrok.exe" (
    set NGROK_CMD=D:\ngrok\ngrok.exe
    echo    ✓ ngrok found at D:\ngrok\ngrok.exe
    goto :ngrok_found
)

if exist "%LOCALAPPDATA%\ngrok\ngrok.exe" (
    set NGROK_CMD=%LOCALAPPDATA%\ngrok\ngrok.exe
    echo    ✓ ngrok found at %LOCALAPPDATA%\ngrok\ngrok.exe
    goto :ngrok_found
)

if exist "%USERPROFILE%\ngrok\ngrok.exe" (
    set NGROK_CMD=%USERPROFILE%\ngrok\ngrok.exe
    echo    ✓ ngrok found at %USERPROFILE%\ngrok\ngrok.exe
    goto :ngrok_found
)

if exist "C:\ngrok\ngrok.exe" (
    set NGROK_CMD=C:\ngrok\ngrok.exe
    echo    ✓ ngrok found at C:\ngrok\ngrok.exe
    goto :ngrok_found
)

REM ngrok not found
echo.
echo ERROR: ngrok not found
echo.
echo Please install ngrok:
echo 1. Create account at https://ngrok.com/
echo 2. Download from https://ngrok.com/download
echo 3. Extract to one of these locations:
echo    - D:\ngrok\
echo    - %USERPROFILE%\ngrok\
echo    - C:\ngrok\
echo    Or add ngrok to your system PATH
echo 4. Run: ngrok authtoken YOUR_AUTH_TOKEN
echo    (Get token from https://dashboard.ngrok.com/get-started/your-authtoken)
echo.
pause
exit /b 1

:ngrok_found
echo.

REM Create virtual environment
echo [3/5] Creating virtual environment...
if exist "venv" (
    echo    ⓘ Virtual environment already exists
) else (
    python -m venv venv
    if errorlevel 1 (
        echo    ✗ Failed to create virtual environment
        pause
        exit /b 1
    )
    echo    ✓ Virtual environment created
)
echo.

REM Activate venv and install dependencies
echo [4/5] Installing dependencies...
call venv\Scripts\activate
if errorlevel 1 (
    echo    ✗ Failed to activate virtual environment
    pause
    exit /b 1
)

pip install -r requirements.txt
if errorlevel 1 (
    echo    ✗ Failed to install dependencies
    pause
    exit /b 1
)
echo    ✓ Dependencies installed
echo.

REM Setup complete
echo [5/5] Setup complete!
echo.
echo ============================================
echo  Setup Summary
echo ============================================
echo ✓ Virtual environment ready
echo ✓ Dependencies installed
echo ✓ ngrok configured
echo.
echo Next steps:
echo   1. Start server: start_server.bat
echo   2. Start ngrok:  ngrok_setup.bat (in a new terminal)
echo   3. Update Flutter app with ngrok URL
echo.
echo API will be available at:
echo   - Local:  http://localhost:5000
echo   - Docs:   http://localhost:5000/docs
echo   - ngrok:  (check ngrok terminal for URL)
echo.
echo ============================================
pause
