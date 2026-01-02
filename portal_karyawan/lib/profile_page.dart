import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers for the form fields
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF4277BC);
    const Color cardBgColor = Color(0xFFA8C7FA); // Light blue for card background

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Go back to Dashboard
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontFamily: 'SegoeUI',
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 2. PROFILE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: brandColor, width: 4),
              ),
              child: Column(
                children: [
                  // Profile Icon Circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      color: Colors.transparent, // Or white if you prefer
                    ),
                    child: const Icon(Icons.person_outline, size: 50, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Kevin Geraldi Harjanto L",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "NIP: 123456789",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 3. EMAIL ROW
            const Row(
              children: [
                Icon(Icons.email_outlined, size: 24),
                SizedBox(width: 10),
                Text(
                  "Email :  Kevin@gmail.com",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 4. PASSWORD FORM
            _buildLabel("Current Password"),
            _buildTextField(_currentPassController),
            
            const SizedBox(height: 15),
            
            _buildLabel("New Password"),
            _buildTextField(_newPassController),
            
            const SizedBox(height: 15),
            
            _buildLabel("Confirm New Password"),
            _buildTextField(_confirmPassController),

            const SizedBox(height: 30),

            // 5. BUTTONS
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  print("Submit pressed");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Submit", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 15),

            // Logout Button (Text says 'Login' in your design, but red usually means Logout)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Usually, this would clear session and navigate back to LoginScreen
                  print("Logout pressed");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B3B), // Bright Red
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Logout", style: TextStyle(fontSize: 16)), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to keep code clean
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Helper widget for standard text fields
  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true, // Passwords are hidden
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4277BC), width: 2),
        ),
      ),
    );
  }
}