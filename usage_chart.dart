import 'package:flutter/material.dart';

class UsageChart extends StatelessWidget {
  const UsageChart({super.key, required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final safeValues = values.isEmpty ? const [0.2, 0.4, 0.3, 0.7, 0.5, 0.8, 0.6] : values;
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _UsagePainter(
          values: safeValues,
          lineColor: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _UsagePainter extends CustomPainter {
  _UsagePainter({required this.values, required this.lineColor, required this.gridColor});
  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = gridColor..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxValue = values.fold<double>(0, (max, value) => value > max ? value : max);
    final divisor = maxValue <= 0 ? 1 : maxValue;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : size.width * i / (values.length - 1);
      final y = size.height - ((values[i] / divisor) * (size.height - 20)) - 10;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = lineColor..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _UsagePainter oldDelegate) => oldDelegate.values != values;
}
