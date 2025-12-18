import 'package:flutter/material.dart';

// API Configuration
class ApiConstants {
  static final String baseUrl = 'https://292e040d83a1.ngrok-free.app';
  static const String clockInEndpoint = '/api/clock-in';
  static const String clockOutEndpoint = '/api/clock-out';
  static const String recognizeEndpoint = '/api/recognize';
  static const String attendanceEndpoint = '/api/attendance';
}

// Color Scheme
class AppColors {
  static const Color primary = Color(0xFF5B6EF5);
  static const Color primaryDark = Color(0xFF4755D8);
  static const Color background = Color(0xFFF5F6FA);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle body = TextStyle(fontSize: 16, color: AppColors.black);

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.grey,
  );
}

// Sizing
class AppSizes {
  static const double borderRadius = 12.0;
  static const double buttonHeight = 50.0;
  static const double padding = 16.0;
  static const double paddingLarge = 24.0;
}
