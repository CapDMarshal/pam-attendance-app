import 'package:flutter/material.dart';
import 'api_service.dart';

class GajiPage extends StatefulWidget {
  const GajiPage({super.key});

  @override
  State<GajiPage> createState() => _GajiPageState();
}

class _GajiPageState extends State<GajiPage> {
  String? _periode;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // TODO: Replace with actual user ID from login
  final String userId = '1';

  // Salary data from API
  int basicSalary = 0;
  int allowances = 0;
  int deductions = 0;
  int netSalary = 0;

  @override
  void initState() {
    super.initState();
    // Set default period to current month
    final now = DateTime.now();
    _periode = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadSalarySlip();
  }

  Future<void> _loadSalarySlip() async {
    if (_periode == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getSalarySlip(userId, _periode!);

      if (response['success'] == true) {
        final slip = response['slip'];
        setState(() {
          basicSalary = slip['basicSalary'] as int;
          allowances = slip['allowances'] as int;
          deductions = slip['deductions'] as int;
          netSalary = slip['netSalary'] as int;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to load salary slip',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading salary: $e')));
      }
    }
  }

  String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
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
            // Top bar with logo left and person icon right
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
            // Back arrow
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),

            // Periode dropdown + download button
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
                          value: _periode,
                          hint: const Text(
                            'Pilih Periode Gaji',
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
                          ],
                          onChanged: (v) {
                            setState(() => _periode = v);
                            _loadSalarySlip();
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

            const SizedBox(height: 20),

            // Table container
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
                          child: _SlipTable(
                            basicSalary: basicSalary,
                            allowances: allowances,
                            deductions: deductions,
                            netSalary: netSalary,
                            formatCurrency: formatCurrency,
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

class _SlipTable extends StatelessWidget {
  final int basicSalary;
  final int allowances;
  final int deductions;
  final int netSalary;
  final String Function(int) formatCurrency;

  const _SlipTable({
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    const th = TextStyle(fontWeight: FontWeight.w400, color: Colors.black87);
    const td = TextStyle(color: Colors.black87, fontSize: 11);
    const section = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    const totalBold = TextStyle(fontWeight: FontWeight.w700);

    Table header() => Table(
      columnWidths: const {
        0: FixedColumnWidth(36),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: const [
        TableRow(
          children: [
            _Cell('No.', style: th),
            _Cell('Kategori', style: th),
            _Cell('Komponen Gaji', style: th),
            _Cell('Jumlah (Rp)', align: TextAlign.right, style: th),
          ],
        ),
      ],
    );

    Table items(List<List<String>> rows) => Table(
      columnWidths: const {
        0: FixedColumnWidth(36),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final r in rows)
          TableRow(
            children: [
              const SizedBox.shrink().withCell(text: r[0], style: td),
              const SizedBox.shrink().withCell(text: r[1], style: td),
              const SizedBox.shrink().withCell(text: r[2], style: td),
              const SizedBox.shrink().withCell(
                text: r[3],
                style: td,
                align: TextAlign.right,
              ),
            ],
          ),
      ],
    );

    Widget fullSpanTitle(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: section,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );

    Widget fullSpanTotal(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: totalBold,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ),
          Text(value, style: totalBold),
        ],
      ),
    );

    Widget spacerH(double h) => SizedBox(height: h);

    final totalGross = basicSalary + allowances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(),
        spacerH(6),
        fullSpanTitle('Penerimaan'),
        items([
          ['1.', 'PENDAPATAN', 'Gaji Pokok', formatCurrency(basicSalary)],
          ['2.', 'PENDAPATAN', 'Tunjangan', formatCurrency(allowances)],
        ]),
        spacerH(8),
        fullSpanTotal('TOTAL KOTOR', formatCurrency(totalGross)),
        spacerH(12),
        fullSpanTitle('Potongan'),
        items([
          ['3.', 'POTONGAN', 'Total Potongan', formatCurrency(deductions)],
        ]),
        spacerH(8),
        fullSpanTotal('TOTAL POTONGAN', formatCurrency(deductions)),
        spacerH(8),
        fullSpanTotal('GAJI BERSIH (THP)', formatCurrency(netSalary)),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final TextAlign align;
  final TextStyle? style;
  const _Cell(this.text, {this.align = TextAlign.left, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(text, textAlign: align, style: style),
    );
  }
}

extension _SizedBoxCell on SizedBox {
  TableCell withCell({
    required String text,
    TextStyle? style,
    TextAlign align = TextAlign.left,
  }) {
    return TableCell(
      child: _Cell(text, align: align, style: style),
    );
  }
}
