import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class LandlordDashboardScreen extends StatelessWidget {
  const LandlordDashboardScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final live = controller.meterStatus;
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          Row(
            children: [
              Expanded(child: Text('Property operations', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
              StatusPill(label: live?.deviceOnline == true ? 'Gateway online' : 'Gateway offline', good: live?.deviceOnline == true),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Monitor rooms, devices, tenant balances and operational alerts.'),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: const [
              MetricTile(label: 'Total rooms', value: '12', icon: Icons.meeting_room_outlined, caption: '10 occupied'),
              MetricTile(label: 'Devices online', value: '11 / 12', icon: Icons.router_outlined, caption: '1 requires attention'),
              MetricTile(label: 'Today usage', value: '56.2 kWh', icon: Icons.bolt_outlined),
              MetricTile(label: 'Contributions', value: 'GHS 2,840', icon: Icons.account_balance_wallet_outlined),
            ],
          ),
          const SizedBox(height: 18),
          Text('Rooms', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _RoomCard(room: 'Room 01', tenant: 'Kwame Mensah', balance: 'GHS 43.20', online: true, note: 'Supply ON'),
          const SizedBox(height: 8),
          _RoomCard(room: 'Room 02', tenant: 'Ama Owusu', balance: 'GHS 3.10', online: true, note: 'Low balance'),
          const SizedBox(height: 8),
          _RoomCard(room: 'Room 03', tenant: 'Unassigned', balance: '--', online: false, note: 'Device offline'),
          const SizedBox(height: 8),
          _RoomCard(
            room: controller.profile?.unitNumber ?? 'Room 04',
            tenant: controller.profile?.fullName ?? 'Demo Tenant',
            balance: 'GHS ${(live?.balanceGhs ?? 0).toStringAsFixed(2)}',
            online: live?.deviceOnline == true,
            note: live?.isRelayOn == true ? 'Supply ON' : 'Supply OFF',
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Advanced workflow', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('Create property → add rooms → register PEMS device → assign tenant → monitor balance and protection events.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.tenant, required this.balance, required this.online, required this.note});
  final String room;
  final String tenant;
  final String balance;
  final bool online;
  final String note;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(child: Icon(online ? Icons.meeting_room_outlined : Icons.portable_wifi_off_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(tenant, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(note, style: TextStyle(color: online ? const Color(0xFF0B6B4F) : Theme.of(context).colorScheme.error)),
              ],
            ),
          ),
          Text(balance, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
