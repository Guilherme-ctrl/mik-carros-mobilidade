import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/cubit/notifications_cubit.dart';
import 'presentation/pages/notifications_page.dart';

class NotificationsModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (_) => BlocProvider.value(
        value: Modular.get<NotificationsCubit>(),
        child: const NotificationsPage(),
      ),
    );
  }
}
