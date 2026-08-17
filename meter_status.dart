class MeterStatus {
  const MeterStatus({
    required this.meterId,
    required this.deviceOnline,
    required this.balanceKwh,
    required this.balanceGhs,
    required this.ratePerKwh,
    required this.isRelayOn,
    required this.lastReadingAt,
    required this.lowBalanceThresholdKwh,
    this.voltage,
    this.current,
    this.power,
    this.frequency,
    this.powerFactor,
    this.energyKwh,
    this.tamperActive = false,
    this.protectionState = 'normal',
  });

  final String meterId;
  final bool deviceOnline;
  final double balanceKwh;
  final double balanceGhs;
  final double ratePerKwh;
  final bool isRelayOn;
  final DateTime? lastReadingAt;
  final double lowBalanceThresholdKwh;
  final double? voltage;
  final double? current;
  final double? power;
  final double? frequency;
  final double? powerFactor;
  final double? energyKwh;
  final bool tamperActive;
  final String protectionState;

  bool get lowBalance => balanceKwh <= lowBalanceThresholdKwh;

  factory MeterStatus.fromJson(Map<String, dynamic> json) {
    double? nullableNumber(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    double number(dynamic value, [double fallback = 0]) {
      return nullableNumber(value) ?? fallback;
    }

    return MeterStatus(
      meterId: json['meterId']?.toString() ?? 'unknown-meter',
      deviceOnline: json['deviceOnline'] == true,
      balanceKwh: number(json['balanceKwh']),
      balanceGhs: number(json['balanceGhs']),
      ratePerKwh: number(json['ratePerKwh']),
      isRelayOn: json['isRelayOn'] == true,
      lastReadingAt: DateTime.tryParse(json['lastReadingAt']?.toString() ?? ''),
      lowBalanceThresholdKwh: number(json['lowBalanceThresholdKwh']),
      voltage: nullableNumber(json['voltage']),
      current: nullableNumber(json['current']),
      power: nullableNumber(json['power']),
      frequency: nullableNumber(json['frequency']),
      powerFactor: nullableNumber(json['powerFactor']),
      energyKwh: nullableNumber(json['energyKwh']),
      tamperActive: json['tamperActive'] == true,
      protectionState: json['protectionState']?.toString() ?? 'normal',
    );
  }
}
