import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.restore();
  runApp(PemsApp(controller: controller));
}
