import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart'; // <--- Connects to Profile
import 'riwayatkehadiran_page.dart'; // <--- Connects to Attendance History
import 'riwayatslipgaji_page.dart'; // <--- Connects to Salary History

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _firstName = "";
  bool _isLoadingName = true;
  String _attendanceStatus = ""; // 'in', 'out', 'default'
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchAttendanceStatus();
  }

  Future<void> _fetchUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        final response = await Supabase.instance.client
            .from('karyawan')
            .select('nama_lengkap')
            .eq('nip', nip)
            .maybeSingle();

        if (response != null && response['nama_lengkap'] != null) {
          final String fullName = response['nama_lengkap'];
          // Get the first word
          final String firstName = fullName.split(' ').first;

          if (mounted) {
            setState(() {
              _firstName = firstName;
              _isLoadingName = false;
            });
          }
        }
      } else {
        debugPrint("User session NIP is null");
        if (mounted) {
          setState(() => _isLoadingName = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    } finally {
      if (mounted && _isLoadingName) {
        setState(() => _isLoadingName = false);
      }
    }
  }

  Future<void> _fetchAttendanceStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        // Query kehadiran using nip and time range for today (Local time converted to UTC)
        final DateTime now = DateTime.now(); // Local time

        // Construct start and end of TODAY in Local time
        final DateTime startOfDayLocal = DateTime(now.year, now.month, now.day);
        final DateTime endOfDayLocal = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        );

        // Convert to UTC ISO strings for Supabase query
        final String startOfDay = startOfDayLocal.toUtc().toIso8601String();
        final String endOfDay = endOfDayLocal.toUtc().toIso8601String();

        final response = await Supabase.instance.client
            .from('kehadiran')
            .select('status')
            .eq('nip', nip) // Direct NIP query as per user request
            .gte('waktu_clockin', startOfDay)
            .lte('waktu_clockin', endOfDay)
            .order('waktu_clockin', ascending: false) // Get latest status
            .limit(1)
            .maybeSingle();

        if (mounted) {
          setState(() {
            if (response != null && response['status'] != null) {
              final String status = response['status']
                  .toString()
                  .toLowerCase()
                  .trim();
              debugPrint("Fetched Status: '$status'");

              if (status == 'in') {
                _attendanceStatus = "in";
              } else if (status == 'out') {
                _attendanceStatus = "out";
              } else {
                _attendanceStatus = "default";
              }
            } else {
              debugPrint("No attendance record found for today.");
              _attendanceStatus = "default";
            }
            _isLoadingStatus = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  Widget _buildStatusCard() {
    Color cardColor;
    Color borderColor;
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    double iconRotation = 0;

    switch (_attendanceStatus) {
      case 'in':
        cardColor = const Color(0xFF4CAF50); // Green
        borderColor = const Color(0xFF2E7D32); // Darker Green
        icon = Icons.check_circle;
        iconColor = Colors.white;
        title = "You are Checked in!";
        subtitle = "Keep up the good work!";
        break;
      case 'out':
        cardColor = Colors.grey.shade400; // Grey
        borderColor = Colors.grey.shade700; // Darker Grey
        icon = Icons
            .logout; // Or 'door_back_door' if available, but logout is standard
        iconColor = const Color(0xFFD32F2F); // Red
        title = "Checked out";
        subtitle = "You're done for the day";
        break;
      default: // 'default'
        cardColor = const Color(0xFFA8C7FA); // Light Blue
        borderColor = const Color(0xFF4277BC); // Brand Blue
        icon = Icons.link_off;
        iconColor = const Color(0xFF4277BC);
        title = "You are not checked in";
        subtitle = "Check in before 09:00 am";
        iconRotation = -0.5;
        break;
    }

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: iconRotation,
            child: Icon(icon, size: 60, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Brand colors matching your design
    const Color brandColor = Color(0xFF4277BC);

    return Scaffold(
      backgroundColor: Colors.white,

      // 1. CUSTOM APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Hides the back button (user can't go back to login)
        // Logo and Title
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 40, height: 40),
            const SizedBox(width: 10),
            const Text(
              "CODING ANARCHIST",
              style: TextStyle(
                fontFamily: 'RapidResponse', // Your custom font
                fontSize: 18,
                color: brandColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        // Profile Button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Colors.black,
                size: 32,
              ),
              onPressed: () {
                // Navigate to Profile
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ),
        ],

        // Bottom Border Line
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),

      // 2. MAIN BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GREETING SECTION ---
            Row(
              children: [
                const Icon(Icons.favorite, color: brandColor, size: 28),
                const SizedBox(width: 10),
                _isLoadingName
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        "Halo, $_firstName!",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              "Rajin Pangkal Kaya!",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // --- STATUS CARD ---
            _isLoadingStatus
                ? Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _buildStatusCard(),

            const SizedBox(height: 40),

            // --- MENU ITEM 1: Riwayat Kehadiran ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RiwayatKehadiranPage(),
                  ),
                );
              },
              child: _buildMenuItem(
                icon: Icons.calendar_month,
                text: "Riwayat Kehadiran",
                color: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 20),

            // --- MENU ITEM 2: Slip Gaji ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RiwayatSlipGajiPage(),
                  ),
                );
              },
              child: _buildMenuItem(
                icon: Icons.wallet,
                text: "Slip Gaji",
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget to reduce code repetition
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        // Colored Box with Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 15),

        // Text Label
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),

        // Arrow Icon
        const Icon(Icons.arrow_forward, color: Colors.black),
      ],
    );
  }
}
