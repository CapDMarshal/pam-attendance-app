# Face Recognition Backend API

## 🚀 Quick Start

### Prerequisites
- **Python 3.11** (Required for TensorFlow compatibility)
- **Ngrok** (For exposing local server to internet)
- **Webcam** (For testing)

### ⚡ One-Click Setup & Run
1. **Setup Environment**:
   Double-click `setup_venv.bat` to create a virtual environment and install dependencies.

2. **Start Server**:
   Double-click `start_server.bat`. The server will run on `http://localhost:5000`.

3. **Start Ngrok**:
   Double-click `ngrok_setup.bat`. This exposes your local server to the internet.

---

## 📱 Flutter Integration

### 1. Dependencies
Add these to your `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  image: ^4.1.3
  camera: any
  google_mlkit_face_detection: any
```

### 2. Configuration
Update `lib/config/api_config.dart` with your **Ngrok URL**:
```dart
class ApiConfig {
  static const String baseUrl = 'https://your-ngrok-url.ngrok-free.app';
}
```

### 3. API Usage
The app sends a JPEG image to `/api/recognize`.
```dart
final response = await FaceRecognitionAPI.recognizeFace(imageBytes);
if (response.success) {
  print('Recognized: ${response.name}');
}
```

---

## 📡 API Endpoints

### Health Check
`GET /api/health`
- Returns status of server and loaded models.

### Face Recognition
`POST /api/recognize`
- **Body**: `multipart/form-data` with `file` (image).
- **Response**:
  ```json
  {
    "success": true,
    "name": "John Doe",
    "confidence": 0.85,
    "face_detected": true
  }
  ```

---

## 🔧 Troubleshooting

### Server Issues
- **Python Version**: Ensure you are using Python 3.11. Run `python --version`.
- **Dependencies**: If errors occur, run `setup_venv.bat` again.

### App Connection
- **Ngrok**: Ensure ngrok is running and the URL in `api_config.dart` matches.
- **Android**: If running on a physical device, ensure USB debugging is enabled and drivers are installed.

### Face Not Detected
- Ensure good lighting.
- Face should be centered in the frame.
