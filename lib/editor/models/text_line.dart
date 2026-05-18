/// Representa una línea de texto con metadatos para el viewport.
class TextLine {
  final int index;
  final String text;

  const TextLine({required this.index, required this.text});

  /// Longitud de la línea en caracteres.
  int get length => text.length;

  /// Altura en píxeles (se calcula externamente según la fuente).
  double get height => 0.0; // Placeholder, se define en el theme

  /// Si la línea está vacía o solo contiene whitespace.
  bool get isEmpty => text.trim().isEmpty;

  @override
  String toString() => 'Line($index, "${text.length} chars")';
}
