enum ConnectionMode { localDevice, cloud }

enum UserRole { tenant, landlord }

class AppConfig {
  static const localBaseUrl = 'http://192.168.4.1/api/v1';
  static const cloudBaseUrl = 'https://api.example.com/api/v1';
  static const demoMeterId = 'demo-meter-01';

  static String baseUrlFor(ConnectionMode mode) {
    return mode == ConnectionMode.localDevice ? localBaseUrl : cloudBaseUrl;
  }
}
