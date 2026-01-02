import 'package:flutter/material.dart';
import 'profile_page.dart';               // <--- Connects to Profile
import 'riwayatkehadiran_page.dart';     // <--- Connects to Attendance History
import 'riwayatslipgaji_page.dart';       // <--- Connects to Salary History

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
        automaticallyImplyLeading: false, // Hides the back button (user can't go back to login)
        
        // Logo and Title
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
            ),
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
          child: Container(
            color: Colors.grey.shade300,
            height: 1.0,
          ),
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
                const Text(
                  "Halo, Kevin!",
                  style: TextStyle(
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // --- STATUS CARD (Check In) ---
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFA8C7FA), // Light blue background
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: brandColor, 
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.5, 
                    child: const Icon(
                      Icons.link_off,
                      size: 60,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You are not checked in",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    "Check in before 09:00 am",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- MENU ITEM 1: Riwayat Kehadiran ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RiwayatKehadiranPage()),
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
                  MaterialPageRoute(builder: (context) => const RiwayatSlipGajiPage()),
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
  Widget _buildMenuItem({required IconData icon, required String text, required Color color}) {
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Arrow Icon
        const Icon(Icons.arrow_forward, color: Colors.black),
      ],
    );
  }
}