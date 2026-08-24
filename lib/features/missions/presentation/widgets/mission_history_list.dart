import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';

class MissionHistoryList extends StatelessWidget {
  final List<Mission> missions;

  const MissionHistoryList({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s1,
          ),
          child: Text(
            'HISTÓRICO DO DIA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceDisabled,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...missions.map((m) => _HistoryTile(mission: m)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Mission mission;
  const _HistoryTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    // History entries only ever come from getMissionsHistoryForCar
    // (removal_reason IS NULL — a natural mission closure, ADR-5), so the
    // found/not_found split is the meaningful distinction here, not a
    // completed-vs-cancelled one (cancelled/explicitly-removed rows carry
    // removal_reason='removed' and never reach this list).
    final isCompleted = mission.ownOutcome == RequestOutcome.found;
    final time = DateFormat('HH:mm').format(mission.createdAt.toLocal());

    return ListTile(
      dense: true,
      leading: Icon(
        isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined,
        color: isCompleted ? AppColors.statusAvailable : AppColors.statusUnavailable,
        size: 20,
      ),
      title: Text(
        mission.event,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Prova ${mission.stage} · ${mission.neighborhood}',
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
