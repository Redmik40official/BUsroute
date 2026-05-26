/// Driver Home Screen stub — full implementation in Phase 5
library;

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Driver Home\n(Phase 5)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
