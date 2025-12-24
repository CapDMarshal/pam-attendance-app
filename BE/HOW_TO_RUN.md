# How to Run the Face Recognition Server

## Option 1: Run Everything at Once (Recommended)

**Simple one-click solution:**
```batch
run_all.bat
```

This will:
1. ✅ Activate virtual environment
2. ✅ Start the Face Recognition API server
3. ✅ Start ngrok tunnel for public access
4. ✅ Open both in separate windows

**Look for:**
- **Server window**: Shows API logs and errors
- **ngrok window**: Shows the public URL (Forwarding line)

---

## Option 2: Run Server and ngrok Separately

### Step 1: Start the Server First
```batch
start_server_only.bat
```

Or manually:
```batch
python app.py
```

**Wait until you see:**
```
INFO:     Uvicorn running on http://0.0.0.0:5000
INFO:     Face recognition model loaded successfully!
```

### Step 2: Start ngrok Tunnel (in a new terminal)
```batch
start_ngrok_only.bat
```

Or manually:
```batch
ngrok http 5000
```

**Copy the public URL** from the ngrok output:
```
Forwarding  https://xxxx-xx-xx-xx-xx.ngrok-free.app -> localhost:5000
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            Copy this URL!
```

---

## Option 3: Local Testing Only (No ngrok)

If you only want to test locally without public access:

```batch
start_server_only.bat
```

Then access at: **http://localhost:5000**

---

## After Starting

### 1. Verify Server is Running

Open your browser and go to:
- **API Docs**: http://localhost:5000/docs
- **Health Check**: http://localhost:5000/api/health

### 2. Update Flutter App

If using ngrok, update the Flutter app's API endpoint:

**File**: `FE/lib/utils/constants.dart`

```dart
class ApiConstants {
  // Replace with your ngrok URL
  static const String baseUrl = 'https://YOUR-NGROK-URL.ngrok-free.app';
  
  // Example:
  // static const String baseUrl = 'https://1234-56-78-90-12.ngrok-free.app';
}
```

### 3. Test the API

Using the browser docs at http://localhost:5000/docs:
1. Try `/api/health` to check status
2. Try `/api/registered-faces` to see registered users
3. Try `/api/recognize` to test face recognition

---

## Troubleshooting

### Server won't start

**Check error messages** in the server window. Common issues:

#### "No module named 'keras_facenet'"
```batch
pip install keras-facenet tensorflow
```

#### "Address already in use"
Something is already running on port 5000. Kill it:
```batch
netstat -ano | findstr :5000
taskkill /F /PID <PID_NUMBER>
```

#### "Model loading takes too long"
First run downloads FaceNet model (~200MB). This is normal.

---

### ngrok won't start

#### "ngrok not found"
Install ngrok:
1. Download from https://ngrok.com/download
2. Extract to `D:\ngrok\` or add to PATH
3. Run: `ngrok config add-authtoken YOUR_TOKEN`

#### "Server not available"
Make sure the server is running first before starting ngrok!

---

### Server starts but crashes

Check the server window for errors. Common causes:

1. **FaceNet not installed**: Run `setup_facenet.bat`
2. **Missing dependencies**: Run `pip install -r requirements.txt`
3. **No faces registered**: This is OK, you can register via `/api/register`

---

## Quick Reference

| Action | Command |
|--------|---------|
| **Everything at once** | `run_all.bat` |
| **Server only** | `start_server_only.bat` or `python app.py` |
| **ngrok only** | `start_ngrok_only.bat` or `ngrok http 5000` |
| **View API docs** | http://localhost:5000/docs |
| **Health check** | http://localhost:5000/api/health |
| **Stop server** | Ctrl+C in terminal or close window |
| **Stop ngrok** | Ctrl+C in ngrok terminal or close window |

---

## Workflow Summary

```
1. run_all.bat
   ↓
2. Check server window - should show "model loaded"
   ↓
3. Check ngrok window - copy the Forwarding URL
   ↓
4. Update Flutter app with ngrok URL
   ↓
5. Test with Flutter app!
```

---

## Testing Checklist

After starting:

- [ ] Server window shows "Face recognition model loaded successfully!"
- [ ] No error messages in server window
- [ ] http://localhost:5000/docs loads successfully
- [ ] http://localhost:5000/api/health returns {"status": "healthy"}
- [ ] ngrok window shows "Forwarding" URL (if using ngrok)
- [ ] Flutter app can connect to the API

---

## Need Help?

1. Check the **server window** for error messages
2. Check the **ngrok window** for connection issues
3. Visit http://localhost:5000/docs to see API documentation
4. Read FACENET_MIGRATION.md for setup details
5. Read QUICK_START.md for troubleshooting

---

**Version**: 3.0.0 (FaceNet)  
**Port**: 5000  
**Docs**: http://localhost:5000/docs
