import 'package:flutter/material.dart';
import 'daftarkehadiran_page.dart'; // <--- IMPORT THE DETAIL PAGE

class RiwayatKehadiranPage extends StatefulWidget {
  const RiwayatKehadiranPage({super.key});

  @override
  State<RiwayatKehadiranPage> createState() => _RiwayatKehadiranPageState();
}

class _RiwayatKehadiranPageState extends State<RiwayatKehadiranPage> {
  // Simple state for the year dropdown
  String selectedYear = "2025";

  @override
  Widget build(BuildContext context) {
    // Colors based on your design
    const Color tealColor = Color(0xFF00C9A7); 
    
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
          "Riwayat Kehadiran",
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
            
            // 2. HEADER (Icon + Text)
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 10),
                const Text(
                  "Daftar Kehadiran",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. FILTER ROW (Year Dropdown + Download Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Year Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedYear,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.keyboard_arrow_down, size: 28),
                    ],
                  ),
                ),

                // Download Icon Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. ATTENDANCE CARDS (Wrapped in GestureDetector for Navigation)
            
            // CARD 1: MARET
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DaftarKehadiranPage()),
                );
              },
              child: _buildMonthCard(
                month: "Maret",
                percentage: 0.9,
                attendanceCount: 18,
                tealColor: tealColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CARD 2: FEBRUARI
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DaftarKehadiranPage()),
                );
              },
              child: _buildMonthCard(
                month: "Februari",
                percentage: 0.9,
                attendanceCount: 18,
                tealColor: tealColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CARD 3: JANUARI
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DaftarKehadiranPage()),
                );
              },
              child: _buildMonthCard(
                month: "Januari",
                percentage: 0.9,
                attendanceCount: 18,
                tealColor: tealColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGET FOR THE CARDS
  Widget _buildMonthCard({
    required String month, 
    required double percentage, 
    required int attendanceCount,
    required Color tealColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Light grey outer background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Name + Arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.black),
            ],
          ),
          
          const SizedBox(height: 12),

          // White Inner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Percentage Text
                Text(
                  "${(percentage * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(tealColor),
                  ),
                ),

                const SizedBox(height: 8),

                // Footer Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Jumlah Kehadiran:",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "${attendanceCount}x",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}