@echo off
echo Starting ngrok tunnel on port 5000...
echo.
echo Make sure your FastAPI server is running on port 5000 before starting ngrok!
echo.
echo To start the server, run: python app.py
echo or: uvicorn app:app --host 0.0.0.0 --port 5000
echo.
pause

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
        echo.
        echo ERROR: ngrok not found!
        echo Please install ngrok or run complete_setup.bat
        echo.
        pause
        exit /b 1
    )
)

REM Run ngrok
%NGROK_CMD% http 5000
