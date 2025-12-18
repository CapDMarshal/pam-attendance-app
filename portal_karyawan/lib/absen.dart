import 'package:flutter/material.dart';
import 'api_service.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  String? _bulan;
  List<_AbsenRow> _data = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // TODO: Replace with actual user ID from login
  final String userId = '1';

  @override
  void initState() {
    super.initState();
    // Set default month to current month
    final now = DateTime.now();
    _bulan = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (_bulan == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUserAttendanceByMonth(
        userId,
        _bulan!,
      );

      if (response['success'] == true) {
        final records = response['records'] as List;
        setState(() {
          _data = records.map((record) {
            final timestamp = record['timestamp'] as String;
            final date = DateTime.parse(timestamp);
            final dateStr =
                '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
            final timeStr =
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            final type = record['type'] as String;

            // Determine status based on type
            String status = 'Hadir';
            if (type == 'clock-in') {
              status = 'Masuk';
            } else if (type == 'clock-out') {
              status = 'Pulang';
            }

            return _AbsenRow(dateStr, timeStr, '-', status);
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _data = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _data = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const topBarColor = Color(0xFFD1DAE9);
    const primaryBlue = Color(0xFF4C5BD9);

    return Scaffold(
      backgroundColor: const Color(0xFFD8E0EF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Container(
              height: 56,
              color: topBarColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _CircleBox(
                    child: Image(
                      image: AssetImage('lib/assets/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  _CircleBox(
                    child: Icon(Icons.person_outline, color: Color(0xFF3F60D9)),
                  ),
                ],
              ),
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),

            // Filter bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _bulan,
                          hint: const Text(
                            'Pilih Bulan',
                            style: TextStyle(fontSize: 16),
                          ),
                          icon: const Icon(Icons.expand_more),
                          items: const [
                            DropdownMenuItem(
                              value: '2025-12',
                              child: Text('Desember 2025'),
                            ),
                            DropdownMenuItem(
                              value: '2025-11',
                              child: Text('November 2025'),
                            ),
                            DropdownMenuItem(
                              value: '2025-10',
                              child: Text('Oktober 2025'),
                            ),
                            DropdownMenuItem(
                              value: '2025-09',
                              child: Text('September 2025'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _bulan = v);
                            _loadAttendance();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {},
                      child: const Icon(
                        Icons.download_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Table card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 350),
                            child: _AbsensiTable(data: _data),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBox extends StatelessWidget {
  final Widget child;
  const _CircleBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF5E7AE9).withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6),
      child: Center(child: child),
    );
  }
}

class _AbsensiTable extends StatelessWidget {
  final List<_AbsenRow> data;
  const _AbsensiTable({required this.data});

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':
        return const Color(0xFF2E7D32); // green
      case 'Izin':
        return const Color(0xFF1976D2); // blue
      case 'Sakit':
        return const Color(0xFFEF6C00); // orange
      default:
        return const Color(0xFFC62828); // red for Alfa/others
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    const cellStyle = TextStyle(color: Colors.black87);

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 48,
      columns: const [
        DataColumn(label: Text('Tanggal', style: headerStyle)),
        DataColumn(label: Text('Masuk', style: headerStyle)),
        DataColumn(label: Text('Pulang', style: headerStyle)),
        DataColumn(label: Text('Status', style: headerStyle)),
      ],
      rows: data
          .map(
            (e) => DataRow(
              cells: [
                DataCell(Text(e.tanggal, style: cellStyle)),
                DataCell(Text(e.masuk, style: cellStyle)),
                DataCell(Text(e.pulang, style: cellStyle)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(e.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      e.status,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _statusColor(e.status),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _AbsenRow {
  final String tanggal;
  final String masuk;
  final String pulang;
  final String status;
  const _AbsenRow(this.tanggal, this.masuk, this.pulang, this.status);
}
