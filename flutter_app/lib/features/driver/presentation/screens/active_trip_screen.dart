/// Active Trip Screen stub — full implementation in Phase 5
library;

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class ActiveTripScreen extends StatelessWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Active Trip: $tripId\n(Phase 5)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
