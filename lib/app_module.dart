import 'package:flutter_modular/flutter_modular.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/location_service.dart';
import 'features/auth/auth_module.dart';
import 'features/location/domain/usecases/start_location_tracking.dart';
import 'features/location/domain/usecases/stop_location_tracking.dart';
import 'features/missions/missions_module.dart';
import 'features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/domain/usecases/get_my_notifications.dart';
import 'features/notifications/domain/usecases/mark_as_read.dart';
import 'features/notifications/domain/usecases/watch_notifications.dart';
import 'features/car_chat/car_chat_module.dart';
import 'features/notifications/notifications_module.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<LocationService>(LocationService.new);
    i.addSingleton<StartLocationTracking>(StartLocationTracking.new);
    i.addSingleton<StopLocationTracking>(StopLocationTracking.new);
    // Notifications — registered globally so MissionsPage badge can access the cubit
    i.addSingleton<LocalNotificationService>(LocalNotificationService.new);
    i.addSingleton<NotificationsRemoteDatasource>(NotificationsRemoteDatasourceImpl.new);
    i.addSingleton<NotificationsRepository>(NotificationsRepositoryImpl.new);
    i.addSingleton<GetMyNotifications>(GetMyNotifications.new);
    i.addSingleton<MarkAsRead>(MarkAsRead.new);
    i.addSingleton<WatchNotifications>(WatchNotifications.new);
    i.addSingleton<NotificationsCubit>(NotificationsCubit.new);
  }

  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule());
    r.module('/missions', module: MissionsModule());
    r.module('/notifications', module: NotificationsModule());
    r.module('/car-chat', module: CarChatModule());
    r.redirect('/', to: '/auth/splash');
  }
}
