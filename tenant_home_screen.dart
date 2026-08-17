import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class TenantHomeScreen extends StatelessWidget {
  const TenantHomeScreen({super.key, required this.controller});
  final AppController controller;

  String _metric(double? value, String unit, {int decimals = 1}) {
    return value == null ? '-- $unit' : '${value.toStringAsFixed(decimals)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final status = controller.meterStatus;
    final profile = controller.profile;
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good day,', style: Theme.of(context).textTheme.bodyMedium),
                    Text(profile?.fullName ?? 'PEMS User', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${profile?.propertyName ?? 'Property'} • ${profile?.unitNumber ?? 'Room'}'),
                  ],
                ),
              ),
              StatusPill(label: status?.deviceOnline == true ? 'Device online' : 'Device offline', good: status?.deviceOnline == true),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('GHS ${(status?.balanceGhs ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('≈ ${(status?.balanceKwh ?? 0).toStringAsFixed(2)} kWh remaining', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: StatusPill(label: status?.isRelayOn == true ? 'Supply ON' : 'Supply OFF', good: status?.isRelayOn == true)),
                    const SizedBox(width: 10),
                    Expanded(child: StatusPill(label: status?.lowBalance == true ? 'Low balance' : 'Balance healthy', good: status?.lowBalance != true)),
                  ],
                ),
              ],
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 10),
                  Expanded(child: Text(controller.errorMessage!)),
                  IconButton(onPressed: controller.refreshAll, icon: const Icon(Icons.refresh)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text('Live energy', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              MetricTile(label: 'Voltage', value: _metric(status?.voltage, 'V'), icon: Icons.electric_bolt_outlined, caption: status?.voltage == null ? 'Requires advanced firmware field' : 'Live PZEM reading'),
              MetricTile(label: 'Current', value: _metric(status?.current, 'A', decimals: 2), icon: Icons.show_chart),
              MetricTile(label: 'Power', value: _metric(status?.power, 'W', decimals: 0), icon: Icons.power_outlined),
              MetricTile(label: 'Frequency', value: _metric(status?.frequency, 'Hz'), icon: Icons.waves_outlined),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Protection & supply', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                    const Icon(Icons.shield_outlined),
                  ],
                ),
                const SizedBox(height: 14),
                _StatusRow(label: 'Supply relay', value: status?.isRelayOn == true ? 'Connected' : 'Disconnected'),
                _StatusRow(label: 'Protection state', value: status?.protectionState.toUpperCase() ?? 'UNKNOWN'),
                _StatusRow(label: 'Tamper state', value: status?.tamperActive == true ? 'Alert' : 'Normal'),
                _StatusRow(label: 'Tariff', value: 'GHS ${(status?.ratePerKwh ?? 0).toStringAsFixed(2)} / kWh'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
