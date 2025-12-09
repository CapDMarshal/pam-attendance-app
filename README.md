# Face Recognition Attendance System

A mobile attendance system using face recognition technology. Built with Flutter (frontend) and Python FastAPI (backend).

---

## 📋 Table of Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Running the Application](#running-the-application)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Requirements

### Backend
- Python 3.8+ installed
- ngrok account (free) for mobile access

### Frontend
- Flutter SDK 3.9.2+
- Android device or emulator

---

## Quick Start

### 1️⃣ ngrok Setup (One-Time)

ngrok is required to expose your local backend to your mobile device.

1. **Create Account**: Go to [ngrok.com](https://ngrok.com/) and sign up (free)
2. **Download**: Download ngrok from [ngrok.com/download](https://ngrok.com/download)
3. **Extract**: Place `ngrok.exe` in `D:\ngrok\` folder
4. **Authenticate**: 
   ```bash
   D:\ngrok\ngrok.exe authtoken YOUR_AUTH_TOKEN
   ```
   Get your auth token from: https://dashboard.ngrok.com/get-started/your-authtoken

### 2️⃣ Backend Setup (One-Time)

```bash
cd BE
complete_setup.bat
```

This will automatically:
- Check if ngrok is installed
- Create Python virtual environment
- Install all required packages

### 3️⃣ Frontend Setup (One-Time)

```bash
cd FE
flutter pub get
```

### 4️⃣ Run the Application

**Terminal 1 - Start Backend:**
```bash
cd BE
run_all.bat
```

This opens **two windows**:
- **Server window**: Shows API logs
- **ngrok window**: Shows the public URL

**Important**: Look for the ngrok URL in the ngrok window. It looks like:
```
Forwarding    https://xxxx-xx-xx-xx-xx.ngrok-free.app -> http://localhost:5000
```

**Terminal 2 - Update Flutter Config:**

Open `FE/lib/utils/constants.dart` and update the `baseUrl`:
```dart
static const String baseUrl = 'https://xxxx-xx-xx-xx-xx.ngrok-free.app';
```

**Terminal 3 - Start Frontend:**
```bash
cd FE
flutter run
```

---

## Detailed Setup

### Backend Files Overview

- `complete_setup.bat` - One-time setup script
- `run_all.bat` - Runs server + ngrok together
- `start_server.bat` - Runs only the server (manual mode)
- `ngrok_setup.bat` - Runs only ngrok (manual mode)
- `app.py` - Main FastAPI application
- `requirements.txt` - Python dependencies

### Frontend Structure

```
FE/
├── lib/
│   ├── screens/          # App screens (dashboard, clock-in, clock-out)
│   ├── services/         # API communication
│   ├── widgets/          # Reusable components
│   └── utils/            # Constants and config
└── assets/               # Images and resources
```

---

## Running the Application

### Option 1: Quick Run (Recommended)

```bash
# Terminal 1
cd BE
run_all.bat

# Terminal 2
cd FE
flutter run
```

### Option 2: Manual Control

If you want to run backend and ngrok separately:

```bash
# Terminal 1 - Backend
cd BE
start_server.bat

# Terminal 2 - ngrok
cd BE
ngrok_setup.bat

# Terminal 3 - Frontend
cd FE
flutter run
```

---

## Configuration

### Update ngrok URL in Flutter

Every time ngrok restarts, it generates a **new URL**. You must update it in the Flutter app:

1. Check the ngrok window for the current URL
2. Open `FE/lib/utils/constants.dart`
3. Update the `baseUrl`:
   ```dart
   static const String baseUrl = 'https://YOUR-NEW-NGROK-URL.ngrok-free.app';
   ```
4. Hot restart the Flutter app (press `R` in terminal)

### For Local Testing (Emulator Only)

If testing on an Android emulator (not physical device):

```dart
// In FE/lib/utils/constants.dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

---

## Features

✅ Face recognition using MTCNN and FaceNet  
✅ Clock-in and Clock-out tracking  
✅ JSON-based attendance storage  
✅ Real-time camera capture  
✅ Modern Flutter UI  
✅ RESTful API with automatic documentation  

---

## API Endpoints

Visit `http://localhost:5000/docs` when the server is running to see interactive API documentation.

**Main Endpoints:**
- `POST /api/clock-in` - Clock in with face photo
- `POST /api/clock-out` - Clock out with face photo
- `GET /api/attendance/{name}` - Get attendance records
- `POST /api/recognize` - Recognize face only

---

## Troubleshooting

### ❌ "ngrok not found" error

**Solution**: Make sure `ngrok.exe` is in `D:\ngrok\` or update the path in `complete_setup.bat` and `run_all.bat`

### ❌ Flutter can't connect to backend

**Check these:**
1. ✅ Is the server running? (Check Terminal 1)
2. ✅ Is ngrok running? (Check Terminal 2)
3. ✅ Did you update the ngrok URL in `constants.dart`?
4. ✅ Did you hot restart Flutter? (Press `R` in terminal)

### ❌ "No face detected" error

**Solutions:**
- Ensure good lighting
- Face the camera directly
- Make sure face is clearly visible
- Try moving closer to the camera

### ❌ ngrok URL expired

ngrok free tier URLs expire after 2 hours. When this happens:
1. Close ngrok window
2. Run `run_all.bat` again (or just `ngrok_setup.bat`)
3. Copy the **new** ngrok URL
4. Update `constants.dart`
5. Hot restart Flutter app

### ❌ Port 5000 already in use

**Solution**:
```bash
# Windows - Find and kill process on port 5000
netstat -ano | findstr :5000
taskkill /PID <PID_NUMBER> /F
```

### ❌ Virtual environment errors

**Solution**: Delete `venv` folder and run setup again:
```bash
cd BE
rmdir /s venv
complete_setup.bat
```

---

## Project Structure

```
PAM-FINAL/
├── BE/                          # Backend
│   ├── app.py                   # Main FastAPI app
│   ├── requirements.txt         # Python packages
│   ├── model_wajah_knn.pkl     # Trained face recognition model
│   ├── attendance.json         # Attendance data
│   ├── complete_setup.bat      # One-time setup
│   └── run_all.bat             # Run server + ngrok
│
├── FE/                          # Frontend
│   ├── lib/
│   │   ├── screens/            # App pages
│   │   ├── services/           # API calls
│   │   ├── widgets/            # UI components
│   │   └── utils/              # Config (constants.dart)
│   ├── assets/                 # Images
│   └── pubspec.yaml            # Flutter config
│
└── README.md                    # This file
```

---

## Development Tips

### Backend Development

**View Logs**: Check the server window for logs

**Test API**: Use the Swagger UI at `http://localhost:5000/docs`

**Stop Server**: Close the server window or press `Ctrl+C`

### Frontend Development

**Hot Reload**: Press `r` in Flutter terminal (for UI changes)

**Hot Restart**: Press `R` in Flutter terminal (for logic changes)

**Stop App**: Press `q` in Flutter terminal

**Check Flutter**: Run `flutter doctor` to verify setup

---

## Summary - Complete Workflow

1. **First Time Setup** (Once):
   ```bash
   # Setup ngrok account and authentication
   # Then run:
   cd BE
   complete_setup.bat
   
   cd ../FE
   flutter pub get
   ```

2. **Every Time You Run** (Always):
   ```bash
   # Terminal 1
   cd BE
   run_all.bat
   
   # Copy ngrok URL from ngrok window
   # Update FE/lib/utils/constants.dart
   
   # Terminal 2
   cd FE
   flutter run
   ```

3. **When ngrok URL Changes** (Every 2 hours or after restart):
   - Copy new ngrok URL
   - Update `constants.dart`
   - Press `R` in Flutter terminal

---

## Support

**Backend Issues**: Check server window logs and `http://localhost:5000/docs`

**Frontend Issues**: Run `flutter doctor` and check console errors

**ngrok Issues**: Verify authentication and check ngrok dashboard

---

Made with ❤️ for attendance management
