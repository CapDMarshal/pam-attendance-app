import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the login screen so we can navigate to it

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo2.png',
              width: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              "CODING ANARCHIST",
              style: TextStyle(
                fontFamily: 'RapidResponse',
                fontSize: 32,
                color: Color(0xFF4277BC),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}