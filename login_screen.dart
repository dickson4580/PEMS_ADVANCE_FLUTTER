import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../state/app_controller.dart';
import '../widgets/section_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'demo@pems.local');
  final _password = TextEditingController(text: 'demo1234');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 22),
                  Text('PEMS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Advanced prepaid energy management', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 28),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Connection', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        SegmentedButton<ConnectionMode>(
                          segments: const [
                            ButtonSegment(value: ConnectionMode.localDevice, label: Text('Local ESP32'), icon: Icon(Icons.wifi_tethering)),
                            ButtonSegment(value: ConnectionMode.cloud, label: Text('Cloud'), icon: Icon(Icons.cloud_outlined)),
                          ],
                          selected: {c.connectionMode},
                          onSelectionChanged: (value) => c.setConnectionMode(value.first),
                        ),
                        const SizedBox(height: 18),
                        Text('Role', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(value: UserRole.tenant, label: Text('Tenant'), icon: Icon(Icons.person_outline)),
                            ButtonSegment(value: UserRole.landlord, label: Text('Landlord'), icon: Icon(Icons.apartment_outlined)),
                          ],
                          selected: {c.role},
                          onSelectionChanged: (value) => c.setRole(value.first),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                        ),
                        if (c.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(c.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: c.busy ? null : () => c.login(_email.text.trim(), _password.text),
                          icon: c.busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.login),
                          label: Text(c.busy ? 'Connecting...' : 'Continue'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          c.isLocal
                              ? 'Local mode connects directly to PEMS_DEMO at 192.168.4.1.'
                              : 'Cloud mode is backend-ready and requires your production API URL.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
