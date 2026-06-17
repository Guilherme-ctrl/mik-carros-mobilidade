import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/comment.dart';

class CommentBubble extends StatelessWidget {
  final Comment comment;

  const CommentBubble({super.key, required this.comment});

  static String _formatBRT(DateTime utc) {
    // BRT = UTC-3, fixed offset (Brazil abolished DST in 2019)
    final brt = utc.toUtc().subtract(const Duration(hours: 3));
    return DateFormat('dd/MM HH:mm').format(brt);
  }

  String get _initials {
    final parts = comment.authorName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.brandPinkMuted,
          child: Text(
            _initials,
            style: const TextStyle(
              color: AppColors.brandPinkLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    _formatBRT(comment.createdAt),
                    style: tt.labelSmall?.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: tt.bodySmall?.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
