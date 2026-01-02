import 'package:flutter/material.dart';
import 'daftarslipgaji_page.dart'; // <--- IMPORT THE DETAIL PAGE

class RiwayatSlipGajiPage extends StatefulWidget {
  const RiwayatSlipGajiPage({super.key});

  @override
  State<RiwayatSlipGajiPage> createState() => _RiwayatSlipGajiPageState();
}

class _RiwayatSlipGajiPageState extends State<RiwayatSlipGajiPage> {
  String selectedYear = "2025";

  @override
  Widget build(BuildContext context) {
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
          "Slip Gaji",
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
            
            // 2. HEADER
            Row(
              children: [
                const Icon(Icons.featured_play_list_outlined, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 10),
                const Text(
                  "Daftar Slip Gaji",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. FILTER ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Year Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                
                // Download Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download, color: Colors.blueAccent),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. SLIP GAJI CARDS (With Navigation)
            
            // Card 1: Februari (Segera Diambil)
            GestureDetector(
              onTap: () {
                // Navigate to Detail Slip Gaji
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetailSlipGajiPage()),
                );
              },
              child: _buildSlipGajiCard(
                month: "Februari",
                amount: "Rp. 6.000.000,00",
                statusText: "Segera Diambil",
                statusColor: Colors.blueAccent,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Card 2: Januari (Telah Diambil)
            GestureDetector(
              onTap: () {
                // Navigate to Detail Slip Gaji
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetailSlipGajiPage()),
                );
              },
              child: _buildSlipGajiCard(
                month: "Januari",
                amount: "Rp. 6.000.000,00",
                statusText: "Telah Diambil",
                statusColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGET
  Widget _buildSlipGajiCard({
    required String month,
    required String amount,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Light grey outer card
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Month Row
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

          // Inner White Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    // Left Side: Label and Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Jumlah Bersih:",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // Right Side: Status Text
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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