import 'dart:math';

/// Representa la posición del cursor en el editor.
///
/// Siempre se mantiene en un estado válido: línea y columna no negativos.
class Cursor {
  final int line;
  final int column;

  const Cursor(this.line, this.column);

  static const Cursor initial = Cursor(0, 0);

  /// Desplaza el cursor una posición hacia arriba.
  Cursor moveUp({required int totalLines}) {
    if (line <= 0) return this;
    return Cursor(line - 1, column);
  }

  /// Desplaza el cursor una posición hacia abajo.
  Cursor moveDown({required int totalLines}) {
    if (line >= totalLines - 1) return this;
    return Cursor(line + 1, column);
  }

  /// Desplaza el cursor a la izquierda.
  Cursor moveLeft() {
    if (column > 0) return Cursor(line, column - 1);
    if (line > 0) return Cursor(line - 1, column); // wrap a línea anterior
    return this;
  }

  /// Desplaza el cursor a la derecha.
  Cursor moveRight({required int lineLength}) {
    if (column < lineLength) return Cursor(line, column + 1);
    // wrap a siguiente línea
    return Cursor(line + 1, 0);
  }

  /// Convierte un punto táctil (x, y) a posición cursor.
  ///
  /// [touchX], [touchY]: coordenadas del toque en píxeles.
  /// [scrollX], [scrollY]: desplazamiento actual del viewport.
  /// [charWidth], [lineHeight]: dimensiones de la fuente.
  /// [totalLines]: número total de líneas en el documento.
  static Cursor fromTouch({
    required double touchX,
    required double touchY,
    required double scrollX,
    required double scrollY,
    required double charWidth,
    required double lineHeight,
    required int totalLines,
    required List<int> lineLengths,
  }) {
    final rawLine = ((touchY + scrollY) / lineHeight).floor();
    final line = rawLine.clamp(0, totalLines - 1);

    final rawCol = ((touchX + scrollX) / charWidth).round();
    final maxCol = line < lineLengths.length ? lineLengths[line] : 0;
    final col = rawCol.clamp(0, maxCol);

    return Cursor(line, col);
  }

  /// Calcula la posición en píxeles del cursor en la pantalla.
  (double x, double y) toPixel({
    required double scrollX,
    required double scrollY,
    required double charWidth,
    required double lineHeight,
  }) {
    final x = (column * charWidth) - scrollX;
    final y = (line * lineHeight) - scrollY;
    return (x, y);
  }

  Cursor copyWith({int? line, int? column}) {
    return Cursor(
      line ?? this.line,
      column ?? this.column,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cursor && line == other.line && column == other.column;

  @override
  int get hashCode => Object.hash(line, column);

  @override
  String toString() => 'Cursor($line, $column)';
}
