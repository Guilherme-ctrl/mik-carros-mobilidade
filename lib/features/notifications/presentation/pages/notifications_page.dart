import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! NotificationsLoaded || state.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: AppColors.onSurfaceDisabled,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Nenhuma notificação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
            itemCount: state.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _NotificationTile(notification: state.notifications[index]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    final isMissionAssigned = notification.type == 'mission_assigned';

    return ListTile(
      tileColor: notification.isUnread
          ? AppColors.brandPinkMuted.withValues(alpha: 0.5)
          : null,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: notification.isUnread
              ? AppColors.brandPinkMuted
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          isMissionAssigned ? Icons.directions_car : Icons.update,
          color: notification.isUnread
              ? AppColors.brandPink
              : AppColors.onSurfaceDisabled,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.w400,
          color: notification.isUnread
              ? AppColors.onSurface
              : AppColors.onSurfaceMuted,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            notification.body,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            fmt.format(notification.createdAt.toLocal()),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        BlocProvider.of<NotificationsCubit>(context).markAsRead(notification.id);
        if (notification.requestId != null) {
          Modular.to.navigate('/missions/');
        }
      },
    );
  }
}
