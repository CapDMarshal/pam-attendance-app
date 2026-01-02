import 'package:flutter/material.dart';
import 'splashscreen_page.dart'; // Import the splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coding Anarchist',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4277BC)),
      ),
      // Point directly to the imported file
      home: const SplashScreen(),
    );
  }
}