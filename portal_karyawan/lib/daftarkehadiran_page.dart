import 'package:flutter/material.dart';

class DaftarKehadiranPage extends StatelessWidget {
  const DaftarKehadiranPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color tealColor = Color(0xFF00C9A7); // Matching the progress bar color

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Daftar Kehadiran",
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
            
            // 2. HEADER (Icon + Month + Download)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      "Maret",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

            // 3. SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Percentage
                  const Text(
                    "90%",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.9,
                      minHeight: 12,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(tealColor),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // "Jumlah Kehadiran" Text
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Jumlah Kehadiran:               18x", // Manual spacing to match image layout
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Four Stats Boxes (Hadir, Izin, Sakit, Alpa)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox("Hadir", "18"),
                      _buildStatBox("Izin", "1"),
                      _buildStatBox("Sakit", "0"),
                      _buildStatBox("Alpa", "0"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. DATA TABLE HEADERS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Masuk", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Pulang", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1),

            // 5. DATA ROWS (Hardcoded to match image)
            _buildLogItem("01-03-2025", "08:01", "17:05", "Hadir", Colors.green),
            _buildLogItem("01-03-2025", "-", "-", "Alpa", Colors.red),
            _buildLogItem("01-03-2025", "-", "-", "Izin", Colors.blue),
            _buildLogItem("01-03-2025", "-", "-", "Sakit", Colors.orange), // Yellow/Orange for Sakit
          ],
        ),
      ),
    );
  }

  // Helper for the white squares in the summary card
  Widget _buildStatBox(String label, String count) {
    return Container(
      width: 75, // Fixed width to fit 4 in a row
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // Helper for the table rows
  Widget _buildLogItem(String date, String inTime, String outTime, String status, Color statusColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(date, style: const TextStyle(fontSize: 13))),
              Expanded(flex: 2, child: Text(inTime, style: const TextStyle(fontSize: 13))),
              Expanded(flex: 2, child: Text(outTime, style: const TextStyle(fontSize: 13))),
              Expanded(
                flex: 2, 
                child: Text(
                  status, 
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1), // Thin line between rows
      ],
    );
  }
}