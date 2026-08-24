import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';
import '../cubit/missions_cubit.dart';

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

class _HistoryTile extends StatefulWidget {
  final Mission mission;
  const _HistoryTile({required this.mission});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _reopening = false;

  // Reabrir (20260824000004). Fica aqui, no histórico, porque é exatamente
  // onde o motorista percebe o engano: a missão sumiu da tela principal e
  // reapareceu na lista de encerradas com o desfecho errado.
  Future<void> _confirmAndReopen() async {
    final mission = widget.mission;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Reabrir missão?'),
        content: Text(
          'O desfecho de "${mission.event}" será apagado e a missão volta a '
          'ficar em andamento. Se o seu carro já tiver sido designado para '
          'outra missão, ele não volta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _reopening = true);
    final result =
        await BlocProvider.of<MissionsCubit>(context).reopenMission(mission.id);
    if (!mounted) return;
    setState(() => _reopening = false);

    if (result == null) return;   // o cubit já emitiu MissionsError

    // O resultado precisa ser dito: "reabri e nada aconteceu na minha tela" é
    // exatamente o que acontece quando o carro já foi para outra missão.
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(
        result.needsReassignment
            ? 'Missão reaberta, mas seu carro já está em outra. A Mesa Central precisa reatribuir.'
            : 'Missão reaberta com ${result.restored.join(", ")}.',
      ),
      duration: const Duration(seconds: 6),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(time, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 4),
          _reopening
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _confirmAndReopen,
                  icon: const Icon(Icons.undo, size: 18),
                  color: AppColors.onSurfaceMuted,
                  tooltip: 'Reabrir missão',
                  visualDensity: VisualDensity.compact,
                ),
        ],
      ),
    );
  }
}
