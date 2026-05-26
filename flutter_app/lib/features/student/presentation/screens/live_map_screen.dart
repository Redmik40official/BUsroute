/// Live Map Screen stub — full implementation in Phase 7
library;

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class LiveMapScreen extends StatelessWidget {
  final String routeId;
  final String routeName;
  final String routeColor;

  const LiveMapScreen({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.routeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Live Map — $routeName\n(Phase 7)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
