import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/section_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController(text: '10');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _topUp(double amount) async {
    final reference = await widget.controller.topUp(amount);
    if (!mounted) return;
    if (reference != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Top-up successful. Reference: $reference')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final status = c.meterStatus;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        Text('Wallet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Manage prepaid credit and review transactions.'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wallet balance', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('GHS ${(status?.balanceGhs ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${(status?.balanceKwh ?? 0).toStringAsFixed(2)} kWh available', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Top up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 20, 50].map((value) {
                  return ActionChip(
                    label: Text('GHS $value'),
                    onPressed: c.busy ? null : () => _topUp(value.toDouble()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Custom amount (GHS)', prefixIcon: Icon(Icons.payments_outlined)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: c.busy
                    ? null
                    : () {
                        final value = double.tryParse(_amountController.text.trim());
                        if (value != null && value > 0) _topUp(value);
                      },
                icon: const Icon(Icons.add_card),
                label: Text(c.busy ? 'Processing...' : 'Top up wallet'),
              ),
              const SizedBox(height: 8),
              Text(
                c.isLocal
                    ? 'Local prototype mode: this sends the top-up directly to the ESP32.'
                    : 'Cloud mode should verify payments through a payment provider before crediting the wallet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Transactions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (c.transactions.isEmpty)
          const SectionCard(child: Text('No transactions recorded yet.'))
        else
          ...c.transactions.reversed.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(child: Icon(tx.type == 'topup' ? Icons.add_card : Icons.bolt_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.type == 'topup' ? 'Wallet top-up' : 'Energy consumption', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(tx.createdAt.toLocal().toString().split('.').first, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text('${tx.type == 'topup' ? '+' : '-'} GHS ${tx.amountGhs.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
