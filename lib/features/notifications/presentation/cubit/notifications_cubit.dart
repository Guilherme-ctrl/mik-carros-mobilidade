import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/get_my_notifications.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/watch_notifications.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetMyNotifications _getMyNotifications;
  final MarkAsRead _markAsRead;
  final WatchNotifications _watchNotifications;
  final LocalNotificationService _localNotifications;

  StreamSubscription<AppNotification?>? _realtimeSub;

  // Tipos que merecem interromper o motorista. Deliberadamente NÃO inclui
  // 'mission_queued': o desenho da fila diz que ele só descobre missões futuras
  // por um indicador discreto (FILA-ADR-5), e um alerta na tela seria o oposto
  // disso. Nem 'mission_composition_changed', que é contexto, não chamado.
  static const _alertable = {'mission_assigned', 'comment_added', 'nudge'};

  NotificationsCubit(
    this._getMyNotifications,
    this._markAsRead,
    this._watchNotifications,
    this._localNotifications,
  ) : super(NotificationsInitial());

  Future<void> init() async {
    await _localNotifications.init();
    await _loadNotifications();

    _realtimeSub?.cancel();
    _realtimeSub = _watchNotifications().listen((newNotification) {
      // Antes só 'mission_assigned' virava notificação local, e isso deixava o
      // motorista sem aviso nenhum justamente nos dois casos em que alguém está
      // esperando resposta dele: mensagem no chat e o "cutucar" da Mesa Central.
      // Com o app aberto em outra tela, ambos passavam em silêncio.
      //
      // O push do FCM cobre app fechado ou em background; este caminho cobre o
      // app em primeiro plano, quando o sistema não exibe o push. Os dois não
      // colidem: são estados mutuamente exclusivos do app.
      if (newNotification != null && _alertable.contains(newNotification.type)) {
        _localNotifications.show(newNotification.title, newNotification.body);
      }
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final result = await _getMyNotifications();
    result.fold(
      (_) {},
      (list) => emit(NotificationsLoaded(notifications: list)),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _markAsRead(notificationId);
    await _loadNotifications();
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
