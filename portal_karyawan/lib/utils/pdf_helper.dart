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
}
