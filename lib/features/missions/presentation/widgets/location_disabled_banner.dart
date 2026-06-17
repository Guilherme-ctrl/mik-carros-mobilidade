import 'package:flutter/material.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';

class LocationDisabledBanner extends StatelessWidget {
  const LocationDisabledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.statusBusyBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              'Localização desativada — Mesa Central não consegue ver sua posição',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
