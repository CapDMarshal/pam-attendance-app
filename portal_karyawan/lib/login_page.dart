import 'package:flutter/material.dart';
import 'dashboard_page.dart'; // <--- IMPORT THE DASHBOARD PAGE HERE

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to retrieve text input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // State for the checkbox
  bool _isRememberMeChecked = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF4277BC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // CENTER WIDGET: Forces the entire scrollable form to the middle of the screen
        child: Center( 
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- HEADER SECTION (Logo + Text) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "CODING ANARCHIST",
                      style: TextStyle(
                        fontFamily: 'RapidResponse', 
                        fontSize: 22,
                        color: brandColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50), // Spacing between header and form

                // --- EMAIL FIELD ---
                const Text(
                  "Email Address",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: brandColor, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- PASSWORD FIELD ---
                const Text(
                  "Password",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Hides the password
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: brandColor, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // --- REMEMBER ME & FORGOT PASSWORD ---
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isRememberMeChecked,
                        activeColor: brandColor,
                        onChanged: (bool? value) {
                          setState(() {
                            _isRememberMeChecked = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("Remember me"),
                    
                    const Spacer(), // Pushes "Forgot Password" to the far right
                    
                    GestureDetector(
                      onTap: () {
                        print("Forgot password tapped");
                      },
                      child: const Text(
                        "Forgot Password",
                        style: TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity, // Full width button
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // 1. (Optional) Print inputs to console for testing
                      print("Email: ${_emailController.text}");
                      print("Password: ${_passwordController.text}");
                      
                      // 2. NAVIGATE TO DASHBOARD
                      // We use pushReplacement so the user can't click "Back" to return to Login
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}