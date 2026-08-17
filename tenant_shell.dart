import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import 'account_screen.dart';
import 'alerts_screen.dart';
import 'tenant_home_screen.dart';
import 'usage_screen.dart';
import 'wallet_screen.dart';

class TenantShell extends StatelessWidget {
  const TenantShell({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TenantHomeScreen(controller: controller),
      UsageScreen(controller: controller),
      WalletScreen(controller: controller),
      AlertsScreen(controller: controller),
      AccountScreen(controller: controller),
    ];
    return Scaffold(
      body: IndexedStack(index: controller.tenantTab, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.tenantTab,
        onDestinationSelected: controller.setTenantTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Usage'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
