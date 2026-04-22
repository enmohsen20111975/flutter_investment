import 'dart:math' as math;
import 'package:flutter/material.dart';

class SparklineChart extends StatelessWidget {
  const SparklineChart({
    required this.values,
    this.lineColor,
    this.fillColor,
    this.strokeWidth = 2,
    super.key,
  });

  final List<double> values;
  final Color? lineColor;
  final Color? fillColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات كافية للعرض.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          lineColor: lineColor ?? Theme.of(context).colorScheme.primary,
          fillColor: fillColor ??
              Theme.of(context).colorScheme.primary.withOpacity(0.14),
          strokeWidth: strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs().clamp(1.0, double.infinity);
    final widthStep =
        size.width / (values.length - 1).clamp(1, double.infinity);

    final path = Path();
    final fillPath = Path();

    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      final x = index * widthStep;
      final normalized = (value - minValue) / range;
      final y = size.height - (normalized * size.height);

      if (index == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (index == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
