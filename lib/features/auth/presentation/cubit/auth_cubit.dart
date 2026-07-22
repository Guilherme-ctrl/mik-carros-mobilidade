import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/update_push_token.dart';
import '../../../../features/location/domain/usecases/start_location_tracking.dart';
import '../../../../features/location/domain/usecases/stop_location_tracking.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithEmail _signIn;
  final SignOut _signOut;
  final GetCurrentSession _getSession;
  final UpdatePushToken _updatePushToken;

  StreamSubscription<String>? _tokenRefreshSub;

  AuthCubit(this._signIn, this._signOut, this._getSession, this._updatePushToken)
      : super(AuthInitial());

  Future<void> checkSession() async {
    emit(AuthLoading());
    final result = await _getSession();
    result.fold(
      (_) => emit(Unauthenticated()),
      (session) {
        if (session != null) {
          Modular.get<StartLocationTracking>()();
          _setupPushNotifications();
          emit(Authenticated(session));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    final result = await _signIn(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (session) {
        Modular.get<StartLocationTracking>()();
        _setupPushNotifications();
        emit(Authenticated(session));
      },
    );
  }

  Future<void> signOut() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    Modular.get<StopLocationTracking>()();
    await _signOut();
    emit(Unauthenticated());
  }

  Future<void> _setupPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // T19.14 — request permission on first run after login
      final settings = await messaging.requestPermission(
        alert: true,
        badge: false,
        sound: true,
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'FCM authorizationStatus: ${settings.authorizationStatus}',
        category: 'fcm',
        level: SentryLevel.info,
      ));
      if (!authorized) return;

      // T19.16 — suppress FCM banner in foreground; local notifications from
      // spec 012 already handle the in-app alert.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      // On iOS the APNs token is registered asynchronously after app launch.
      // FCM throws apns-token-not-set if getToken() is called before APNs
      // is ready, so we await getAPNSToken() first to block until it's set.
      if (Platform.isIOS) {
        await messaging.getAPNSToken();
      }

      // T19.13 — upload current token and keep it fresh on rotation
      final token = await messaging.getToken();
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'FCM getToken: ${token != null ? "ok (${token.substring(0, 20)}…)" : "null"}',
        category: 'fcm',
        level: token != null ? SentryLevel.info : SentryLevel.warning,
      ));
      if (token != null) {
        final result = await _updatePushToken(token);
        result.fold(
          (failure) => Sentry.captureMessage(
            'FCM updatePushToken failed: ${failure.message}',
            level: SentryLevel.error,
          ),
          (_) => Sentry.addBreadcrumb(Breadcrumb(
            message: 'FCM token saved to Supabase',
            category: 'fcm',
            level: SentryLevel.info,
          )),
        );
      }

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
        _updatePushToken(newToken);
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st, hint: Hint.withMap({'context': 'FCM setup'}));
    }
  }
}
