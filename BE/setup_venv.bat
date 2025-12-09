@echo off
echo Creating Python 3.11 virtual environment...
echo.

REM Create virtual environment using Python 3.11
"C:\Users\FSOS\AppData\Local\Programs\Python\Python311\python.exe" -m venv venv

echo.
echo Virtual environment created successfully!
echo.
echo Installing dependencies...
call venv\Scripts\activate
"C:\Users\FSOS\.local\bin\uv.exe" pip install -r requirements.txt
echo.
echo Setup complete!
pause
