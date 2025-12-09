@echo off
echo Starting ngrok tunnel on port 5000...
echo.
echo Make sure your FastAPI server is running on port 5000 before starting ngrok!
echo.
echo To start the server, run: python app.py
echo or: uvicorn app:app --host 0.0.0.0 --port 5000
echo.
pause

D:\ngrok\ngrok.exe http 5000
