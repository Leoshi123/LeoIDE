import 'dart:math';

/// Gestiona qué líneas son visibles en pantalla y deben renderizarse.
///
/// En un teléfono con pantalla limitada, renderizar 10,000 líneas de código
/// es inviable. VirtualViewport calcula exactamente qué líneas entran en
/// el área visible y añade un buffer de seguridad para scroll suave.
class VirtualViewport {
  /// Alto total de la pantalla dedicado al editor (píxeles).
  double viewportHeight;

  /// Ancho total de la pantalla dedicado al editor (píxeles).
  double viewportWidth;

  /// Alto de cada línea (píxeles) — determinado por la fuente.
  double lineHeight;

  /// Ancho de cada caracter (píxeles) — determinado por la fuente.
  double charWidth;

  /// Número de líneas extra para renderizar arriba/abajo del viewport.
  /// Esto evita flickering al hacer scroll rápido.
  int safetyBuffer;

  /// Desplazamiento horizontal (píxeles).
  double scrollX;

  /// Desplazamiento vertical (píxeles).
  double scrollY;

  /// Ancho máximo de línea en el documento (píxeles).
  double maxLineWidth;

  /// Total de líneas en el documento.
  int totalLines;

  VirtualViewport({
    required this.viewportHeight,
    required this.viewportWidth,
    this.lineHeight = 24.0,
    this.charWidth = 10.0,
    this.safetyBuffer = 5,
    this.scrollX = 0.0,
    this.scrollY = 0.0,
    this.maxLineWidth = 0.0,
    this.totalLines = 1,
  });

  // ── Líneas visibles ──

  /// Número de líneas que caben en el viewport.
  int get visibleLineCount =>
      (viewportHeight / lineHeight).ceil() + 1;

  /// Índice de la primera línea visible (con buffer de seguridad).
  int get firstVisibleLine =>
      max(0, (scrollY / lineHeight).floor() - safetyBuffer);

  /// Índice de la última línea visible (con buffer de seguridad).
  int get lastVisibleLine =>
      min(totalLines - 1, ((scrollY + viewportHeight) / lineHeight).ceil() + safetyBuffer);

  /// Rango de líneas a renderizar [inicio, fin).
  (int start, int end) get visibleRange =>
      (firstVisibleLine, lastVisibleLine + 1);

  /// Número de líneas a renderizar realmente.
  int get linesToRender => lastVisibleLine - firstVisibleLine + 1;

  // ── Scroll ──

  /// Scroll vertical. [dy] positivo = hacia abajo, negativo = hacia arriba.
  void scrollBy(double dx, double dy) {
    scrollX = (scrollX + dx).clamp(0.0, maxScrollX);
    scrollY = (scrollY + dy).clamp(0.0, maxScrollY);
  }

  /// Scroll a una línea específica.
  void scrollToLine(int line) {
    scrollY = (line * lineHeight).clamp(0.0, maxScrollY);
  }

  /// Scroll para asegurar que el cursor sea visible.
  void ensureCursorVisible(int cursorLine, int cursorColumn) {
    final cursorY = cursorLine * lineHeight;
    final cursorX = cursorColumn * charWidth;

    // Scroll vertical
    if (cursorY < scrollY) {
      scrollY = cursorY - safetyBuffer * lineHeight;
    } else if (cursorY + lineHeight > scrollY + viewportHeight) {
      scrollY = cursorY + lineHeight - viewportHeight + safetyBuffer * lineHeight;
    }

    // Scroll horizontal
    if (cursorX < scrollX) {
      scrollX = cursorX - 50; // margen izquierdo
    } else if (cursorX + charWidth > scrollX + viewportWidth) {
      scrollX = cursorX + charWidth - viewportWidth + 50;
    }

    scrollX = scrollX.clamp(0.0, maxScrollX);
    scrollY = scrollY.clamp(0.0, maxScrollY);
  }

  // ── Límites ──

  /// Máximo scroll horizontal.
  double get maxScrollX => max(0.0, maxLineWidth - viewportWidth);

  /// Máximo scroll vertical.
  double get maxScrollY => max(0.0, (totalLines * lineHeight) - viewportHeight);

  /// Si se necesita scroll horizontal.
  bool get hasHorizontalScroll => maxLineWidth > viewportWidth;

  /// Si se necesita scroll vertical.
  bool get hasVerticalScroll => (totalLines * lineHeight) > viewportHeight;

  // ── Conversión de coordenadas ──

  /// Convierte una posición Y de pantalla a índice de línea.
  int yToLine(double y) =>
      ((y + scrollY) / lineHeight).floor().clamp(0, totalLines - 1);

  /// Convierte una posición X de pantalla a columna.
  double xToColumn(double x) =>
      ((x + scrollX) / charWidth).roundToDouble();

  /// Convierte línea a posición Y en pantalla.
  double lineToY(int line) => (line * lineHeight) - scrollY;

  /// Convierte columna a posición X en pantalla.
  double columnToX(int col) => (col * charWidth) - scrollX;

  /// Progreso del scroll vertical (0.0 a 1.0).
  double get scrollProgress =>
      maxScrollY > 0 ? (scrollY / maxScrollY) : 0.0;

  /// Progreso del scroll horizontal (0.0 a 1.0).
  double get scrollHorizontalProgress =>
      maxScrollX > 0 ? (scrollX / maxScrollX) : 0.0;

  @override
  String toString() =>
      'Viewport(lines ${firstVisibleLine}-${lastVisibleLine}, '
      'scroll(${scrollX.toStringAsFixed(0)}, ${scrollY.toStringAsFixed(0)}), '
      '${linesToRender} rendered)';
}
