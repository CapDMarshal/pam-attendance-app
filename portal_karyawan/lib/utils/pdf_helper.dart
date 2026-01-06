import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfHelper {
  static Future<void> generateAndPrintSlip({
    required String month,
    required String year,
    required List<dynamic> details,
    required String userName,
    required String nip,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final incomes = details.where((d) => d['kategori'].toString().toLowerCase().trim() == 'penerimaan').toList();
    final deductions = details.where((d) => d['kategori'].toString().toLowerCase().trim() == 'potongan').toList();

    double totalIncome = incomes.fold(0, (sum, item) => sum + (item['jumlah'] is num ? item['jumlah'] : double.tryParse(item['jumlah'].toString()) ?? 0));
    double totalDeduction = deductions.fold(0, (sum, item) => sum + (item['jumlah'] is num ? item['jumlah'] : double.tryParse(item['jumlah'].toString()) ?? 0));
    double netSalary = totalIncome - totalDeduction;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("SLIP GAJI", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("PAM ATTENDANCE", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Portal Karyawan", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Nama: $userName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("NIP: $nip"),
                      ],
                    ),
                    pw.Text("Periode: $month $year", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ... (Detailed Rows Logic Identical to before, kept concise here to fit)
              pw.Row(
                children: [
                  pw.SizedBox(width: 30, child: pw.Text("No", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("Kategori", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 4, child: pw.Text("Komponen Gaji", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text("Jumlah(Rp)", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Divider(),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.Text("PENERIMAAN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
              ),
              if (incomes.isEmpty) pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("- Tidak ada data -")),
              ...incomes.asMap().entries.map((entry) => _buildPdfRow(
                (entry.key + 1).toString(), "Penerimaan", entry.value['nama_komponen'] ?? '-', _formatCurrency(entry.value['jumlah']))),
              pw.SizedBox(height: 5),
              _buildTotalRow("TOTAL KOTOR", _formatCurrency(totalIncome), isBold: true),
              pw.Divider(),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.Text("POTONGAN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
              ),
              if (deductions.isEmpty) pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("- Tidak ada data -")),
               ...deductions.asMap().entries.map((entry) => _buildPdfRow(
                (incomes.length + entry.key + 1).toString(), "Potongan", entry.value['nama_komponen'] ?? '-', _formatCurrency(entry.value['jumlah']))),
              pw.SizedBox(height: 5),
              _buildTotalRow("TOTAL POTONGAN", _formatCurrency(totalDeduction), isBold: true),
              pw.Divider(thickness: 2),

              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("GAJI BERSIH (THP)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatCurrency(netSalary), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.Spacer(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Dicetak Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}"),
                      pw.SizedBox(height: 40),
                      pw.Text("( HRD Manager )", style: const pw.TextStyle(color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Slip_Gaji_${month}_${year}_$nip',
    );
  }

  static Future<void> generateAndPrintYearlySummary({
    required String year,
    required List<Map<String, dynamic>> slips,
    required String userName,
    required String nip,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final List<List<String>> tableData = [];
    double grandTotal = 0;

    for (var slip in slips) {
        // Recalculate or use pre-calculated amount if trusted
        // We'll trust the 'amount' field passed from UI logic for simplicity and consistency
        final double amount = (slip['amount'] is num) ? (slip['amount'] as num).toDouble() : 0.0;
        grandTotal += amount;
        
        tableData.add([
           slip['month'].toString(),
           slip['status'].toString(),
           _formatCurrency(amount),
        ]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("REKAPITULASI GAJI", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("PAM ATTENDANCE", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Portal Karyawan", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
               pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Nama: $userName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("NIP: $nip"),
                      ],
                    ),
                    pw.Text("Tahun: $year", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: ['Bulan', 'Status', 'Gaji Bersih (THP)'],
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {2: pw.Alignment.centerRight},
              ),
              
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Text("TOTAL TAHUN $year", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_formatCurrency(grandTotal), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ]
              ),

              pw.Spacer(),
               pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Dicetak Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}"),
                      pw.SizedBox(height: 40),
                      pw.Text("( HRD Manager )", style: const pw.TextStyle(color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

     await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Gaji_${year}_$nip',
    );
  }

  static pw.Widget _buildPdfRow(String no, String category, String component, String amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 30, child: pw.Text(no)),
          pw.Expanded(flex: 2, child: pw.Text(category)),
          pw.Expanded(flex: 4, child: pw.Text(component)),
          pw.Expanded(
            flex: 3,
            child: pw.Text(amount, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(amount, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  static String _formatCurrency(dynamic amount) {
    double value = 0.0;
    if (amount is num) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 2);
    return format.format(value);
  }

  // --- ATTENDANCE REPORTS ---

  static Future<void> generateAndPrintAttendanceReport({
    required String monthYear,
    required List<Map<String, dynamic>> attendanceData,
    required String userName,
    required String nip,
    required int totalPresence,
    required double percentage,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final List<List<String>> tableData = [];
    for (var item in attendanceData) {
      tableData.add([
        item['date'].toString(),
        item['in'].toString(),
        item['out'].toString(),
        item['status'].toString(),
      ]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               _buildHeader("LAPORAN ABSENSI", "PAM ATTENDANCE", "Portal Karyawan"),
               pw.SizedBox(height: 20),
               
               // Info Box
               pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Nama: $userName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("NIP: $nip"),
                      ],
                    ),
                    pw.Text("Periode: $monthYear", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Stats
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text("Total Kehadiran: $totalPresence x (${(percentage * 100).toInt()}%)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 10),

              // Table
              pw.TableHelper.fromTextArray(
                headers: ['Tanggal', 'Masuk', 'Pulang', 'Status'],
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight
                },
              ),
              
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Absensi_${monthYear}_$nip',
    );
  }

  static Future<void> generateAndPrintAttendanceYearlySummary({
    required String year,
    required List<Map<String, dynamic>> monthList, // Expected: monthName, count, percentage
    required String userName,
    required String nip,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final List<List<String>> tableData = [];
    int totalPresenceYear = 0;

    for (var item in monthList) {
        final int count = (item['count'] is num) ? (item['count'] as num).toInt() : 0;
        final double pct = (item['percentage'] is num) ? (item['percentage'] as num).toDouble() : 0.0;
        totalPresenceYear += count;

        tableData.add([
           item['monthName'].toString(),
           "$count x",
           "${(pct * 100).toInt()}%",
        ]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               _buildHeader("REKAPITULASI ABSENSI", "PAM ATTENDANCE", "Portal Karyawan"),
               pw.SizedBox(height: 20),
               
               // Info Box
               pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Nama: $userName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("NIP: $nip"),
                      ],
                    ),
                    pw.Text("Tahun: $year", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.TableHelper.fromTextArray(
                headers: ['Bulan', 'Jumlah Kehadiran', 'Persentase'],
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight
                },
              ),
              
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Text("TOTAL KEHADIRAN TAHUN $year", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text("$totalPresenceYear x", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ]
              ),

              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Absensi_${year}_$nip',
    );
  }

  // --- REUSABLE COMPONENTS ---

  static pw.Widget _buildHeader(String title, String sub1, String sub2) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(sub1, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(sub2, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
     return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text("Dicetak Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}"),
            pw.SizedBox(height: 40),
            pw.Text("( HRD Manager )", style: const pw.TextStyle(color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }
}
