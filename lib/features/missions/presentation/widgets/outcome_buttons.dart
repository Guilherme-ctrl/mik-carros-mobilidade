import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';
import '../cubit/missions_cubit.dart';
import '../cubit/missions_state.dart';

class OutcomeButtons extends StatefulWidget {
  final Mission mission;
  const OutcomeButtons({super.key, required this.mission});

  @override
  State<OutcomeButtons> createState() => _OutcomeButtonsState();
}

class _OutcomeButtonsState extends State<OutcomeButtons> {
  bool _loading = false;

  Future<void> _setOutcome(bool found) async {
    setState(() => _loading = true);
    final cubit = BlocProvider.of<MissionsCubit>(context);
    // ADR-7 — one symmetric call for both outcomes now (report_car_outcome),
    // replacing the old found/not_found method split.
    await cubit.reportOutcome(
      widget.mission.id,
      found ? RequestOutcome.found.supabaseValue : RequestOutcome.notFound.supabaseValue,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionsCubit, MissionsState>(
      builder: (context, state) {
        final busy = _loading || state is MissionsLoading;
        // Depois de 20260824000002 este par de botões continua na tela mesmo
        // com o desfecho já reportado, porque agora dá para trocá-lo. Sem
        // marcar qual está valendo, o motorista veria dois botões idênticos e
        // não saberia o que já reportou.
        final selected = widget.mission.ownOutcome;
        final foundOn    = selected == RequestOutcome.found;
        final notFoundOn = selected == RequestOutcome.notFound;
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: (selected == null || foundOn)
                      ? AppColors.success
                      : AppColors.surface3,
                  foregroundColor: (selected == null || foundOn)
                      ? Colors.white
                      : AppColors.onSurfaceMuted,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                onPressed: (busy || foundOn) ? null : () => _setOutcome(true),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Achei'),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      notFoundOn ? AppColors.warning : AppColors.onSurfaceMuted,
                  backgroundColor:
                      notFoundOn ? AppColors.statusBusyBg : Colors.transparent,
                  side: BorderSide(
                    color: notFoundOn
                        ? AppColors.warning
                        : AppColors.warning.withValues(alpha: 0.35),
                  ),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                onPressed: (busy || notFoundOn) ? null : () => _setOutcome(false),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Não achei'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OutcomeBadge extends StatelessWidget {
  final RequestOutcome outcome;
  const OutcomeBadge(this.outcome, {super.key});

  @override
  Widget build(BuildContext context) {
    final isFound = outcome == RequestOutcome.found;
    final color = isFound ? AppColors.success : AppColors.warning;
    final bg    = isFound ? AppColors.statusAvailableBg : AppColors.statusBusyBg;
    final label = isFound ? 'Achei' : 'Não achei';
    final icon  = isFound ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
