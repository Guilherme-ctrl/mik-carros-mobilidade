import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';
import '../cubit/missions_cubit.dart';
import '../cubit/missions_state.dart';

class MissionActionButton extends StatelessWidget {
  final Mission mission;

  const MissionActionButton({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    // ownStatus, not the request-level status — FR7: this button only ever
    // advances THIS car's own progress (update_car_status), never the whole
    // mission. "returning"'s next step is reporting an outcome (FR6.1), not
    // another status transition, so nextDriverStatus is null there and
    // ActiveMissionCard shows OutcomeButtons instead.
    final next = mission.ownStatus.nextDriverStatus;
    if (next == null) return const SizedBox.shrink();

    return BlocBuilder<MissionsCubit, MissionsState>(
      builder: (context, state) {
        final isLoading = state is MissionsLoading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPink,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            onPressed: isLoading
                ? null
                : () => BlocProvider.of<MissionsCubit>(context)
                    .updateStatus(mission.id, next.supabaseValue),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(mission.ownStatus.actionLabel),
          ),
        );
      },
    );
  }
}
