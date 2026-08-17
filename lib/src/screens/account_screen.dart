import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/section_card.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        Text('Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            children: [
              const CircleAvatar(radius: 34, child: Icon(Icons.person_outline, size: 34)),
              const SizedBox(height: 12),
              Text(profile?.fullName ?? 'PEMS User', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(profile?.email ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
              _InfoRow(label: 'Property', value: profile?.propertyName ?? '--'),
              _InfoRow(label: 'Room / unit', value: profile?.unitNumber ?? '--'),
              _InfoRow(label: 'Phone', value: profile?.phone ?? '--'),
              _InfoRow(label: 'Meter ID', value: controller.meterStatus?.meterId ?? 'demo-meter-01'),
              _InfoRow(label: 'Connection', value: controller.isLocal ? 'Local ESP32' : 'Cloud'),
              _InfoRow(label: 'API', value: controller.baseUrl),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: controller.logout, icon: const Icon(Icons.logout), label: const Text('Sign out')),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
