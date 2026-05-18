import 'package:flutter/material.dart';

/// Widget que muestra los números de línea en el gutter del editor.
///
/// Separado del canvas principal para mejor rendimiento al hacer scroll.
class LineNumberGutter extends StatelessWidget {
  final int totalLines;
  final int firstVisibleLine;
  final int lastVisibleLine;
  final double lineHeight;
  final double scrollY;
  final Color backgroundColor;
  final Color textColor;
  final double width;

  const LineNumberGutter({
    super.key,
    required this.totalLines,
    required this.firstVisibleLine,
    required this.lastVisibleLine,
    required this.lineHeight,
    required this.scrollY,
    this.backgroundColor = const Color(0xFF252526),
    this.textColor = const Color(0xFF858585),
    this.width = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: backgroundColor,
      child: ClipRect(
        child: CustomPaint(
          painter: _LineNumberPainter(
            totalLines: totalLines,
            firstVisibleLine: firstVisibleLine,
            lastVisibleLine: lastVisibleLine,
            lineHeight: lineHeight,
            scrollY: scrollY,
            textColor: textColor,
          ),
          size: Size(width, double.infinity),
        ),
      ),
    );
  }
}

class _LineNumberPainter extends CustomPainter {
  final int totalLines;
  final int firstVisibleLine;
  final int lastVisibleLine;
  final double lineHeight;
  final double scrollY;
  final Color textColor;

  _LineNumberPainter({
    required this.totalLines,
    required this.firstVisibleLine,
    required this.lastVisibleLine,
    required this.lineHeight,
    required this.scrollY,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = firstVisibleLine; i <= lastVisibleLine && i < totalLines; i++) {
      final y = (i * lineHeight) - scrollY;
      if (y < -lineHeight || y > size.height) continue;

      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          color: textColor,
          fontSize: lineHeight * 0.7,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout(maxWidth: size.width - 10);

      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width - 6, y + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineNumberPainter oldDelegate) {
    return oldDelegate.firstVisibleLine != firstVisibleLine ||
        oldDelegate.scrollY != scrollY ||
        oldDelegate.totalLines != totalLines;
  }
}
