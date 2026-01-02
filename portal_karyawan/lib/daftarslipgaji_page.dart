import 'package:flutter/material.dart';

class DetailSlipGajiPage extends StatelessWidget {
  const DetailSlipGajiPage({super.key});

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Slip Gaji",
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
                    const Icon(Icons.featured_play_list_outlined, color: Colors.blueAccent, size: 28),
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

            const SizedBox(height: 30),

            // 3. TABLE HEADERS
            const Row(
              children: [
                SizedBox(width: 30, child: Text("No", style: TextStyle(fontSize: 12))),
                Expanded(flex: 2, child: Text("Kategori", style: TextStyle(fontSize: 12))),
                Expanded(flex: 3, child: Text("Komponen\nGaji", style: TextStyle(fontSize: 12))),
                Expanded(flex: 3, child: Text("Jumlah(Rp)", textAlign: TextAlign.right, style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.black, thickness: 1),

            // 4. SECTION: PENERIMAAN
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Penerimaan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(thickness: 1),

            _buildRow("1", "Pendapatan", "Gaji Pokok", "5.000.000,00"),
            _buildRow("2", "Pendapatan", "Tunjangan\nJabatan", "850.000,00"),
            _buildRow("3", "Pendapatan", "Uang\nLembur", "380.000,00"),

            const Divider(thickness: 1),
            
            // TOTAL KOTOR
            _buildTotalRow("TOTAL KOTOR", "6.230.000,00"),
            
            const Divider(thickness: 1),

            // 5. SECTION: POTONGAN
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Potongan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(thickness: 1),

            _buildRow("4", "Potongan", "PPh Pasal 21", "120.000,00"),
            _buildRow("5", "Potongan", "Iuran BPJS", "80.000,00"),
            _buildRow("6", "Potongan", "Cicilan\nKaryawan", "30.000,00"),

            const Divider(thickness: 1),
            
            // TOTAL POTONGAN
            _buildTotalRow("TOTAL POTONGAN", "230.000,00"),
            
            const Divider(thickness: 1),

            const SizedBox(height: 20),

            // 6. FINAL: GAJI BERSIH (THP)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "GAJI BERSIH (THP)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Text(
                  "6.000.000,00",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.black, thickness: 1),
          ],
        ),
      ),
    );
  }

  // Helper for standard data rows
  Widget _buildRow(String no, String category, String component, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multiline text
        children: [
          SizedBox(width: 30, child: Text(no, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(category, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 3, child: Text(component, style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 3, 
            child: Text(
              amount, 
              textAlign: TextAlign.right, 
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Total rows
  Widget _buildTotalRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}