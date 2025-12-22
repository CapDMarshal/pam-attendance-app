# PAM Attendance System

A comprehensive face recognition-based attendance system with mobile app, web admin panel, and employee portal.

## � Project Components

### 1. Backend (`BE/`)
FastAPI-based backend with face recognition capabilities using MTCNN and FaceNet.

**Features:**
- Face recognition for clock-in/clock-out
- User management
- Attendance tracking with status management
- Salary slip generation
- RESTful API endpoints

**Tech Stack:**
- Python 3.x
- FastAPI
- TensorFlow
- MTCNN & FaceNet
- OpenCV

### 2. Mobile App (`FE/`)
Flutter mobile application for employee attendance.

**Features:**
- Face recognition-based clock-in/out
- Real-time attendance tracking
- User-friendly interface

**Tech Stack:**
- Flutter/Dart
- Camera integration
- HTTP requests

### 3. Admin Panel (`pam-admin/`)
Next.js web application for administrators.

**Features:**
- User management (add, edit, view)
- Attendance reports (Laporan Absensi)
- Salary slip management (Slip Gaji)
- Status management (attend/alpha/permission/sick)
- Dashboard with attendance overview

**Tech Stack:**
- Next.js 16
- TypeScript
- Tailwind CSS
- React

### 4. Employee Portal (`portal_karyawan/`)
Flutter web application for employees to view their records.

**Features:**
- View attendance history
- Download salary slips
- Monthly attendance reports

**Tech Stack:**
- Flutter Web
- Dart

## 📋 Prerequisites

- **Python 3.8+** for backend
- **Node.js 18+** or **Bun** for pam-admin
- **Flutter SDK** for FE and portal_karyawan
- **Git**

## 🛠️ Installation

### Backend Setup

```bash
cd BE
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Admin Panel Setup

```bash
cd pam-admin
bun install  # or npm install
```

### Employee Portal Setup

```bash
cd portal_karyawan
flutter pub get
```

### Mobile App Setup

```bash
cd FE
flutter pub get
```

## ▶️ Running the Applications

### Start Backend

```bash
cd BE
./run_all.bat  # Starts FastAPI server and ngrok tunnel
```

Backend will run on `http://localhost:5000`

### Start Admin Panel

```bash
cd pam-admin
bun run dev  # or npm run dev
```

Admin panel will run on `http://localhost:3000`

### Start Employee Portal

```bash
cd portal_karyawan
flutter run -d chrome  # For web
```

### Run Mobile App

```bash
cd FE
flutter run
```

## 🔑 API Endpoints

### Authentication
- `POST /api/auth/login` - User login

### Users
- `GET /api/users` - Get all users
- `GET /api/users/{user_id}` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/{user_id}` - Update user

### Attendance
- `POST /api/clock-in` - Clock in with face recognition
- `POST /api/clock-out` - Clock out with face recognition
- `GET /api/attendance/all` - Get all attendance records
- `GET /api/attendance/user/{user_id}` - Get user attendance
- `GET /api/attendance/user/{user_id}/month/{month}` - Get monthly attendance
- `GET /api/attendance/status/month/{month}` - Get attendance with status calculation
- `POST /api/attendance/status/update` - Update attendance status

### Salary
- `GET /api/salary/{user_id}` - Get user salary info
- `GET /api/salary/{user_id}/slip/{month}` - Get salary slip by month

### Face Recognition
- `POST /api/recognize` - Recognize face from image
- `POST /api/register` - Register new face
- `GET /api/registered-faces` - Get all registered faces

## 📁 Project Structure

```
PAM-FINAL/
├── BE/                          # FastAPI Backend
│   ├── app.py                   # Main application
│   ├── users.json               # User database
│   ├── attendance.json          # Attendance records
│   ├── attendance_statuses.json # Status overrides
│   ├── salaries.json            # Salary data
│   └── datasets/                # Face recognition datasets
├── FE/                          # Flutter Mobile App
│   ├── lib/
│   └── android/
├── pam-admin/                   # Next.js Admin Panel
│   ├── app/
│   ├── components/
│   └── lib/
└── portal_karyawan/            # Flutter Web Employee Portal
    └── lib/
```

## 🎯 Features

### Admin Panel Features
- **Dashboard**: Overview of all users with today's attendance status
- **User Management**: Add, edit, and manage user accounts
- **Laporan Absensi**: 
  - Monthly attendance reports
  - Status breakdown (attend/alpha/permission/sick)
  - Edit individual day status via modal
  - Working days calculation (Mon-Fri)
- **Slip Gaji**: Monthly salary slip generation and viewing
- **Alter Absention**: Quick status change for today's attendance

### Attendance Status System
- **attend**: User clocked in (from face recognition)
- **alpha**: Absent (default for working days without clock-in)
- **permission**: Excused absence (set by admin)
- **sick**: Sick leave (set by admin)

Status priority:
1. Admin manual overrides (permission/sick)
2. Clock-in records (attend)
3. Default (alpha)

## 🔒 Default Admin Credentials

**Admin Panel:**
- Username: `admin`
- Password: `admin`

## 📱 Mobile App Configuration

Update the ngrok URL in `FE/lib/utils/constants.dart` after starting the backend:

```dart
class ApiConstants {
  static const String baseUrl = 'YOUR_NGROK_URL';
}
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Your Name** - Initial work

## 🙏 Acknowledgments

- MTCNN for face detection
- FaceNet for face recognition
- FastAPI for backend framework
- Next.js for admin panel
- Flutter for mobile and web applications
