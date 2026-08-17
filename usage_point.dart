class UsagePoint {
  const UsagePoint({
    required this.id,
    required this.meterId,
    required this.kwhConsumed,
    required this.recordedAt,
  });

  final String id;
  final String meterId;
  final double kwhConsumed;
  final DateTime recordedAt;

  factory UsagePoint.fromJson(Map<String, dynamic> json) {
    final value = json['kwhConsumed'];
    final kwh = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return UsagePoint(
      id: json['id']?.toString() ?? 'usage',
      meterId: json['meterId']?.toString() ?? '',
      kwhConsumed: kwh,
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
