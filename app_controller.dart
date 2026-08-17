import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/alert_event.dart';
import '../models/meter_status.dart';
import '../models/tenant_profile.dart';
import '../models/transaction.dart';
import '../models/usage_point.dart';
import '../services/pems_api_client.dart';

class AppController extends ChangeNotifier {
  ConnectionMode connectionMode = ConnectionMode.localDevice;
  UserRole role = UserRole.tenant;
  bool authenticated = false;
  bool busy = false;
  String? errorMessage;
  int tenantTab = 0;
  int landlordTab = 0;

  TenantProfile? profile;
  MeterStatus? meterStatus;
  List<UsagePoint> usage = const [];
  List<PemsTransaction> transactions = const [];
  DateTime? lastSuccessfulSync;

  PemsApiClient? _api;
  Timer? _poller;

  String get baseUrl => AppConfig.baseUrlFor(connectionMode);
  bool get isLocal => connectionMode == ConnectionMode.localDevice;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('connectionMode');
    final savedRole = prefs.getString('role');
    if (savedMode == 'cloud') connectionMode = ConnectionMode.cloud;
    if (savedRole == 'landlord') role = UserRole.landlord;
  }

  void setConnectionMode(ConnectionMode value) {
    connectionMode = value;
    errorMessage = null;
    notifyListeners();
  }

  void setRole(UserRole value) {
    role = value;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    busy = true;
    errorMessage = null;
    notifyListeners();

    try {
      _api?.close();
      _api = PemsApiClient(baseUrl: baseUrl);
      profile = await _api!.login(email, password);
      authenticated = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'connectionMode',
        connectionMode == ConnectionMode.localDevice ? 'local' : 'cloud',
      );
      await prefs.setString('role', role == UserRole.tenant ? 'tenant' : 'landlord');
      await refreshAll();
      _startPolling();
    } catch (error) {
      authenticated = false;
      errorMessage = _friendlyError(error);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    if (_api == null) return;
    try {
      final results = await Future.wait([
        _api!.getMeterStatus(AppConfig.demoMeterId),
        _api!.getUsage(AppConfig.demoMeterId),
        _api!.getTransactions(AppConfig.demoMeterId),
      ]);
      meterStatus = results[0] as MeterStatus;
      usage = results[1] as List<UsagePoint>;
      transactions = results[2] as List<PemsTransaction>;
      lastSuccessfulSync = DateTime.now();
      errorMessage = null;
    } catch (error) {
      errorMessage = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<void> refreshStatus() async {
    if (_api == null || !authenticated) return;
    try {
      meterStatus = await _api!.getMeterStatus(AppConfig.demoMeterId);
      lastSuccessfulSync = DateTime.now();
      errorMessage = null;
    } catch (error) {
      errorMessage = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<String?> topUp(double amount) async {
    if (_api == null) return null;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final reference = await _api!.topUp(amount);
      await refreshAll();
      return reference;
    } catch (error) {
      errorMessage = _friendlyError(error);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setTenantTab(int index) {
    tenantTab = index;
    notifyListeners();
  }

  void setLandlordTab(int index) {
    landlordTab = index;
    notifyListeners();
  }

  List<AlertEvent> get alerts {
    final now = DateTime.now();
    final status = meterStatus;
    final items = <AlertEvent>[];
    if (status == null) {
      return [
        AlertEvent(
          title: 'Waiting for meter data',
          message: 'PEMS has not received a meter reading yet.',
          severity: AlertSeverity.info,
          time: now,
        ),
      ];
    }
    if (!status.deviceOnline) {
      items.add(AlertEvent(
        title: 'Device offline',
        message: 'The assigned PEMS unit is not responding.',
        severity: AlertSeverity.critical,
        time: now,
      ));
    }
    if (status.lowBalance) {
      items.add(AlertEvent(
        title: 'Low energy balance',
        message: 'Top up soon to avoid an automatic supply disconnection.',
        severity: AlertSeverity.warning,
        time: now,
      ));
    }
    if (!status.isRelayOn) {
      items.add(AlertEvent(
        title: 'Room supply disconnected',
        message: 'The PEMS relay is currently OFF.',
        severity: AlertSeverity.critical,
        time: now,
      ));
    }
    if (status.tamperActive) {
      items.add(AlertEvent(
        title: 'Tamper alert',
        message: 'The device reported a possible tamper condition.',
        severity: AlertSeverity.critical,
        time: now,
      ));
    }
    if (status.voltage != null && status.voltage! > 250) {
      items.add(AlertEvent(
        title: 'High voltage detected',
        message: 'Measured ${status.voltage!.toStringAsFixed(1)} V. Protection may disconnect the load.',
        severity: AlertSeverity.critical,
        time: now,
      ));
    }
    if (status.voltage != null && status.voltage! < 190) {
      items.add(AlertEvent(
        title: 'Low voltage detected',
        message: 'Measured ${status.voltage!.toStringAsFixed(1)} V.',
        severity: AlertSeverity.warning,
        time: now,
      ));
    }
    if (items.isEmpty) {
      items.add(AlertEvent(
        title: 'System healthy',
        message: 'No active PEMS alerts were detected.',
        severity: AlertSeverity.info,
        time: now,
      ));
    }
    return items;
  }

  void logout() {
    _poller?.cancel();
    authenticated = false;
    profile = null;
    meterStatus = null;
    usage = const [];
    transactions = const [];
    errorMessage = null;
    notifyListeners();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => refreshStatus());
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Connection refused')) {
      return isLocal
          ? 'Cannot reach the ESP32. Connect this phone to PEMS_DEMO and confirm 192.168.4.1 is reachable.'
          : 'Cannot reach the PEMS cloud service.';
    }
    if (text.contains('TimeoutException')) {
      return 'The PEMS connection timed out. Check the Wi-Fi connection and try again.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _poller?.cancel();
    _api?.close();
    super.dispose();
  }
}
