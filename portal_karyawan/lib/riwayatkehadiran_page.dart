import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'daftarkehadiran_page.dart';
import 'utils/pdf_helper.dart';

class RiwayatKehadiranPage extends StatefulWidget {
  const RiwayatKehadiranPage({super.key});

  @override
  State<RiwayatKehadiranPage> createState() => _RiwayatKehadiranPageState();
}

class _RiwayatKehadiranPageState extends State<RiwayatKehadiranPage> {
  bool _isLoading = true;
  List<String> _years = [];
  String _selectedYear = "2025";
  List<Map<String, dynamic>> _monthList = [];
  
  // User Info for PDF
  String _userName = "-";
  String _currentUserNip = "";

  @override
  void initState() {
    super.initState();
    _years = [DateTime.now().year.toString()]; // Default to current year
    _selectedYear = DateTime.now().year.toString();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserName();
    await _fetchAvailableYears();
    // fetchHistory handled inside fetchAvailableYears or after
  }

  Future<void> _fetchUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserNip = prefs.getString('nip') ?? "";
      
      if (_currentUserNip.isNotEmpty) {
        final response = await Supabase.instance.client
            .from('karyawan')
            .select('nama_lengkap')
            .eq('nip', _currentUserNip)
            .maybeSingle();
            
        if (response != null && response['nama_lengkap'] != null) {
          if (mounted) {
            setState(() {
              _userName = response['nama_lengkap'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
  }

  Future<void> _fetchAvailableYears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        // Query to get distinct years? 
        // Supabase doesn't support SELECT DISTINCT year(waktu_clockin) easily without RPC.
        // We'll fetch all clockins (lite select) to extract years.
        
        final response = await Supabase.instance.client
            .from('kehadiran')
            .select('waktu_clockin')
            .eq('nip', nip);

        final Set<String> yearSet = {};
        for (var item in response) {
          if (item['waktu_clockin'] != null) {
            final date = DateTime.parse(item['waktu_clockin']).toLocal();
            yearSet.add(date.year.toString());
          }
        }

        if (yearSet.isNotEmpty) {
          final sortedYears = yearSet.toList()..sort((a, b) => b.compareTo(a)); // Descending
          if (mounted) {
            setState(() {
              _years = sortedYears;
              if (!_years.contains(_selectedYear)) {
                 _selectedYear = _years.first;
              }
            });
            _fetchMonthlySummary();
          }
        } else {
           // No data, keep defaults
           _fetchMonthlySummary();
        }
      }
    } catch (e) {
      debugPrint("Error fetching years: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMonthlySummary() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        final year = int.parse(_selectedYear);
        final startOfYear = DateTime.utc(year, 1, 1);
        final endOfYear = DateTime.utc(year, 12, 31, 23, 59, 59);

        // Fetch all attendance for the selected year
        final response = await Supabase.instance.client
            .from('kehadiran')
            .select('waktu_clockin, status_presensi')
            .eq('nip', nip)
            .gte('waktu_clockin', startOfYear.toIso8601String())
            .lte('waktu_clockin', endOfYear.toIso8601String());

        // Process data locally to group by Month
        // Map<MonthInt, Count>
        final Map<int, int> attendanceCounts = {};
        
        // Initialize 1-12 with 0? Or just existing? 
        // Better to show only months with data or all months up to current?
        // Let's matching slips: show months that have data.
        
        for (var item in response) {
           if (item['waktu_clockin'] != null) {
             final date = DateTime.parse(item['waktu_clockin']).toLocal();
             final month = date.month;
             final status = item['status_presensi']?.toString().toLowerCase().trim();
             
             if (status == 'hadir') {
                attendanceCounts[month] = (attendanceCounts[month] ?? 0) + 1;
             } else {
                // Should we count present only? or all? 
                // "jumlah kehadiran perbulan 22 kali... pengguna telah hadir berapa kali"
                // Implies counting 'Hadir'.
                // Ensure entry exists though
                if (!attendanceCounts.containsKey(month)) {
                  attendanceCounts[month] = 0; 
                }
             }
           }
        }

        final List<Map<String, dynamic>> summaries = [];
        
        // Iterate months in descending order (Dec -> Jan)
        for (int m = 12; m >= 1; m--) {
          if (attendanceCounts.containsKey(m)) {
             final count = attendanceCounts[m]!;
             final double percentage = (count / 22.0).clamp(0.0, 1.0);
             
             summaries.add({
               'monthInt': m,
               'monthName': _getMonthName(m),
               'count': count,
               'percentage': percentage,
             });
          }
        }

        if (mounted) {
          setState(() {
            _monthList = summaries;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    const Color tealColor = Color(0xFF00C9A7); 
    
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
            
            // 2. HEADER
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

            // 3. FILTER ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Year Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _years.contains(_selectedYear) ? _selectedYear : null,
                      hint: Text(_selectedYear),
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
                          _fetchMonthlySummary();
                        }
                      },
                      items: _years.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Download Icon Box (Functionality can be added later)
                GestureDetector(
                  onTap: () {
                     if (_monthList.isNotEmpty) {
                       PdfHelper.generateAndPrintAttendanceYearlySummary(
                         year: _selectedYear,
                         monthList: _monthList,
                         userName: _userName,
                         nip: _currentUserNip,
                       );
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tidak ada data untuk diunduh")),
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

            const SizedBox(height: 20),

            // 4. ATTENDANCE CARDS
            _isLoading 
               ? const Center(child: CircularProgressIndicator())
               : _monthList.isEmpty 
                  ? const Center(child: Text("Tidak ada data kehadiran."))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _monthList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                         final item = _monthList[index];
                         return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DaftarKehadiranPage(
                                  month: item['monthInt'],
                                  year: int.parse(_selectedYear),
                                )),
                              );
                            },
                            child: _buildMonthCard(
                              month: item['monthName'],
                              percentage: item['percentage'],
                              attendanceCount: item['count'],
                              tealColor: tealColor,
                            ),
                         );
                      },
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
        color: Colors.grey.shade200, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
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
                Text(
                  "${(percentage * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),

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