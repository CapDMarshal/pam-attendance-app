import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'daftarslipgaji_page.dart';
import 'utils/pdf_helper.dart';

class RiwayatSlipGajiPage extends StatefulWidget {
  const RiwayatSlipGajiPage({super.key});

  @override
  State<RiwayatSlipGajiPage> createState() => _RiwayatSlipGajiPageState();
}

class _RiwayatSlipGajiPageState extends State<RiwayatSlipGajiPage> {
  bool _isLoading = true;
  List<String> _years = ["2025"];
  String _selectedYear = "2025";
  List<Map<String, dynamic>> _slipList = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchAvailableYears();
    // _fetchSlipGaji is now called inside _fetchAvailableYears after setting the default year
  }

  Future<void> _fetchAvailableYears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        final response = await Supabase.instance.client
            .from('slip_gaji')
            .select('tahun')
            .eq('nip', nip);

        final Set<String> yearSet = {};
        for (var item in response) {
          yearSet.add(item['tahun'].toString());
        }

        if (yearSet.isNotEmpty) {
          final sortedYears = yearSet.toList()
            ..sort((a, b) => b.compareTo(a)); // Descending: 2026, 2025...
          if (mounted) {
            setState(() {
              _years = sortedYears;
              // Default to the latest year (first in sorted list)
              _selectedYear = _years.first;
            });
            // Fetch data for this default year immediately
            _fetchSlipGaji();
          }
        } else {
          // No data found (RLS or empty)
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching years: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSlipGaji() async {
    setState(() {
      _isLoading = true;
      _slipList = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        // Fetch slip_gaji and nested slip_gaji_detail to calculate total
        final response = await Supabase.instance.client
            .from('slip_gaji')
            .select('*, slip_gaji_detail(jumlah, kategori, nama_komponen)')
            .eq('nip', nip)
            .eq('tahun', int.parse(_selectedYear))
            .order('bulan', ascending: false);

        final List<Map<String, dynamic>> loadedSlips = [];

        for (var slip in response) {
          double totalAmount = 0;

          // Calculate Net Salary: Penerimaan - Potongan
          if (slip['slip_gaji_detail'] != null) {
            for (var detail in slip['slip_gaji_detail']) {
              // Ultra-safe parsing: Handle String, int, double, or null
              final dynamic rawAmount = detail['jumlah'];
              double amount = 0.0;
              if (rawAmount is num) {
                amount = rawAmount.toDouble();
              } else if (rawAmount is String) {
                amount = double.tryParse(rawAmount) ?? 0.0;
              }

              final String category = detail['kategori']
                  .toString()
                  .toLowerCase()
                  .trim();

              if (category == 'penerimaan') {
                totalAmount += amount;
              } else if (category == 'potongan') {
                totalAmount -= amount;
              }
            }
          }

          // Determine Status Display
          String statusText = "Status Tidak Diketahui";
          Color statusColor = Colors.grey;

          final String dbStatus =
              slip['status']?.toString().toLowerCase().trim() ?? '';

          if (dbStatus == 'diambil') {
            statusText = "Telah Diambil";
            statusColor = Colors.green;
          } else if (dbStatus == 'belum') {
            statusText = "Segera Diambil";
            statusColor = Colors.orange;
          }

          loadedSlips.add({
            'month': _getMonthName(slip['bulan']),
            'amount': totalAmount,
            'status': statusText,
            'statusColor': statusColor,
            'data': slip,
          });
        }

        if (mounted) {
          setState(() {
            _slipList = loadedSlips;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching slips: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return "";
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

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
                const Icon(
                  Icons.featured_play_list_outlined,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Daftar Slip Gaji",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedYear = newValue;
                          });
                          _fetchSlipGaji();
                        }
                      },
                      items: _years.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Download Button for Yearly Summary
                GestureDetector(
                  onTap: () async {
                    if (_slipList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Tidak ada data untuk tahun ini."),
                        ),
                      );
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final userName = prefs.getString('user_name') ?? "Karyawan";
                    final nip = prefs.getString('nip') ?? "-";

                    PdfHelper.generateAndPrintYearlySummary(
                      year: _selectedYear,
                      slips: _slipList,
                      userName: userName,
                      nip: nip,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. SLIP GAJI LIST
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _slipList.isEmpty
                ? const Center(child: Text("Tidak ada data slip gaji."))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _slipList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final slip = _slipList[index];
                      return GestureDetector(
                        onTap: () {
                          debugPrint(
                            "Navigating to Detail. Month: ${slip['month']}",
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailSlipGajiPage(
                                month: slip['month'],
                                year: _selectedYear,
                                details: slip['data']['slip_gaji_detail'] ?? [],
                              ),
                            ),
                          );
                        },
                        child: _buildSlipGajiCard(
                          month: slip['month'],
                          amount: _formatCurrency(slip['amount']),
                          statusText: slip['status'],
                          statusColor: slip['statusColor'],
                        ),
                      );
                    },
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
