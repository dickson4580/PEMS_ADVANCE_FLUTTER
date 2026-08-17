class AlertEvent {
  const AlertEvent({
    required this.title,
    required this.message,
    required this.severity,
    required this.time,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime time;
}

enum AlertSeverity { info, warning, critical }
