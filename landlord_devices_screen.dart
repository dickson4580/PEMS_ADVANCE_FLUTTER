import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/section_card.dart';

class LandlordDevicesScreen extends StatelessWidget {
  const LandlordDevicesScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final live = controller.meterStatus;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        Text('Devices', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Register, assign and monitor PEMS units.'),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PEMS-GH-UMA-00001', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _Row('Assigned room', controller.profile?.unitNumber ?? 'Room 1'),
              _Row('Assigned tenant', controller.profile?.fullName ?? 'Demo Tenant'),
              _Row('API meter ID', live?.meterId ?? 'demo-meter-01'),
              _Row('Connectivity', live?.deviceOnline == true ? 'Online' : 'Offline'),
              _Row('Relay', live?.isRelayOn == true ? 'ON' : 'OFF'),
              _Row('Firmware channel', 'Prototype / local'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Register another device')),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }
}
