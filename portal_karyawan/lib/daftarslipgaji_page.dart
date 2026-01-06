import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pdf_helper.dart';

class DetailSlipGajiPage extends StatefulWidget {
  final String month;
  final String year;
  final List<dynamic> details;

  const DetailSlipGajiPage({
    super.key,
    required this.month,
    required this.year,
    required this.details,
  });

  @override
  State<DetailSlipGajiPage> createState() => _DetailSlipGajiPageState();
}

class _DetailSlipGajiPageState extends State<DetailSlipGajiPage> {
  // ... (Identical to before)
  String _userName = "";
  String _nip = "";

// ... (Identical init logic)
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Karyawan"; 
      _nip = prefs.getString('nip') ?? "-";
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... logic remains same
    // Separate items by category
    final incomes = widget.details.where((d) => d['kategori'].toString().toLowerCase().trim() == 'penerimaan').toList();
    final deductions = widget.details.where((d) => d['kategori'].toString().toLowerCase().trim() == 'potongan').toList();
    
    // Calculate totals
    double totalIncome = incomes.fold(0, (sum, item) => sum + (item['jumlah'] is num ? item['jumlah'] : double.tryParse(item['jumlah'].toString()) ?? 0));
    double totalDeduction = deductions.fold(0, (sum, item) => sum + (item['jumlah'] is num ? item['jumlah'] : double.tryParse(item['jumlah'].toString()) ?? 0));
    double netSalary = totalIncome - totalDeduction;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         //... same appbar
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.featured_play_list_outlined, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "${widget.month} ${widget.year}", // Show Month + Year
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (_nip.isNotEmpty) {
                      PdfHelper.generateAndPrintSlip(
                        month: widget.month,
                        year: widget.year,
                        details: widget.details,
                        userName: _userName,
                        nip: _nip,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Data pengguna belum dimuat sepenuhnya.")),
                      );
                    }
                  },
                  child: Container(
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

            if (incomes.isEmpty)
              const Padding(padding: EdgeInsets.all(8.0), child: Text("- Tidak ada data -")),
            
            ...incomes.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              return _buildRow(
                index.toString(),
                "Penerimaan", 
                item['nama_komponen'] ?? '-', 
                _formatCurrency(item['jumlah'])
              );
            }),

            const Divider(thickness: 1),
            
            // TOTAL KOTOR
            _buildTotalRow("TOTAL KOTOR", _formatCurrency(totalIncome)),
            
            const Divider(thickness: 1),

            // 5. SECTION: POTONGAN
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Potongan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(thickness: 1),

            if (deductions.isEmpty)
              const Padding(padding: EdgeInsets.all(8.0), child: Text("- Tidak ada data -")),

            ...deductions.asMap().entries.map((entry) {
              final index = entry.key + 1; // You might want continuous numbering or reset
              final item = entry.value;
              return _buildRow(
                (incomes.length + index).toString(),
                "Potongan", 
                item['nama_komponen'] ?? '-', 
                _formatCurrency(item['jumlah'])
              );
            }),

            const Divider(thickness: 1),
            
            // TOTAL POTONGAN
            _buildTotalRow("TOTAL POTONGAN", _formatCurrency(totalDeduction)),
            
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
                Text(
                  _formatCurrency(netSalary),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  String _formatCurrency(dynamic amount) {
    double value = 0.0;
    if (amount is num) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 2);
    return format.format(value);
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