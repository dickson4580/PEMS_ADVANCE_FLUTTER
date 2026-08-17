import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import 'account_screen.dart';
import 'alerts_screen.dart';
import 'landlord_dashboard_screen.dart';
import 'landlord_devices_screen.dart';

class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = [
      LandlordDashboardScreen(controller: controller),
      LandlordDevicesScreen(controller: controller),
      AlertsScreen(controller: controller),
      AccountScreen(controller: controller),
    ];
    return Scaffold(
      body: IndexedStack(index: controller.landlordTab, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.landlordTab,
        onDestinationSelected: controller.setLandlordTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.router_outlined), selectedIcon: Icon(Icons.router), label: 'Devices'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
