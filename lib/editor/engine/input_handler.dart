import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_engine.dart';
import 'dart:math';

/// Conecta el teclado con el TextEngine.
///
/// Para teclado físico (Linux/desktop): usa Focus.onKeyEvent.
/// Para teclado virtual (Android): usa un TextField oculto.
class EditorInputHandler {
  final TextEngine _engine;
  final FocusNode _focusNode;

  /// Controller sincronizado con el engine para el teclado virtual.
  late final TextEditingController _controller;

  /// Flag para evitar loops al sincronizar.
  bool _syncing = false;

  VoidCallback? onTextChanged;
  VoidCallback? onCursorMoved;

  EditorInputHandler({
    required TextEngine engine,
    required FocusNode focusNode,
    this.onTextChanged,
    this.onCursorMoved,
  })  : _engine = engine,
        _focusNode = focusNode {
    _controller = TextEditingController(text: _engine.text);
    _controller.addListener(_onControllerChanged);
  }

  TextEditingController get controller => _controller;

  /// Procesa teclas del teclado físico vía Focus.onKeyEvent.
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // --- Shortcuts con Ctrl ---
    if (isCtrl) {
      switch (key) {
        case LogicalKeyboardKey.keyZ:
          if (isShift) {
            _engine.redo();
          } else {
            _engine.undo();
          }
          _syncControllerFromEngine();
          onTextChanged?.call();
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyY:
          _engine.redo();
          _syncControllerFromEngine();
          onTextChanged?.call();
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyA:
          // Select all (placeholder Fase 2)
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyS:
          // Save (placeholder Fase 4)
          return KeyEventResult.handled;

        default:
          break;
      }
    }

    // --- Teclas de navegación ---
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        _engine.moveCursorUp();
        onCursorMoved?.call();
        _syncControllerFromEngine();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        _engine.moveCursorDown();
        onCursorMoved?.call();
        _syncControllerFromEngine();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowLeft:
        _engine.moveCursorLeft();
        onCursorMoved?.call();
        _syncControllerFromEngine();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
        _engine.moveCursorRight();
        onCursorMoved?.call();
        _syncControllerFromEngine();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.home:
        _engine.moveToLineStart();
        onCursorMoved?.call();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.end:
        _engine.moveToLineEnd();
        onCursorMoved?.call();
        return KeyEventResult.handled;

      default:
        break;
    }

    return KeyEventResult.ignored;
  }

  /// Procesa entrada de texto desde el teclado físico caracter por caracter.
  void handleTextInput(String text) {
    if (text.isEmpty) return;

    _syncing = true;

    for (final char in text.characters) {
      if (char == '\n') {
        _engine.insertNewline();
      } else if (char.codeUnitAt(0) == 127) { // Delete
        _engine.deleteForward();
      } else if (char.codeUnitAt(0) == 8) { // Backspace
        _engine.backspace();
      } else {
        _engine.insertAtCursor(char);
      }
    }

    _syncing = false;
    _syncControllerFromEngine();
    onTextChanged?.call();
  }

  /// Procesa entrada desde la barra de símbolos.
  void insertSymbol(String symbol) {
    _engine.insertAtCursor(symbol);
    _syncControllerFromEngine();
    onTextChanged?.call();
  }

  /// Sincroniza el controller desde el engine (después de undo/redo/navegación).
  void _syncControllerFromEngine() {
    _syncing = true;
    final cursor = _engine.cursor;
    final pos = _engine.pieceTable.lineColToPosition(cursor.line, cursor.column);

    _controller.value = TextEditingValue(
      text: _engine.text,
      selection: TextSelection.collapsed(offset: pos),
    );
    _syncing = false;
  }

  /// Cuando el TextField oculto cambia, sincronizar con el engine.
  void _onControllerChanged() {
    if (_syncing) return;
    _syncing = true;

    final oldText = _engine.text;
    final newText = _controller.text;

    if (oldText != newText) {
      // Hacer diff simple: reemplazar todo el texto
      // (el TextField oculto maneja cambios carácter por carácter,
      //  pero por simplicidad hacemos replace del texto completo)
      _engine.loadText(newText);

      // Actualizar cursor desde la selección del controller
      final sel = _controller.selection;
      if (sel.isValid && sel.isCollapsed) {
        final (line, col) = _engine.pieceTable.positionToLineCol(sel.baseOffset);
        // Mover cursor usando el engine (simplificado)
        for (int i = 0; i < 100 && _engine.cursor.line < line; i++) {
          _engine.moveCursorDown();
        }
        for (int i = 0; i < 100 && _engine.cursor.column < col; i++) {
          _engine.moveCursorRight();
        }
      }
    }

    _syncing = false;
    onTextChanged?.call();
  }

  /// Conecta al inicio (focus recibido).
  void connect() {
    _syncControllerFromEngine();
  }

  /// Desconecta al perder focus.
  void disconnect() {}

  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
  }
}
