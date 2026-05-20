import '../models/piece_table.dart';
import '../models/cursor.dart';

/// Representa un cambio en el documento para que la UI pueda reaccionar eficientemente.
class TextDelta {
  final int offset;
  final String text;
  final bool isInsert;

  TextDelta({required this.offset, required this.text, required this.isInsert});
}

/// Orquestador del editor. Coordina PieceTable + Cursor + operaciones.
///
/// Es la capa que la UI consume directamente. Toda modificación del texto
/// pasa por aquí.
class TextEngine {
  PieceTable _pieceTable;
  Cursor _cursor = Cursor.initial;
  
  /// Callback llamado cada vez que el texto cambia.
  void Function(TextDelta)? onDelta;

  TextEngine(String initialText) : _pieceTable = PieceTable(initialText);

  /// Constructor para editor vacío.
  TextEngine.empty() : _pieceTable = PieceTable.empty();

  // ── Getters ──

  PieceTable get pieceTable => _pieceTable;
  Cursor get cursor => _cursor;
  String get text => _pieceTable.text;
  int get length => _pieceTable.length;
  int get lineCount => _pieceTable.lineCount;
  List<int> get lineLengths => _pieceTable.lineLengths;
  bool get canUndo => _pieceTable.canUndo;
  bool get canRedo => _pieceTable.canRedo;

  // ── Operaciones de edición ──

  /// Inserta [value] en la posición actual del cursor.
  void insertAtCursor(String value) {
    final pos = _cursorGlobalPos();
    _pieceTable.insert(pos, value);
    _cursor = _cursor.moveRight(lineLength: _currentLineLength());
    onDelta?.call(TextDelta(offset: pos, text: value, isInsert: true));
  }

  /// Elimina [count] caracteres antes del cursor (backspace).
  void backspace([int count = 1]) {
    if (_cursor.column == 0 && _cursor.line == 0) return;

    final pos = _cursorGlobalPos();
    final actualCount = count.clamp(0, pos);

    if (actualCount == 0) return;

    final deletedText = _pieceTable.text.substring(pos - actualCount, pos);
    _pieceTable.delete(pos - actualCount, actualCount);
    _cursor = _cursor.moveLeft();
    onDelta?.call(TextDelta(offset: pos - actualCount, text: deletedText, isInsert: false));
  }

  /// Elimina [count] caracteres después del cursor (delete forward).
  void deleteForward([int count = 1]) {
    final pos = _cursorGlobalPos();
    final actualCount = count.clamp(0, _pieceTable.length - pos);

    if (actualCount == 0) return;

    final deletedText = _pieceTable.text.substring(pos, pos + actualCount);
    _pieceTable.delete(pos, actualCount);
    onDelta?.call(TextDelta(offset: pos, text: deletedText, isInsert: false));
  }

  /// Inserta un salto de línea (Enter).
  void insertNewline() {
    insertAtCursor('\n');
  }

  /// Inserta una tabulación.
  void insertTab() {
    insertAtCursor('  '); // 2 espacios por tab
  }

  // ── Movimiento del cursor ──

  void moveCursorUp() {
    _cursor = _cursor.moveUp(totalLines: lineCount);
  }

  void moveCursorDown() {
    _cursor = _cursor.moveDown(totalLines: lineCount);
  }

  void moveCursorLeft() {
    _cursor = _cursor.moveLeft();
  }

  void moveCursorRight() {
    _cursor = _cursor.moveRight(lineLength: _currentLineLength());
  }

  /// Mueve el cursor a una posición calculada desde un toque.
  void moveCursorToTouch({
    required double touchX,
    required double touchY,
    required double scrollX,
    required double scrollY,
    required double charWidth,
    required double lineHeight,
  }) {
    _cursor = Cursor.fromTouch(
      touchX: touchX,
      touchY: touchY,
      scrollX: scrollX,
      scrollY: scrollY,
      charWidth: charWidth,
      lineHeight: lineHeight,
      totalLines: lineCount,
      lineLengths: _pieceTable.lineLengths,
    );
  }

  /// Mueve el cursor al inicio de la línea actual.
  void moveToLineStart() {
    _cursor = Cursor(_cursor.line, 0);
  }

  /// Mueve el cursor al final de la línea actual.
  void moveToLineEnd() {
    final len = _currentLineLength();
    _cursor = Cursor(_cursor.line, len);
  }

  // ── Undo / Redo ──

  void undo() {
    _pieceTable.undo();
    _clampCursor();
  }

  void redo() {
    _pieceTable.redo();
    _clampCursor();
  }

  /// Convierte una posición de carácter en número de línea (0‑based).
  int offsetToLine(int offset) {
    final lengths = _pieceTable.lineLengths;
    int cum = 0;
    for (int i = 0; i < lengths.length; i++) {
      // Cada línea termina con '\n' que no está incluida en length, así que contamos un carácter extra.
      if (offset <= cum + lengths[i]) return i;
      cum += lengths[i] + 1; // +1 por el salto de línea
    }
    return lengths.isEmpty ? 0 : lengths.length - 1;
  }

  int _cursorGlobalPos() {
    return _pieceTable.lineColToPosition(_cursor.line, _cursor.column);
  }

  /// Convierte una posición global a línea/columna.
  (int line, int col) positionToLineCol(int pos) => _pieceTable.positionToLineCol(pos);

  int _currentLineLength() {
    final lengths = _pieceTable.lineLengths;
    if (_cursor.line < lengths.length) {
      return lengths[_cursor.line];
    }
    return 0;
  }

  void _clampCursor() {
    final lengths = _pieceTable.lineLengths;
    final clampedLine = _cursor.line.clamp(0, lineCount - 1);
    final maxCol = clampedLine < lengths.length ? lengths[clampedLine] : 0;
    _cursor = Cursor(clampedLine, _cursor.column.clamp(0, maxCol));
  }

  /// Carga un nuevo texto en el editor.
  void loadText(String newText) {
    _pieceTable = PieceTable(newText);
    _cursor = Cursor.initial;
  }

  /// Obtiene el texto de una línea específica.
  String lineAt(int index) => _pieceTable.lineAt(index);
}
