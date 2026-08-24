import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_module.dart';
import 'app_widget.dart';
import 'core/config/app_config.dart';
import 'core/errors/error_page.dart';
import 'firebase_options.dart';

// Must be a top-level function — runs in a separate isolate when the app is
// terminated or backgrounded. Data will sync via Supabase realtime on next open.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage _) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // Lida do bundle, não de --dart-define.
  //
  // A release vinha de APP_VERSION/BUILD_NUMBER, que NINGUÉM passava — nem o
  // build local, nem o workflow de release. Os dois caíam nos valores padrão
  // ('1.0.0' e '1'), então TODO evento no Sentry chegava como release 1.0.0+1,
  // inclusive os do TestFlight, enquanto o pubspec já ia em 1.0.0+4. Na
  // prática era impossível saber de qual build veio um erro.
  //
  // O bundle não tem como divergir do que foi instalado, e não depende de
  // ninguém lembrar de passar uma flag. A simbolização não é afetada: o
  // debug-files upload do CI é indexado por debug ID, não por release.
  final pacote = await PackageInfo.fromPlatform();

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.tracesSampleRate = 1.0;
      options.release = '${pacote.version}+${pacote.buildNumber}';
      // Estava fixo em 'production', então build de debug se misturava com
      // aparelho de motorista — no sábado seria impossível separar erro real
      // de teste seu.
      options.environment = kDebugMode ? 'development' : 'production';
    },
    appRunner: () {
      FlutterError.onError = (details) {
        Sentry.captureException(
          details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };

      ErrorWidget.builder = (_) => const ErrorPage();

      Modular.setObservers([SentryNavigatorObserver()]);
      runApp(ModularApp(module: AppModule(), child: const AppWidget()));

      // T19.15 — navigate to missions when the user taps a push notification.
      // onMessageOpenedApp fires when the app is in background and the user taps.
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        Modular.to.navigate('/missions/');
      });
      // getInitialMessage handles the app-terminated case (tap opened the app).
      FirebaseMessaging.instance.getInitialMessage().then((msg) {
        if (msg != null) Modular.to.navigate('/missions/');
      });
    },
  );
}
