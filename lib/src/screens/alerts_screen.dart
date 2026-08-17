import 'package:flutter/material.dart';
import '../models/alert_event.dart';
import '../state/app_controller.dart';
import '../widgets/section_card.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        Text('Alerts & protection', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Active device, balance, voltage and supply notifications.'),
        const SizedBox(height: 18),
        ...controller.alerts.map((alert) {
          final data = switch (alert.severity) {
            AlertSeverity.info => (Icons.check_circle_outline, const Color(0xFF0B6B4F)),
            AlertSeverity.warning => (Icons.warning_amber_rounded, const Color(0xFF9B6B00)),
            AlertSeverity.critical => (Icons.error_outline, Theme.of(context).colorScheme.error),
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: data.$2.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                    child: Icon(data.$1, color: data.$2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(alert.message),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended protection policy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('The production system can disconnect the room load during sustained over-voltage, under-voltage, tamper or zero-balance conditions and reconnect after a configurable recovery delay.'),
            ],
          ),
        ),
      ],
    );
  }
}
