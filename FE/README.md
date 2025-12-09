# Face Recognition Attendance System - Flutter Frontend

A Flutter mobile application for face recognition-based attendance tracking system. This app integrates with a Python backend using MTCNN and FaceNet for face verification.

## Features

- **Dashboard**: Simple interface with Clock-In and Clock-Out options
- **Face Recognition**: Real-time camera preview with face positioning guide
- **Attendance Tracking**: Automatic recording of clock-in/clock-out times
- **Backend Integration**: Seamless API communication with Flask backend

## Screenshots

The app design matches the reference with:
- Blue primary color scheme (#5B6EF5)
- Clean, modern UI
- Camera preview with face frame overlay
- Success/failure feedback dialogs

## Prerequisites

- Flutter SDK (3.35.7 or later)
- Android Studio / Xcode for mobile development
- Physical device or emulator with camera support
- Backend server running (see ../BE/README.md)

## Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Backend URL**:
   Edit `lib/utils/constants.dart` and update the `baseUrl`:
   ```dart
   static const String baseUrl = 'YOUR_NGROK_URL_HERE';
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── dashboard_screen.dart # Main dashboard
│   ├── clock_in_screen.dart  # Clock-in with camera
│   └── clock_out_screen.dart # Clock-out with camera
├── services/
│   └── api_service.dart      # API communication
├── widgets/
│   └── custom_button.dart    # Reusable button widget
└── utils/
    └── constants.dart        # App constants & styling
```

## API Integration

The app communicates with the following backend endpoints:

- `POST /api/clock-in`: Submit face image for clock-in
- `POST /api/clock-out`: Submit face image for clock-out
- `POST /api/recognize`: Recognize face from image
- `GET /api/attendance/{name}`: Get attendance records

## Permissions

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face recognition</string>
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

**Camera not working**:
- Ensure camera permissions are granted
- Test on a physical device (emulators may have limited camera support)

**API connection failed**:
- Verify backend is running
- Check ngrok URL is correct in `constants.dart`
- Ensure phone/emulator can access the network

**Build errors**:
```bash
flutter clean
flutter pub get
flutter run
```

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Camera package**: Camera access and preview
- **HTTP package**: API communication
- **Provider**: State management (for future enhancements)

## License

This project is part of the PAM-FINAL course project.
