@echo off
echo Starting Face Recognition API Server with Python 3.11...
echo.
echo Server will start on http://localhost:5000
echo API Documentation will be available at http://localhost:5000/docs
echo.
echo Press Ctrl+C to stop the server
echo.

call venv\Scripts\activate.bat
python app.py
