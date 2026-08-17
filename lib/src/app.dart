import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/landlord_shell.dart';
import 'screens/login_screen.dart';
import 'screens/tenant_shell.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

class PemsApp extends StatelessWidget {
  const PemsApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PEMS Advanced',
          theme: AppTheme.light(),
          home: !controller.authenticated
              ? LoginScreen(controller: controller)
              : controller.role == UserRole.tenant
                  ? TenantShell(controller: controller)
                  : LandlordShell(controller: controller),
        );
      },
    );
  }
}
