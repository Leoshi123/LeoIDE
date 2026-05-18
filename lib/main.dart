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
      home: const EditorScreen(),
    );
  }
}

/// Pantalla principal del editor de código.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  /// Engine principal del editor.
  late final TextEngine _engine;

  /// Viewport para virtual scrolling.
  late final VirtualViewport _viewport;

  /// Extensión del archivo actual (para la barra de símbolos).
  String _currentExtension = '.dart';

  /// Nombre del archivo actual.
  String _currentFileName = 'sin_titulo.dart';

  /// Código de ejemplo inicial.
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
    _engine = TextEngine(_defaultCode);
    _viewport = VirtualViewport(
      viewportHeight: 600,
      viewportWidth: 400,
      totalLines: _engine.lineCount,
    );
    _updateMaxLineWidth();
  }

  void _updateMaxLineWidth() {
    double maxWidth = 0;
    for (int i = 0; i < _engine.lineCount; i++) {
      maxWidth = maxWidth > (_engine.lineAt(i).length * _viewport.charWidth)
          ? maxWidth
          : _engine.lineAt(i).length * _viewport.charWidth;
    }
    _viewport.maxLineWidth = maxWidth;
  }

  void _onSymbolTap(String symbol) {
    _engine.insertAtCursor(symbol);
    _updateMaxLineWidth();
    setState(() {});
  }

  void _onNewFile() {
    setState(() {
      _engine.loadText('');
      _currentFileName = 'sin_titulo.dart';
      _currentExtension = '.dart';
      _viewport.totalLines = 1;
      _viewport.scrollY = 0;
      _viewport.scrollX = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorColors = _getEditorColors(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentFileName,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
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
            onPressed: () {
              _engine.undo();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 20),
            tooltip: 'Rehacer',
            onPressed: () {
              _engine.redo();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, size: 20),
            tooltip: 'Menú',
            onPressed: () {
              // Placeholder: menú de opciones
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Editor
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Actualizar dimensiones del viewport
                _viewport.viewportHeight = constraints.maxHeight;
                _viewport.viewportWidth = constraints.maxWidth;
                _viewport.totalLines = _engine.lineCount;

                return EditorCanvas(
                  engine: _engine,
                  viewport: _viewport,
                  backgroundColor: editorColors.background,
                  textColor: editorColors.text,
                  lineNumberColor: editorColors.lineNumber,
                  lineNumberBgColor: editorColors.lineNumberBg,
                );
              },
            ),
          ),

          // Barra de símbolos
          SymbolBar(
            fileExtension: _currentExtension,
            onSymbolTap: _onSymbolTap,
          ),
        ],
      ),
    );
  }

  EditorColors _getEditorColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.editorDark : AppTheme.editorLight;
  }
}
