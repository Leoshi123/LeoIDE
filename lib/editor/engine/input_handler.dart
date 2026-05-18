import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_engine.dart';

/// Conecta el teclado con el TextEngine vía Focus.onKeyEvent.
///
/// Sin TextField oculto, sin TextEditingController, sin loops.
/// Cada tecla se traduce directamente a una operación del engine.
class EditorInputHandler {
  final TextEngine _engine;
  final FocusNode _focusNode;

  VoidCallback? onTextChanged;
  VoidCallback? onCursorMoved;

  EditorInputHandler({
    required TextEngine engine,
    required FocusNode focusNode,
    this.onTextChanged,
    this.onCursorMoved,
  })  : _engine = engine,
        _focusNode = focusNode;

  /// Procesa eventos de teclado (físico y virtual).
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // ── Shortcuts con Ctrl ──
    if (isCtrl) {
      switch (key) {
        case LogicalKeyboardKey.keyZ:
          if (isShift) { _engine.redo(); } else { _engine.undo(); }
          _notifyTextChanged();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyY:
          _engine.redo();
          _notifyTextChanged();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyS:
          // Save placeholder (Fase 4)
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyA:
        case LogicalKeyboardKey.keyC:
        case LogicalKeyboardKey.keyV:
        case LogicalKeyboardKey.keyX:
          // Clipboard operations placeholder (Fase 2)
          return KeyEventResult.handled;
        default:
          break;
      }
    }

    // ── Teclas de edición ──
    switch (key) {
      case LogicalKeyboardKey.backspace:
        _engine.backspace();
        _notifyTextChanged();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.delete:
        _engine.deleteForward();
        _notifyTextChanged();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
        _engine.insertNewline();
        _notifyTextChanged();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.tab:
        _engine.insertTab();
        _notifyTextChanged();
        return KeyEventResult.handled;

      // ── Navegación ──
      case LogicalKeyboardKey.arrowUp:
        _engine.moveCursorUp();
        _notifyCursorMoved();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        _engine.moveCursorDown();
        _notifyCursorMoved();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowLeft:
        _engine.moveCursorLeft();
        _notifyCursorMoved();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
        _engine.moveCursorRight();
        _notifyCursorMoved();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.home:
        _engine.moveToLineStart();
        _notifyCursorMoved();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.end:
        _engine.moveToLineEnd();
        _notifyCursorMoved();
        return KeyEventResult.handled;

      default:
        break;
    }

    // ── Caracteres imprimibles ──
    final label = event.logicalKey.keyLabel;
    if (label.isNotEmpty && label.length <= 2) {
      // Filtra teclas no imprimibles que tienen label vacío
      if (label.codeUnitAt(0) >= 32 && !_isControlLabel(label)) {
        _engine.insertAtCursor(label);
        _notifyTextChanged();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  bool _isControlLabel(String label) {
    // Algunas teclas especiales tienen label pero no son imprimibles
    return label == 'Backspace' || label == 'Delete' || label == 'Enter' ||
        label == 'Tab' || label == 'Escape';
  }

  /// Inserta un símbolo desde la barra de símbolos.
  void insertSymbol(String symbol) {
    _engine.insertAtCursor(symbol);
    _notifyTextChanged();
  }

  void _notifyTextChanged() {
    onTextChanged?.call();
  }

  void _notifyCursorMoved() {
    onCursorMoved?.call();
  }

  void connect() {
    // Para móvil: aquí se conectaría TextInputConnection (Fase 2)
  }

  void disconnect() {}

  void dispose() {}
}
