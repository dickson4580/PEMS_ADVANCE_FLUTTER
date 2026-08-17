import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_status.dart';
import '../models/tenant_profile.dart';
import '../models/transaction.dart';
import '../models/usage_point.dart';

class PemsApiClient {
  PemsApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<T> _decode<T>(
    http.Response response,
    T Function(dynamic json) parser,
  ) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('PEMS API ${response.statusCode}: ${response.body}');
    }
    final body = response.body.trim();
    if (body.isEmpty) throw Exception('PEMS API returned an empty response.');
    return parser(jsonDecode(body));
  }

  Future<TenantProfile> login(String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));

    return _decode(response, (json) {
      final map = json as Map<String, dynamic>;
      accessToken = map['accessToken']?.toString();
      return TenantProfile.fromJson(map['tenant'] as Map<String, dynamic>);
    });
  }

  Future<TenantProfile> getProfile() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/tenants/me'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decode(
      response,
      (json) => TenantProfile.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MeterStatus> getMeterStatus(String meterId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/meters/$meterId/status'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decode(
      response,
      (json) => MeterStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<UsagePoint>> getUsage(String meterId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/meters/$meterId/usage'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decode(response, (json) {
      return (json as List<dynamic>)
          .map((item) => UsagePoint.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<PemsTransaction>> getTransactions(String meterId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/meters/$meterId/transactions'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decode(response, (json) {
      return (json as List<dynamic>)
          .map((item) => PemsTransaction.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<String> topUp(double amountGhs) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/payments/topup'),
          headers: _headers,
          body: jsonEncode({'amountGhs': amountGhs}),
        )
        .timeout(const Duration(seconds: 8));
    return _decode(response, (json) {
      final map = json as Map<String, dynamic>;
      return map['reference']?.toString() ?? 'success';
    });
  }

  void close() => _client.close();
}
