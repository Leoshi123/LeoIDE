/// Representa una pieza dentro de la Piece Table.
///
/// Cada pieza apunta a un buffer (original = 0, add = 1) con offset y longitud.
class Piece {
  final int bufferId;
  final int start;
  final int length;

  const Piece(this.bufferId, this.start, this.length);

  bool get isEmpty => length == 0;

  Piece copyWith({int? bufferId, int? start, int? length}) {
    return Piece(
      bufferId ?? this.bufferId,
      start ?? this.start,
      length ?? this.length,
    );
  }

  @override
  String toString() => 'P(b$bufferId, $start, $length)';
}

/// Piece Table — estructura de datos para edición de texto eficiente en móvil.
///
/// Mantiene dos buffers (original read-only y add para cambios) y una lista
/// de piezas que describen el estado actual del documento.
///
/// Complejidad:
/// - Inserción: O(P) donde P = número de piezas (no caracteres)
/// - Borrado:   O(P)
/// - Undo:      O(1) — solo restaurar piezas previas
/// - Acceso a caracter: O(P) para encontrar la pieza
///
/// Ventaja clave sobre un String plano: las inserciones no mueven caracteres
/// en memoria, solo dividen piezas. Ideal para RAM limitada en móvil.
class PieceTable {
  final String _originalBuffer;
  final StringBuffer _addBuffer = StringBuffer();
  final List<Piece> _pieces = [];

  int _version = 0;

  // Historial de undo
  final List<List<Piece>> _undoStack = [];
  final List<List<Piece>> _redoStack = [];
  static const int _maxUndo = 100;

  PieceTable(String text) : _originalBuffer = text {
    if (text.isNotEmpty) {
      _pieces.add(Piece(0, 0, text.length));
    }
  }

  /// Crea una PieceTable vacía.
  PieceTable.empty() : _originalBuffer = '';

  /// Texto completo reconstruido desde las piezas.
  String get text {
    final buf = StringBuffer();
    for (final piece in _pieces) {
      buf.write(_read(piece));
    }
    return buf.toString();
  }

  /// Longitud total del documento.
  int get length => _pieces.fold(0, (s, p) => s + p.length);

  /// Número de piezas activas.
  int get pieceCount => _pieces.length;

  /// Versión actual.
  int get version => _version;

  /// Lee el contenido de una pieza.
  String _read(Piece p) {
    final src = p.bufferId == 0 ? _originalBuffer : _addBuffer.toString();
    return src.substring(p.start, p.start + p.length);
  }

  /// Lee un caracter en la posición global [pos].
  String charAt(int pos) {
    int acc = 0;
    for (final p in _pieces) {
      if (pos < acc + p.length) {
        final src = p.bufferId == 0 ? _originalBuffer : _addBuffer.toString();
        return src[p.start + (pos - acc)];
      }
      acc += p.length;
    }
    throw RangeError('Position $pos out of range (length: $length)');
  }

  /// Encuentra el índice de pieza y offset local para una posición global.
  (int idx, int offset) _locate(int pos) {
    int acc = 0;
    for (int i = 0; i < _pieces.length; i++) {
      final p = _pieces[i];
      if (pos < acc + p.length) return (i, pos - acc);
      acc += p.length;
    }
    return (_pieces.length - 1, _pieces.last.length);
  }

  // ──────────────────────────────────────────────
  //  OPERACIONES PRINCIPALES
  // ──────────────────────────────────────────────

  /// Inserta [value] en la posición global [pos].
  void insert(int pos, String value) {
    if (value.isEmpty) return;
    _pushUndo();

    final addStart = _addBuffer.length;
    _addBuffer.write(value);
    final newPiece = Piece(1, addStart, value.length);

    if (_pieces.isEmpty) {
      _pieces.add(newPiece);
    } else if (pos >= length) {
      _pieces.add(newPiece);
    } else {
      _splitAndInsert(pos, newPiece);
    }

    _version++;
  }

  /// Elimina [count] caracteres desde [pos].
  void delete(int pos, int count) {
    if (count <= 0 || pos >= length || _pieces.isEmpty) return;
    count = count.clamp(0, length - pos);
    if (count == 0) return;

    _pushUndo();
    _deleteRange(pos, count);
    _version++;
  }

  // ──────────────────────────────────────────────
  //  UNDO / REDO
  // ──────────────────────────────────────────────

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;
    _redoStack.add(List.from(_pieces));
    final saved = _undoStack.removeLast();
    _pieces
      ..clear()
      ..addAll(saved);
    _version++;
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(List.from(_pieces));
    final saved = _redoStack.removeLast();
    _pieces
      ..clear()
      ..addAll(saved);
    _version++;
  }

  void _pushUndo() {
    _undoStack.add(List.from(_pieces));
    if (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear(); // nueva acción invalida el redo
  }

  // ──────────────────────────────────────────────
  //  HELPERS INTERNOS
  // ──────────────────────────────────────────────

  /// Divide la pieza en [pos] e inserta [newPiece] en medio.
  void _splitAndInsert(int pos, Piece newPiece) {
    final result = <Piece>[];
    int acc = 0;
    bool inserted = false;

    for (final p in _pieces) {
      if (inserted) {
        result.add(p);
        continue;
      }

      if (pos <= acc) {
        // La posición está antes de esta pieza: insertar antes
        result.add(newPiece);
        result.add(p);
        inserted = true;
      } else if (pos < acc + p.length) {
        // La posición está dentro de esta pieza: dividir
        final offset = pos - acc;
        if (offset > 0) {
          result.add(Piece(p.bufferId, p.start, offset));
        }
        result.add(newPiece);
        final rightStart = p.start + offset;
        final rightLen = p.length - offset;
        if (rightLen > 0) {
          result.add(Piece(p.bufferId, rightStart, rightLen));
        }
        inserted = true;
      } else {
        result.add(p);
      }
      acc += p.length;
    }

    if (!inserted) {
      result.add(newPiece);
    }

    _pieces
      ..clear()
      ..addAll(result);
  }

  /// Elimina el rango [pos, pos+count) del documento.
  void _deleteRange(int pos, int count) {
    final endPos = pos + count;
    final result = <Piece>[];
    int acc = 0;

    for (final p in _pieces) {
      final pieceStart = acc;
      final pieceEnd = acc + p.length;

      if (pieceEnd <= pos || pieceStart >= endPos) {
        // Fuera del rango de borrado: mantener intacta
        result.add(p);
      } else {
        // Hay solapamiento
        final beforeLen = (pos - pieceStart).clamp(0, p.length);
        final afterStart = (endPos - pieceStart).clamp(0, p.length);
        final afterLen = p.length - afterStart;

        if (beforeLen > 0) {
          result.add(Piece(p.bufferId, p.start, beforeLen));
        }
        if (afterLen > 0) {
          result.add(Piece(p.bufferId, p.start + afterStart, afterLen));
        }
      }
      acc += p.length;
    }

    // Limpiar piezas vacías
    _pieces
      ..clear()
      ..addAll(result.where((p) => p.length > 0));
  }

  // ──────────────────────────────────────────────
  //  NAVEGACIÓN POR LÍNEAS
  // ──────────────────────────────────────────────

  /// Obtiene el texto de una línea específica.
  String lineAt(int lineIndex) {
    final lines = text.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return '';
    return lines[lineIndex];
  }

  /// Número total de líneas.
  int get lineCount {
    if (length == 0) return 1;
    int count = 1;
    for (int i = 0; i < length; i++) {
      if (charAt(i) == '\n') count++;
    }
    return count;
  }

  /// Longitud de cada línea (para cálculo de cursor).
  List<int> get lineLengths {
    final fullText = text;
    final lines = fullText.split('\n');
    return lines.map((l) => l.length).toList();
  }

  /// Convierte posición global a (línea, columna).
  (int line, int col) positionToLineCol(int pos) {
    final fullText = text;
    int line = 0;
    int lastNewline = -1;
    for (int i = 0; i < pos && i < fullText.length; i++) {
      if (fullText[i] == '\n') {
        line++;
        lastNewline = i;
      }
    }
    return (line, pos - lastNewline - 1);
  }

  /// Convierte (línea, columna) a posición global.
  int lineColToPosition(int line, int col) {
    final fullText = text;
    int currentLine = 0;
    int pos = 0;
    while (pos < fullText.length && currentLine < line) {
      if (fullText[pos] == '\n') currentLine++;
      pos++;
    }
    return (pos + col).clamp(0, fullText.length);
  }

  @override
  String toString() => 'PieceTable(${_pieces.length} pieces, ${length} chars, v$_version)';
}
