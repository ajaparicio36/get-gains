import 'package:flutter/material.dart';
import 'package:get_gains_online/app/constants/colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/get_gains_with_title.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: Image.asset(
                  'assets/logos/branding.png',
                  width: 300,
                  height: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
