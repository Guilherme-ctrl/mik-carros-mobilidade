import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/comment.dart';

class CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isOwn;
  final bool showAuthor;

  const CommentBubble({
    super.key,
    required this.comment,
    required this.isOwn,
    this.showAuthor = true,
  });

  static String _formatBRT(DateTime utc) {
    final brt = utc.toUtc().subtract(const Duration(hours: 3));
    return DateFormat('HH:mm').format(brt);
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

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: isOwn ? AppColors.brandPinkMuted : AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isOwn ? AppRadius.lg : AppRadius.xs),
            topRight: Radius.circular(isOwn ? AppRadius.xs : AppRadius.lg),
            bottomLeft: const Radius.circular(AppRadius.lg),
            bottomRight: const Radius.circular(AppRadius.lg),
          ),
          border: Border.all(
            color: isOwn
                ? AppColors.brandPink.withValues(alpha: 0.4)
                : AppColors.surface3,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwn && showAuthor) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.brandPinkMuted,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: AppColors.brandPinkLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s1),
                  Text(
                    comment.authorName,
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.brandPinkLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              comment.content,
              style: tt.bodySmall?.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              _formatBRT(comment.createdAt),
              style: tt.labelSmall?.copyWith(
                color: AppColors.onSurfaceDisabled,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}
