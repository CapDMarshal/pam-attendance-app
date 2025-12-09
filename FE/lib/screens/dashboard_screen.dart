import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'clock_in_screen.dart';
import 'clock_out_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // User Icon/Avatar
              Image.asset(
                'assets/anonim.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 32),

              // App Title
              const Text(
                'Face Recognition',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const Text(
                'Attendance System',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Clock-In Button
              CustomButton(
                text: 'Clock-In',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClockInScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Clock-Out Button
              CustomButton(
                text: 'Clock-Out',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClockOutScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
