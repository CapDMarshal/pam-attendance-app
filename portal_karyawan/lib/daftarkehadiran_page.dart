import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'utils/pdf_helper.dart';

class DaftarKehadiranPage extends StatefulWidget {
  final int? month;
  final int? year;

  const DaftarKehadiranPage({super.key, this.month, this.year});

  @override
  State<DaftarKehadiranPage> createState() => _DaftarKehadiranPageState();
}

class _DaftarKehadiranPageState extends State<DaftarKehadiranPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceList = [];

  // Statistics
  int _totalHadir = 0;
  int _totalIzin = 0;
  int _totalSakit = 0;
  int _totalAlpa = 0;
  int _totalAttendanceCount = 0;
  double _attendancePercentage = 0.0;
  String _currentMonthName = "";

  // User Info for PDF
  String _userName = "-";
  String _currentUserNip = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final now = DateTime.now();
    final targetMonth = widget.month ?? now.month;
    final targetYear = widget.year ?? now.year;

    // Set month name based on target
    _currentMonthName = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime(targetYear, targetMonth));
    await _fetchUserName();
    await _fetchAttendanceData(targetMonth, targetYear);
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

  Future<void> _fetchAttendanceData(int month, int year) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nip = prefs.getString('nip');

      if (nip != null) {
        final startOfMonth = DateTime.utc(year, month, 1);
        final lastDay = DateTime.utc(year, month + 1, 0).day;
        final endOfMonth = DateTime.utc(year, month, lastDay, 23, 59, 59);

        // Fetch data for target month
        // Fetch data for target month
        // We now filter by 'tanggal' to include records that might have null waktu_clockin (like manual Sakit/Izin)
        // Format: YYYY-MM-DD
        final String startStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
        final String endStr = DateFormat('yyyy-MM-dd').format(endOfMonth);

        final response = await Supabase.instance.client
            .from('kehadiran')
            .select()
            .eq('nip', nip)
            .gte('tanggal', startStr)
            .lte('tanggal', endStr)
            .order('tanggal', ascending: false);

        int hadir = 0;
        int izin = 0;
        int sakit = 0;
        int alpa = 0;

        final List<Map<String, dynamic>> mappedList = [];

        for (var record in response) {
          final String status =
              record['status_presensi']?.toString().toLowerCase().trim() ??
              'alpha';
          final String? clockInStr = record['waktu_clockin'];
          final String? clockOutStr = record['waktu_clockout'];
          final String? tanggalStr = record['tanggal'];

          DateTime? clockInTime;
          if (clockInStr != null) {
            clockInTime = DateTime.parse(clockInStr).toLocal();
          }

          DateTime? clockOutTime;
          if (clockOutStr != null) {
            clockOutTime = DateTime.parse(clockOutStr).toLocal();
          }

          // Count Stats
          if (status == 'hadir') {
            hadir++;
          } else if (status == 'izin') {
            izin++;
          } else if (status == 'sakit') {
            sakit++;
          } else if (status == 'alpha') {
            alpa++;
          }

          // Format Date: Use tanggal column if available, else clockin, else today
          String formattedDate = "-";
          if (tanggalStr != null) {
            try {
              final d = DateTime.parse(tanggalStr);
              formattedDate = DateFormat('dd-MM-yyyy').format(d);
            } catch (_) {}
          } else if (clockInTime != null) {
            formattedDate = DateFormat('dd-MM-yyyy').format(clockInTime);
          }

          final String formattedIn = clockInTime != null
              ? DateFormat('HH:mm').format(clockInTime)
              : "-";
          final String formattedOut = clockOutTime != null
              ? DateFormat('HH:mm').format(clockOutTime)
              : "-";

          // Determine Display Status and Color
          String displayStatus = "Alpha";
          Color statusColor = Colors.red;

          if (status == 'hadir') {
            displayStatus = "Hadir";
            statusColor = Colors.green;
          } else if (status == 'izin') {
            displayStatus = "Izin";
            statusColor = Colors.blue;
          } else if (status == 'sakit') {
            displayStatus = "Sakit";
            statusColor = Colors.orange;
          }

          mappedList.add({
            'date': formattedDate,
            'in': formattedIn,
            'out': formattedOut,
            'status': displayStatus,
            'color': statusColor,
          });
        }

        // Calculate Percentage: (Hadir / 22) * 100
        const int workingDaysTarget = 22;
        double percentage = (hadir / workingDaysTarget);
        if (percentage > 1.0) percentage = 1.0; // Cap at 100%

        if (mounted) {
          setState(() {
            _attendanceList = mappedList;
            _totalHadir = hadir;
            _totalIzin = izin;
            _totalSakit = sakit;
            _totalAlpa = alpa;
            _totalAttendanceCount = hadir;
            _attendancePercentage = percentage;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
            // 2. HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _currentMonthName.isNotEmpty
                          ? _currentMonthName
                          : "Bulan Ini",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Download Icon Box in Wrapped in Gesture Detector
                GestureDetector(
                  onTap: () {
                    if (_attendanceList.isNotEmpty) {
                      PdfHelper.generateAndPrintAttendanceReport(
                        monthYear: _currentMonthName,
                        attendanceData: _attendanceList,
                        userName: _userName,
                        nip: _currentUserNip,
                        totalPresence: _totalAttendanceCount,
                        percentage: _attendancePercentage,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Tidak ada data untuk diunduh"),
                        ),
                      );
                    }
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
                  Text(
                    "${(_attendancePercentage * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _attendancePercentage,
                      minHeight: 12,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        tealColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // "Jumlah Kehadiran" Text
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Jumlah Kehadiran:               ${_totalAttendanceCount}x",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Four Stats Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox("Hadir", _totalHadir.toString()),
                      _buildStatBox("Izin", _totalIzin.toString()),
                      _buildStatBox("Sakit", _totalSakit.toString()),
                      _buildStatBox("Alpa", _totalAlpa.toString()),
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
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Tanggal",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Masuk",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Pulang",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1),

            // 5. DATA ROWS
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _attendanceList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text("Belum ada data absensi bulan ini."),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attendanceList.length,
                    itemBuilder: (context, index) {
                      final item = _attendanceList[index];
                      return _buildLogItem(
                        item['date'],
                        item['in'],
                        item['out'],
                        item['status'],
                        item['color'],
                      );
                    },
                  ),
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
          Text(
            count,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Helper for the table rows
  Widget _buildLogItem(
    String date,
    String inTime,
    String outTime,
    String status,
    Color statusColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(date, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text(inTime, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text(outTime, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
