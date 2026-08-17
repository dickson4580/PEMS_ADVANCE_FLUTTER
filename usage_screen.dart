import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/usage_chart.dart';

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final values = controller.usage.map((item) => item.kwhConsumed).toList();
    final total = values.fold<double>(0, (sum, item) => sum + item);
    final rate = controller.meterStatus?.ratePerKwh ?? 0;
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          Text('Usage analytics', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Monitor consumption trends and estimated energy cost.'),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Energy trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                    const Text('Live/local'),
                  ],
                ),
                const SizedBox(height: 16),
                UsageChart(values: values),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              MetricTile(label: 'Recorded energy', value: '${total.toStringAsFixed(3)} kWh', icon: Icons.bolt_outlined),
              MetricTile(label: 'Estimated cost', value: 'GHS ${(total * rate).toStringAsFixed(2)}', icon: Icons.payments_outlined),
            ],
          ),
          const SizedBox(height: 18),
          Text('Recent readings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (controller.usage.isEmpty)
            const SectionCard(child: Text('No usage readings are available yet.'))
          else
            ...controller.usage.reversed.take(10).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SectionCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.electric_meter_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.recordedAt.toLocal().toString().split('.').first)),
                        Text('${item.kwhConsumed.toStringAsFixed(4)} kWh', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
