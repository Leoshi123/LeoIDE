import 'package:flutter/material.dart';
import 'dart:math';

/// Pinta el cursor parpadeante en el canvas del editor.
class CursorPainter {
  final Paint _cursorPaint;
  final double charWidth;
  final double lineHeight;

  // Animación de parpadeo
  bool _visible = true;
  double _lastBlinkTime = 0;
  static const double blinkInterval = 0.5; // segundos

  CursorPainter({
    required this.charWidth,
    required this.lineHeight,
    Color cursorColor = Colors.orangeAccent,
    double cursorWidth = 2.0,
  }) : _cursorPaint = Paint()
      ..color = cursorColor
      ..strokeWidth = cursorWidth
      ..style = PaintingStyle.fill;

  /// Dibuja el cursor en la posición (x, y).
  void paint(Canvas canvas, double x, double y, double elapsedSeconds) {
    // Actualizar parpadeo
    if (elapsedSeconds - _lastBlinkTime > blinkInterval) {
      _visible = !_visible;
      _lastBlinkTime = elapsedSeconds;
    }

    if (!_visible) return;

    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + lineHeight),
      _cursorPaint,
    );
  }

  /// Reinicia el parpadeo (llamar cuando el cursor se mueve).
  void resetBlink() {
    _visible = true;
    _lastBlinkTime = 0;
  }
}
