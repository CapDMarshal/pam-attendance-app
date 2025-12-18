import 'package:flutter_test/flutter_test.dart';

import 'package:portal_karyawan/main.dart';

void main() {
  testWidgets('Home UI renders as expected', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Greeting is visible
    expect(find.text('Selamat Datang Suyud!'), findsOneWidget);

    // Primary buttons are visible
    expect(find.text('Lihat/Cetak Slip Gaji'), findsOneWidget);
    expect(find.text('Cek Absensi'), findsOneWidget);
  });
}
