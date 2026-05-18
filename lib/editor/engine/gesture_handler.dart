import '../models/cursor.dart';

/// Maneja la conversión de eventos táctiles a operaciones del editor.
///
/// En móvil, el toque es la interacción principal. Esta clase traduce
/// gestos (tap, drag, long-press) a acciones del editor.
class GestureHandler {
  /// Última posición de toque conocida (para drag).
  double _lastTouchX = 0;
  double _lastTouchY = 0;

  /// Distancia mínima para considerar un movimiento como drag (píxeles).
  static const double dragThreshold = 10.0;

  /// Distancia máxima entre touch-down y touch-up para considerar un tap.
  static const double tapThreshold = 8.0;

  /// Tiempo máximo para considerar un tap (milisegundos).
  static const int tapTimeoutMs = 300;

  final DateTime _touchStartTime = DateTime.now();
  double _touchStartX = 0;
  double _touchStartY = 0;

  /// Procesa el inicio de un toque.
  void onTouchStart(double x, double y) {
    _lastTouchX = x;
    _lastTouchY = y;
    _touchStartX = x;
    _touchStartY = y;
  }

  /// Procesa el movimiento durante un toque (drag).
  /// Retorna el desplazamiento (dx, dy) si supera el umbral.
  (double dx, double dy)? onTouchMove(double x, double y) {
    final dx = x - _lastTouchX;
    final dy = y - _lastTouchY;

    _lastTouchX = x;
    _lastTouchY = y;

    return (dx, dy);
  }

  /// Procesa el final de un toque.
  /// Retorna [true] si fue un tap (no un drag con intención de scroll).
  bool onTouchEnd(double x, double y) {
    final dx = x - _touchStartX;
    final dy = y - _touchStartY;
    final distance = (dx * dx + dy * dy);
    return distance < tapThreshold * tapThreshold;
  }

  /// Determina si el gesto es un scroll vertical.
  bool isVerticalScroll(double dx, double dy) {
    return dy.abs() > dx.abs() && dy.abs() > dragThreshold;
  }

  /// Determina si el gesto es un scroll horizontal.
  bool isHorizontalScroll(double dx, double dy) {
    return dx.abs() > dy.abs() && dx.abs() > dragThreshold;
  }

  /// Calcula la nueva posición del cursor basada en un toque.
  Cursor cursorForTap({
    required double touchX,
    required double touchY,
    required double scrollX,
    required double scrollY,
    required double charWidth,
    required double lineHeight,
    required int totalLines,
    required List<int> lineLengths,
  }) {
    return Cursor.fromTouch(
      touchX: touchX,
      touchY: touchY,
      scrollX: scrollX,
      scrollY: scrollY,
      charWidth: charWidth,
      lineHeight: lineHeight,
      totalLines: totalLines,
      lineLengths: lineLengths,
    );
  }

  /// Maneja doble tap para seleccionar palabra (placeholder).
  /// En futuras fases se implementará selección de palabras.
  void onDoubleTap(double x, double y) {
    // Placeholder para Fase 2+
  }

  /// Maneja long press (placeholder).
  void onLongPress(double x, double y) {
    // Placeholder para Fase 2+ (menú contextual, paste)
  }
}
