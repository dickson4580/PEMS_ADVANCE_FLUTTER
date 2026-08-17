class PemsTransaction {
  const PemsTransaction({
    required this.id,
    required this.type,
    required this.amountGhs,
    required this.status,
    required this.createdAt,
    this.reference,
  });

  final String id;
  final String type;
  final double amountGhs;
  final String status;
  final DateTime createdAt;
  final String? reference;

  factory PemsTransaction.fromJson(Map<String, dynamic> json) {
    final value = json['amountGhs'];
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return PemsTransaction(
      id: json['id']?.toString() ?? 'transaction',
      type: json['type']?.toString() ?? 'unknown',
      amountGhs: amount,
      status: json['status']?.toString() ?? 'unknown',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      reference: json['reference']?.toString(),
    );
  }
}
