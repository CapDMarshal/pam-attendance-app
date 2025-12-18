import 'package:flutter/material.dart';
import 'gaji.dart';
import 'absen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4C5BD9); // close to the blue in the design
    const lightBackground = Color(0xFFD8E0EF); // soft gray-blue background

    return MaterialApp(
      title: 'Portal Karyawan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
        ),
        scaffoldBackgroundColor: lightBackground,
        useMaterial3: true,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2156B3),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4C5BD9);
    const topBarColor = Color(0xFFD1DAE9);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with two avatars
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
                    child: Icon(
                      Icons.person_outline,
                      color: Color(0xFF3F60D9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 92),
            // Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Selamat Datang Suyud!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: const Color(0xFF1D54B0),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 92),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _PrimaryPillButton(
                    label: 'Lihat/Cetak Slip Gaji',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GajiPage(),
                      ),
                    ),
                    backgroundColor: primaryBlue,
                  ),
                  const SizedBox(height: 32),
                  _PrimaryPillButton(
                    label: 'Cek Absensi',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AbsensiPage(),
                      ),
                    ),
                    backgroundColor: primaryBlue,
                  ),
                ],
              ),
            ),
            // Fill the rest
            const Expanded(child: SizedBox()),
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

class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  const _PrimaryPillButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

// Placeholder pages removed; now using real pages in gaji.dart and absen.dart
