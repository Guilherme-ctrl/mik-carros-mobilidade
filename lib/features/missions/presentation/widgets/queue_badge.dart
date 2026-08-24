// `hide State`: dartz exports a State monad whose name collides with Flutter's
// State, and this is the first widget in the app to need both libraries.
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/entities/queue_summary.dart';
import '../../domain/usecases/watch_queue_count.dart';
import 'queue_summary_expansion.dart';

// US4/FR5 — "+N more coming", and nothing else, until a mission is promoted.
//
// StatefulWidget because the expanded/collapsed toggle is local state. Its
// parent (ActiveMissionCard) stays a StatelessWidget: a stateful child does not
// oblige the parent to become stateful, and keeping the state here also keeps
// the blast radius here (a failing queue read hides this widget and touches
// nothing else on the screen).
class QueueBadge extends StatefulWidget {
  final String carId;

  const QueueBadge({super.key, required this.carId});

  @override
  State<QueueBadge> createState() => _QueueBadgeState();
}

class _QueueBadgeState extends State<QueueBadge> {
  late final WatchQueueCount _watchQueueCount;
  late Stream<Either<Failure, QueueSummary>> _queueStream;

  bool _expanded = false;
  String? _lastLoggedError;

  @override
  void initState() {
    super.initState();
    // Same DI convention as CommentsSection: resolve from Modular in initState.
    _watchQueueCount = Modular.get<WatchQueueCount>();
    _queueStream = _watchQueueCount(widget.carId);
  }

  @override
  void didUpdateWidget(QueueBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The stream is built in initState, not in build, because listening to it
    // opens a Realtime channel — rebuilding it per frame would churn
    // subscriptions. That makes carId the one prop we must react to, or the
    // badge would keep reporting the previous car's queue.
    if (oldWidget.carId != widget.carId) {
      setState(() {
        _queueStream = _watchQueueCount(widget.carId);
        _expanded = false;
        _lastLoggedError = null;
      });
    }
  }

  // Construction guardrail: a failure at an integration boundary is never
  // swallowed. The driver sees nothing (the badge is non-critical, and a raw
  // error string on the mission screen would be worse than its absence), but
  // the failure is always logged. De-duplicated on the message because
  // StreamBuilder's builder re-runs on every parent rebuild with the same
  // snapshot, and one fault should not produce an unbounded log.
  void _logFailure(Failure failure) {
    if (_lastLoggedError == failure.message) return;
    _lastLoggedError = failure.message;
    debugPrint(
      '[QueueBadge] falha ao observar a fila do carro ${widget.carId}: ${failure.message}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, QueueSummary>>(
      stream: _queueStream,
      builder: (context, snapshot) {
        final result = snapshot.data;
        // No emission yet — deliberately no spinner. An indeterminate badge
        // would draw the eye to a non-critical counter on a screen whose job is
        // the current mission.
        if (result == null) return const SizedBox.shrink();

        return result.fold(
          (failure) {
            _logFailure(failure);
            return const SizedBox.shrink();
          },
          (summary) {
            _lastLoggedError = null;
            // FR5.1/FR5.4 — threshold lives on the entity so it is unit-tested.
            // Aparece a partir de UMA missão na fila (era 2 até 2026-08-24).
            if (!summary.showsBadge) return const SizedBox.shrink();
            return _buildBadge(context, summary);
          },
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context, QueueSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leading gap lives here, not in ActiveMissionCard: the parent cannot
        // know whether this widget will render, and a SizedBox on its side
        // would leave a stray gap in the (common) no-badge case.
        const SizedBox(height: AppSpacing.s2),
        // Right-aligned so it reads as part of the header line it sits under,
        // next to the status chip. The badge is not placed INSIDE that Row (as
        // a literal reading of frontend-components.md's hierarchy would put it)
        // because the expansion below needs the card's full width, and a Row
        // child cannot grow past the space the title leaves it.
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            key: const ValueKey('queue-badge-toggle'),
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brandPinkMuted,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.brandPink.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers_outlined,
                      size: 14, color: AppColors.brandPinkLight),
                  const SizedBox(width: 4),
                  Text(
                    // FR5.3 — the count, with no detail attached to it.
                    '+${summary.totalCount}',
                    style: const TextStyle(
                      color: AppColors.brandPinkLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.brandPinkLight,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.s3),
          QueueSummaryExpansion(items: summary.items),
        ],
      ],
    );
  }
}
