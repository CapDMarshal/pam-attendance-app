import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

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

  // Profile Data
  String _fullName = "Loading...";
  String _nip = "...";
  String _email = "...";
  bool _isLoading = true;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        final response = await Supabase.instance.client
            .from('karyawan')
            .select() // Select all fields to get email as well
            .eq('nip', nip)
            .maybeSingle();

        if (response != null) {
          if (mounted) {
            setState(() {
              _fullName = response['nama_lengkap'] ?? "Unknown";
              _nip = response['nip'] ?? nip;
              _email = response['email'] ?? "No Email";
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) {
        setState(() {
          _fullName = "Error loading";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPass = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all password fields')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      // 1. Re-authenticate to verify current password
      // We need email from session or profile
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not authenticated");
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email!,
        password: currentPass,
      );

      // 2. Update Password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear fields
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auth Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

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
    const Color cardBgColor = Color(
      0xFFA8C7FA,
    ); // Light blue for card background

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
                    child: const Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Column(
                          children: [
                            Text(
                              _fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "NIP: $_nip",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 3. EMAIL ROW
            // 3. EMAIL ROW
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Email :  $_email",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                onPressed: _isUpdatingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUpdatingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 15),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Clear session
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  // Sign out from Supabase
                  await Supabase.instance.client.auth.signOut();

                  if (context.mounted) {
                    // Navigate back to LoginScreen and remove all previous routes
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/', // Assuming '/' is the route for login or main wrapper
                      (route) => false,
                    ).catchError((_) {
                      // Fallback if named route isn't defined, though main.dart usually has home: LoginScreen or wrapper
                      // Since main.dart uses home: SplashScreen -> Login, we might need to verify the route name.
                      // Looking at main.dart, it doesn't define named routes.
                      // I should check main.dart or just push Replacement with the widget.
                    });
                    // Safest approach without named routes:
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
