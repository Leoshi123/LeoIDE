import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_engine.dart';

/// Conecta el teclado virtual/físico de Flutter con el TextEngine.
///
/// En móvil, al tocar el editor necesitamos que aparezca el teclado virtual.
/// En desktop/linux, necesitamos capturar las teclas físicas.
/// Flutter no hace esto automáticamente con CustomPainter, hay que hacerlo
/// manualmente usando TextInputConnection + KeyboardListener.
class EditorInputHandler {
  final TextEngine _engine;
  late TextInputConnection _textInputConnection;
  final TextInputConfiguration _textInputConfig;
  final FocusNode _focusNode;

  // Callbacks para notificar cambios en la UI
  VoidCallback? onTextChanged;
  VoidCallback? onCursorMoved;

  EditorInputHandler({
    required TextEngine engine,
    required FocusNode focusNode,
    TextInputAction textInputAction = TextInputAction.newline,
    this.onTextChanged,
    this.onCursorMoved,
  })  : _engine = engine,
        _focusNode = focusNode,
        _textInputConfig = TextInputConfiguration(
          inputType: TextInputType.multiline,
          autocorrect: false,
          enableSuggestions: false,
          enableDeltaModel: true,
          textInputAction: textInputAction,
        ) {
    _setupTextInput();
  }

  void _setupTextInput() {
    _textInputConnection = TextInput.attach(
      _focusNode,
      _textInputConfig,
    )..setEditingState(_buildEditingState());
  }

  /// Conecta el teclado cuando el editor recibe foco.
  void connect() {
    _textInputConnection = TextInput.attach(
      _focusNode,
      _textInputConfig,
    );
    _updateEditingState();
  }

  /// Desconecta el teclado cuando el editor pierde foco.
  void disconnect() {
    _textInputConnection.close();
  }

  /// Procesa deltas de texto enviados por el teclado virtual.
  void handleDeltas(List<TextEditingDelta> deltas) {
    for (final delta in deltas) {
      if (delta is TextEditingDeltaInsertion) {
        _handleInsertion(delta);
      } else if (delta is TextEditingDeltaDeletion) {
        _handleDeletion(delta);
      } else if (delta is TextEditingDeltaReplacement) {
        _handleReplacement(delta);
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        // Solo movimiento de cursor, selección, etc.
        _handleNonTextUpdate(delta);
      }
    }
    _updateEditingState();
    onTextChanged?.call();
  }

  /// Procesa teclas del teclado físico (Linux/desktop).
  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    // Solo teclas de caracteres imprimibles
    if (event.logicalKey != null && event.logicalKey.keyLabel.isNotEmpty) {
      final label = event.logicalKey.keyLabel;
      if (label.length == 1 && !label.startsWith(' ') && label.codeUnitAt(0) >= 32) {
        _engine.insertAtCursor(label);
        _updateEditingState();
        onTextChanged?.call();
        return;
      }
    }

    // Teclas especiales
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _handleSpecialKey(event);
    }
  }

  /// Procesa inserción desde la barra de símbolos.
  void insertSymbol(String symbol) {
    _engine.insertAtCursor(symbol);
    _updateEditingState();
    onTextChanged?.call();
  }

  // ── Handlers internos ──

  void _handleInsertion(TextEditingDeltaInsertion delta) {
    // Insertar el texto directamente
    _engine.insertAtCursor(delta.text);
  }

  void _handleDeletion(TextEditingDeltaDeletion delta) {
    // Determinar si es backspace o delete forward
    // Por convención, si la longitud del texto decrece en 1+
    final deletedLen = delta.deletedLength;
    if (deletedLen > 0) {
      _engine.backspace(deletedLen);
    }
  }

  void _handleReplacement(TextEditingDeltaReplacement delta) {
    // Reemplazo completo (e.g., pegar texto, IME composition)
    final oldLen = delta.replacedRange.length;
    for (int i = 0; i < oldLen; i++) {
      _engine.backspace();
    }
    _engine.insertAtCursor(delta.replacementText);
  }

  void _handleNonTextUpdate(TextEditingDeltaNonTextUpdate delta) {
    // Solo actualizar cursor si hay nueva selección
    if (delta.selection != null) {
      final newOffset = delta.selection!.baseOffset;
      if (newOffset >= 0 && newOffset <= _engine.length) {
        final (line, col) = _engine.pieceTable.positionToLineCol(newOffset);
        // Move cursor - simplificado, la selección se manejará en Fase 2
      }
    }
  }

  void _handleSpecialKey(KeyEvent event) {
    final key = event.logicalKey;
    final isCtrl = event is KeyDownEvent &&
        (HardwareKeyboard.instance.isControlPressed ||
         HardwareKeyboard.instance.isMetaPressed);
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Backspace
    if (key == LogicalKeyboardKey.backspace) {
      _engine.backspace();
      _updateEditingState();
      onTextChanged?.call();
      return;
    }

    // Delete
    if (key == LogicalKeyboardKey.delete) {
      _engine.deleteForward();
      _updateEditingState();
      onTextChanged?.call();
      return;
    }

    // Enter
    if (key == LogicalKeyboardKey.enter) {
      _engine.insertNewline();
      _updateEditingState();
      onTextChanged?.call();
      return;
    }

    // Tab
    if (key == LogicalKeyboardKey.tab) {
      _engine.insertTab();
      _updateEditingState();
      onTextChanged?.call();
      return;
    }

    // Flechas
    if (key == LogicalKeyboardKey.arrowUp) {
      _engine.moveCursorUp();
      onCursorMoved?.call();
      return;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _engine.moveCursorDown();
      onCursorMoved?.call();
      return;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (isCtrl) {
        // Saltar palabra (placeholder)
      }
      _engine.moveCursorLeft();
      onCursorMoved?.call();
      return;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (isCtrl) {
        // Saltar palabra (placeholder)
      }
      _engine.moveCursorRight();
      onCursorMoved?.call();
      return;
    }

    // Ctrl+Z = Undo
    if (isCtrl && key == LogicalKeyboardKey.keyZ) {
      if (isShift) {
        _engine.redo();
      } else {
        _engine.undo();
      }
      onTextChanged?.call();
      return;
    }

    // Ctrl+Y = Redo
    if (isCtrl && key == LogicalKeyboardKey.keyY) {
      _engine.redo();
      onTextChanged?.call();
      return;
    }

    // Ctrl+A = Seleccionar todo (placeholder)
    if (isCtrl && key == LogicalKeyboardKey.keyA) {
      // Fase 2+
    }

    // Ctrl+S = Guardar (placeholder)
    if (isCtrl && key == LogicalKeyboardKey.keyS) {
      // Fase 4+
    }

    // Home / End
    if (key == LogicalKeyboardKey.home) {
      _engine.moveToLineStart();
      onCursorMoved?.call();
      return;
    }
    if (key == LogicalKeyboardKey.end) {
      _engine.moveToLineEnd();
      onCursorMoved?.call();
      return;
    }
  }

  /// Actualiza el estado de editing en el teclado virtual.
  void _updateEditingState() {
    _textInputConnection?.setEditingState(_buildEditingState());
  }

  TextEditingValue _buildEditingState() {
    final cursor = _engine.cursor;
    final pos = _engine.pieceTable.lineColToPosition(cursor.line, cursor.column);
    return TextEditingValue(
      text: _engine.text,
      selection: TextSelection.collapsed(offset: pos),
      composing: TextRange.empty,
    );
  }

  void dispose() {
    _textInputConnection?.close();
  }
}
