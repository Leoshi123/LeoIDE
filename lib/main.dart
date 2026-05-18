import 'package:flutter/material.dart';
import 'editor/engine/text_engine.dart';
import 'editor/engine/virtual_viewport.dart';
import 'editor/widgets/editor_canvas.dart';
import 'keyboard/symbol_bar.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LeoIDEApp());
}

class LeoIDEApp extends StatefulWidget {
  const LeoIDEApp({super.key});

  @override
  State<LeoIDEApp> createState() => _LeoIDEAppState();
}

class _LeoIDEAppState extends State<LeoIDEApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeoIDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: EditorScreen(onToggleTheme: _toggleTheme, isDark: _isDarkMode),
    );
  }
}

/// Pantalla principal del editor de código.
class EditorScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const EditorScreen({super.key, this.onToggleTheme, this.isDark = true});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEngine _engine;
  late final TextEditingController _textController;
  bool _syncing = false;

  String _currentExtension = '.dart';
  String _currentFileName = 'sin_titulo.dart';
  bool _isDark = true;

  static const String _defaultCode = '''import 'dart:io';

void main() {
  print("Hello, LeoIDE!");

  // Tu código aquí
  for (int i = 0; i < 10; i++) {
    print("Línea \$i");
  }
}
''';

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    _engine = TextEngine(_defaultCode);
    _textController = TextEditingController(text: _engine.text);
    _textController.addListener(_onTextChanged);

    // Posicionar cursor al final del texto de ejemplo
    final len = _engine.length;
    _textController.selection = TextSelection.collapsed(offset: len);
    for (int i = 0; i < _engine.lineCount; i++) {
      _engine.moveCursorDown();
    }
  }

  void _onTextChanged() {
    if (_syncing) return;
    _syncing = true;

    final newText = _textController.text;
    if (newText != _engine.text) {
      _engine.loadText(newText);
    }

    // Actualizar cursor del engine desde la selección del controller
    final sel = _textController.selection;
    if (sel.isValid && sel.isCollapsed) {
      final pos = sel.baseOffset.clamp(0, _engine.length);
      final (line, col) = _engine.pieceTable.positionToLineCol(pos);
      // Reset cursor a (0,0) y navegar
      for (int i = _engine.cursor.line; i > 0; i--) {
        _engine.moveCursorUp();
      }
      for (int i = _engine.cursor.column; i > 0; i--) {
        _engine.moveCursorLeft();
      }
      for (int i = 0; i < line; i++) {
        _engine.moveCursorDown();
      }
      for (int i = 0; i < col; i++) {
        _engine.moveCursorRight();
      }
    }

    _syncing = false;
  }

  void _syncControllerFromEngine() {
    _syncing = true;
    final cursor = _engine.cursor;
    final pos = _engine.pieceTable.lineColToPosition(cursor.line, cursor.column);

    _textController.value = TextEditingValue(
      text: _engine.text,
      selection: TextSelection.collapsed(offset: pos),
    );
    _syncing = false;
  }

  void _onSymbolTap(String symbol) {
    _engine.insertAtCursor(symbol);
    _syncControllerFromEngine();
  }

  void _onUndo() {
    _engine.undo();
    _syncControllerFromEngine();
  }

  void _onRedo() {
    _engine.redo();
    _syncControllerFromEngine();
  }

  void _onNewFile() {
    _engine.loadText('');
    _currentFileName = 'sin_titulo.dart';
    _currentExtension = '.dart';
    _syncControllerFromEngine();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentFileName,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Nuevo archivo',
            onPressed: _onNewFile,
          ),
          IconButton(
            icon: const Icon(Icons.undo, size: 20),
            tooltip: 'Deshacer',
            onPressed: _onUndo,
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 20),
            tooltip: 'Rehacer',
            onPressed: _onRedo,
          ),
          IconButton(
            icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
            tooltip: 'Cambiar tema',
            onPressed: () {
              setState(() => _isDark = !_isDark);
              widget.onToggleTheme?.call();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Editor de código (TextField con estilo VS Code)
          Expanded(
            child: Container(
              color: _isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFFFFFFF),
              child: Stack(
                children: [
                  // Números de línea (gutter)
                  _LineNumberGutter(
                    text: _textController.text,
                    isDark: _isDark,
                  ),
                  // Campo de texto
                  Padding(
                    padding: const EdgeInsets.only(left: 56.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      autofocus: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14.0,
                        height: 1.5,
                        color: _isDark
                            ? const Color(0xFFD4D4D4)
                            : const Color(0xFF1E1E1E),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(
                          top: 8,
                          right: 8,
                          bottom: 8,
                        ),
                        isCollapsed: true,
                      ),
                      cursorColor: _isDark
                          ? const Color(0xFF569CD6)
                          : const Color(0xFF0066B8),
                      cursorWidth: 2.0,
                      scrollPhysics: const ClampingScrollPhysics(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra de símbolos
          SymbolBar(
            fileExtension: _currentExtension,
            onSymbolTap: _onSymbolTap,
            backgroundColor: _isDark
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFE0E0E0),
            buttonColor: _isDark
                ? const Color(0xFF3C3C3C)
                : const Color(0xFFD0D0D0),
            symbolColor: _isDark
                ? const Color(0xFFCCCCCC)
                : const Color(0xFF333333),
          ),
        ],
      ),
    );
  }
}

/// Gutter de números de línea a la izquierda del editor.
class _LineNumberGutter extends StatelessWidget {
  final String text;
  final bool isDark;

  const _LineNumberGutter({
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lines = '\n'.allMatches(text).length + 1;

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 50,
        color: isDark
            ? const Color(0xFF252526)
            : const Color(0xFFF3F3F3),
        padding: const EdgeInsets.only(top: 10, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 1; i <= lines && i < 500; i++)
              Text(
                '$i',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.0,
                  height: 1.75,
                  color: isDark
                      ? const Color(0xFF858585)
                      : const Color(0xFF999999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
