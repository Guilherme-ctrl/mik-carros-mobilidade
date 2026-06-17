import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'core/design/app_theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Carros Mik Dundee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: Modular.routerConfig,
    );
  }
}
