import 'package:flutter/material.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/queue_summary.dart';

// FR5.5 — the summarised list the driver gets after tapping the badge. Renders
// from the QueueSummary already in memory (the one that fed the counter), so
// expanding costs no network call.
class QueueSummaryExpansion extends StatelessWidget {
  final List<QueueSummaryItemData> items;

  const QueueSummaryExpansion({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // Com o limiar do badge em 1 (2026-08-24), a fila de UMA missão
          // deixou de ser um caso raro e virou o caso comum — o plural fixo
          // passou a destoar na tela que o motorista mais vê.
          items.length == 1 ? 'PRÓXIMA NA FILA' : 'PRÓXIMAS NA FILA',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceDisabled,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: AppSpacing.s2),
        // Index order is the RPC's order (priority DESC, request created_at
        // ASC) — the same ordering the promotion algorithm uses, so position N
        // here really is the Nth mission this car will be given. Never re-sort
        // client-side: that would let the list disagree with reality.
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s2),
          QueueSummaryItem(position: i + 1, item: items[i]),
        ],
      ],
    );
  }
}

// FR5.5/FR5.6 — one queued mission, summarised.
//
// What is NOT here is the point: no event name, no address, no objective, no
// Líder, and no action button. Those details only become visible when the
// mission is promoted to current. The widget cannot leak them even by mistake,
// because QueueSummaryItemData does not carry them (FILA-ADR-5).
class QueueSummaryItem extends StatelessWidget {
  // 1-based position in the queue, computed client-side from the list index.
  // Deliberately not a backend field: the RPC returns no label of any kind, and
  // position is derivable from an order it already guarantees.
  final int position;
  final QueueSummaryItemData item;

  const QueueSummaryItem({
    super.key,
    required this.position,
    required this.item,
  });

  static const _priorityFg = {
    QueuePriority.alta:   AppColors.statusUnavailable,
    QueuePriority.normal: AppColors.onSurfaceMuted,
    QueuePriority.baixa:  AppColors.statusPending,
  };

  static const _priorityBg = {
    QueuePriority.alta:   AppColors.statusUnavailableBg,
    QueuePriority.normal: AppColors.surface2,
    QueuePriority.baixa:  AppColors.statusPendingBg,
  };

  @override
  Widget build(BuildContext context) {
    final fg = _priorityFg[item.priority] ?? AppColors.onSurfaceMuted;
    final bg = _priorityBg[item.priority] ?? AppColors.surface2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceMuted),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              '$positionª da fila',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: fg.withValues(alpha: 0.4)),
            ),
            child: Text(
              item.priority.label.toUpperCase(),
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
