import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editor/engine/text_engine.dart';
import 'editor/engine/virtual_viewport.dart';
import 'editor/engine/runner.dart';
import 'editor/completion/completion_engine.dart';
import 'editor/completion/models/completion_item.dart';
import 'editor/completion/models/completion_context.dart';
import 'editor/highlight/highlight_controller.dart';
import 'editor/highlight/syntax_lexer.dart';
import 'editor/lsp/lsp_manager.dart';
import 'editor/lsp/models/lsp_types.dart';
import 'editor/widgets/completion_popup.dart';
import 'editor/models/code_template.dart';
import 'editor/engine/language_detector.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeoIDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: EditorScreen(
        onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
        isDark: _isDarkMode,
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const EditorScreen({super.key, this.onToggleTheme, this.isDark = true});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // ── Core ──
  late final TextEngine _engine;
  late final TextEditingController _textController;
  late final CompletionEngine _completionEngine;
  late final LspManager _lspManager;
  Timer? _lspDebounce;
  bool _syncing = false;

  // ── Estado UI ──
  String _currentExtension = '.dart';
  String _currentFileName = 'sin_titulo.dart';
  bool _isDark = true;
  bool _showTerminal = false;
  final List<String> _terminalLog = [];
  bool _isRunning = false;

  // ── Autocompletado ──
  final LayerLink _completionLayerLink = LayerLink();
  OverlayEntry? _completionOverlay;
  final FocusNode _editorFocus = FocusNode();

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
    _completionEngine = CompletionEngine();
    _completionEngine.buildDocument(_defaultCode);
    _lspManager = LspManager();
    _textController = HighlightController(text: _engine.text);
    _textController.addListener(_onTextChanged);
    _editorFocus.addListener(_onFocusChanged);
    _initLspForExtension('.dart');

    // Manejo de teclas para autocompletado
    _editorFocus.onKeyEvent = (node, event) {
      if (_completionItems.isEmpty) return KeyEventResult.ignored;

      if (event is KeyDownEvent) {
        final key = event.logicalKey;
        // Tab → aceptar completado
        if (key == LogicalKeyboardKey.tab ||
            key == LogicalKeyboardKey.enter) {
          _acceptCompletion();
          return KeyEventResult.handled;
        }
        // ↑ ↓ → navegar
        if (key == LogicalKeyboardKey.arrowUp) {
          _completionMoveUp();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _completionMoveDown();
          return KeyEventResult.handled;
        }
        // Esc → cerrar
        if (key == LogicalKeyboardKey.escape) {
          _dismissCompletion();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  /// Inicia el servidor LSP para una extensión.
  void _initLspForExtension(String extension) async {
    final tempPath = '/tmp/leoide/script$extension';
    final client = await _lspManager.startForExtension(extension, tempPath);
    if (client != null) {
      await client.openDocument(_textController.text);
    }
  }

  void _onFocusChanged() {
    if (!_editorFocus.hasFocus) {
      _dismissCompletion();
    }
  }

  // ── Sincronización TextField ↔ Engine ──

  void _onTextChanged() {
    if (_syncing) return;
    _syncing = true;

    final newText = _textController.text;
    if (newText != _engine.text) {
      _engine.loadText(newText);
      _completionEngine.buildDocument(newText);
    }

    // Enviar cambios al LSP (con debounce de 300ms)
    _lspDebounce?.cancel();
    _lspDebounce = Timer(const Duration(milliseconds: 300), () {
      _lspManager.updateDocument(newText);
    });

    final sel = _textController.selection;
    if (sel.isValid && sel.isCollapsed) {
      final pos = sel.baseOffset.clamp(0, _engine.length);
      final (line, col) = _engine.pieceTable.positionToLineCol(pos);
      // Mover cursor del engine a la posición correcta
      final currentLine = _engine.cursor.line;
      final currentCol = _engine.cursor.column;
      if (line != currentLine || col != currentCol) {
        // Reset a (0,0)
        for (int i = 0; i < currentLine; i++) _engine.moveCursorUp();
        for (int i = 0; i < currentCol; i++) _engine.moveCursorLeft();
        // Ir a (line, col)
        for (int i = 0; i < line; i++) _engine.moveCursorDown();
        for (int i = 0; i < col; i++) _engine.moveCursorRight();
      }
    }

    _updateCompletion();
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

  // ── Autocompletado ──

  List<CompletionItem> _completionItems = [];
  int _completionSelectedIndex = 0;

  void _updateCompletion() {
    final sel = _textController.selection;
    if (!sel.isValid || !sel.isCollapsed || sel.baseOffset <= 0) {
      _dismissCompletion();
      return;
    }

    final text = _textController.text;

    // Pedir completaciones locales
    final result = _completionEngine.requestCompletions(
      fullText: text,
      cursorOffset: sel.baseOffset,
    );

    var items = result.sorted;

    // Pedir completaciones LSP y mergear
    if (_lspManager.isActive) {
      final pos = sel.baseOffset;
      // Convertir offset a línea/columna
      int line = 0, col = 0;
      for (int i = 0; i < pos && i < text.length; i++) {
        if (text[i] == '\n') {
          line++;
          col = 0;
        } else {
          col++;
        }
      }
      _requestLspCompletions(line, col).then((lspItems) {
        if (lspItems.isNotEmpty && mounted) {
          _mergeAndShowCompletions(items, lspItems, result.context);
        }
      });
    }

    if (items.isEmpty) {
      _dismissCompletion();
      return;
    }

    _completionItems = items;
    _completionSelectedIndex = 0;
    _showCompletion(result);
  }

  /// Solicita completaciones al LSP y las mergea.
  Future<List<CompletionItem>> _requestLspCompletions(
      int line, int col) async {
    final lspItems = await _lspManager.requestCompletions(line, col);
    if (lspItems.isEmpty) return [];

    return lspItems.map((lsp) {
      CompletionItemKind kind;
      switch (lsp.kind) {
        case 1:
          kind = CompletionItemKind.keyword;
          break;
        case 2:
        case 3:
          kind = CompletionItemKind.method;
          break;
        case 4:
        case 5:
          kind = CompletionItemKind.classs;
          break;
        case 6:
          kind = CompletionItemKind.function;
          break;
        case 7:
          kind = CompletionItemKind.variable;
          break;
        case 9:
          kind = CompletionItemKind.module;
          break;
        case 14:
          kind = CompletionItemKind.snippet;
          break;
        default:
          kind = CompletionItemKind.reference;
      }
      return CompletionItem(
        label: lsp.label,
        insertText: lsp.insertText ?? lsp.label,
        kind: kind,
        detail: lsp.detail ?? 'LSP',
        score: 1.0, // LSP always top
      );
    }).toList();
  }

  /// Mergea resultados LSP con locales (LSP primero).
  void _mergeAndShowCompletions(List<CompletionItem> local,
      List<CompletionItem> lsp, CompletionContext context) {
    // LSP items first, then local (deduplicados por label)
    final seen = <String>{};
    final merged = <CompletionItem>[];

    for (final item in lsp) {
      seen.add(item.label);
      merged.add(item);
    }
    for (final item in local) {
      if (!seen.contains(item.label)) {
        merged.add(item);
      }
    }

    if (merged.isEmpty) {
      _dismissCompletion();
      return;
    }

    _completionItems = merged.take(15).toList();
    _completionSelectedIndex = 0;

    if (mounted) {
      _showCompletion(CompletionResult(
        items: _completionItems,
        context: context,
      ));
    }
  }

  void _showCompletion(CompletionResult result) {
    _dismissCompletion();

    _completionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            left: 56,
            top: 100,
            child: CompositedTransformFollower(
              link: _completionLayerLink,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.topLeft,
              child: CompletionPopup(
                items: _completionItems,
                context: result.context,
                selectedIndex: _completionSelectedIndex,
                onSelected: (insertText) {
                  _insertCompletion(insertText);
                },
                onDismiss: _dismissCompletion,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_completionOverlay!);
  }

  void _insertCompletion(String insertText) {
    final sel = _textController.selection;
    if (!sel.isValid) return;

    final pos = sel.baseOffset;
    final text = _textController.text;

    // Determinar dónde empieza la palabra actual
    int wordStart = pos;
    while (wordStart > 0 && RegExp(r'\w').hasMatch(text[wordStart - 1])) {
      wordStart--;
    }

    // Reemplazar la palabra actual con insertText
    final newText = text.substring(0, wordStart) +
        insertText +
        text.substring(pos);
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: wordStart + insertText.length),
    );
    _dismissCompletion();
  }

  void _dismissCompletion() {
    _completionOverlay?.remove();
    _completionOverlay = null;
    _completionItems = [];
  }

  void _completionMoveUp() {
    if (_completionItems.isEmpty) return;
    setState(() {
      _completionSelectedIndex = (_completionSelectedIndex - 1)
          .clamp(0, _completionItems.length - 1);
    });
    // Reconstruir overlay
    if (_completionOverlay != null) {
      final result = _completionEngine.requestCompletions(
        fullText: _textController.text,
        cursorOffset: _textController.selection.baseOffset,
      );
      if (result.hasItems) _showCompletion(result);
    }
  }

  void _completionMoveDown() {
    if (_completionItems.isEmpty) return;
    setState(() {
      _completionSelectedIndex = (_completionSelectedIndex + 1)
          .clamp(0, _completionItems.length - 1);
    });
    if (_completionOverlay != null) {
      final result = _completionEngine.requestCompletions(
        fullText: _textController.text,
        cursorOffset: _textController.selection.baseOffset,
      );
      if (result.hasItems) _showCompletion(result);
    }
  }

  void _acceptCompletion() {
    if (_completionItems.isEmpty) return;
    if (_completionSelectedIndex < _completionItems.length) {
      _insertCompletion(
          _completionItems[_completionSelectedIndex].insertText);
    }
  }

  // ── Plantillas ──

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark
            ? const Color(0xFF252526)
            : const Color(0xFFF3F3F3),
        title: const Text(
          'Nuevo archivo desde plantilla',
          style: TextStyle(fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: CodeTemplate.all.length,
            itemBuilder: (_, i) {
              final t = CodeTemplate.all[i];
              return ListTile(
                leading: _langIcon(t.extension),
                title: Text(
                  t.name,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  t.extension,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  _loadTemplate(t);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _onNewFile();
              Navigator.pop(ctx);
            },
            child: const Text('Archivo vacío'),
          ),
        ],
      ),
    );
  }

  Widget _langIcon(String ext) {
    Color color;
    switch (ext) {
      case '.dart':
        color = const Color(0xFF0175C2);
        break;
      case '.py':
        color = const Color(0xFF3572A5);
        break;
      case '.cpp':
      case '.c':
        color = const Color(0xFFF34B7D);
        break;
      case '.php':
        color = const Color(0xFF4F5D95);
        break;
      case '.html':
        color = const Color(0xFFE34F26);
        break;
      case '.css':
        color = const Color(0xFF563D7C);
        break;
      case '.js':
        color = const Color(0xFFF7DF1E);
        break;
      default:
        color = const Color(0xFF858585);
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.code, color: color, size: 18),
    );
  }

  void _loadTemplate(CodeTemplate template) {
    setState(() {
      _engine.loadText(template.code);
      _currentFileName = 'nuevo${template.extension}';
      _currentExtension = template.extension;
      _completionEngine.setLanguage(_extToLang(template.extension));
      _completionEngine.buildDocument(template.code);
      (_textController as HighlightController)
          .setLanguage(_extToConfig(template.extension));
      _textController.text = template.code;
      _syncControllerFromEngine();
      _initLspForExtension(template.extension);
    });
  }

  void _onNewFile() {
    setState(() {
      _engine.loadText('');
      _currentFileName = 'sin_titulo.dart';
      _currentExtension = '.dart';
      _completionEngine.setLanguage('dart');
      _completionEngine.buildDocument('');
      (_textController as HighlightController)
          .setLanguage(LanguageConfig.dart);
      _textController.clear();
      _syncControllerFromEngine();
      _initLspForExtension('.dart');
    });
  }

  /// Convierte extensión → nombre de lenguaje (para completion).
  String _extToLang(String ext) {
    switch (ext) {
      case '.py':
        return 'python';
      case '.c':
        return 'c';
      case '.cpp':
      case '.cc':
      case '.cxx':
        return 'cpp';
      case '.js':
      case '.mjs':
        return 'javascript';
      case '.php':
        return 'php';
      case '.html':
      case '.htm':
        return 'html';
      case '.css':
        return 'css';
      case '.dart':
      default:
        return 'dart';
    }
  }

  /// Convierte extensión → LanguageConfig (para highlighting).
  LanguageConfig _extToConfig(String ext) {
    switch (ext) {
      case '.py':
        return LanguageConfig.python;
      case '.c':
        return LanguageConfig.c;
      case '.cpp':
      case '.cc':
      case '.cxx':
        return LanguageConfig.cpp;
      case '.js':
      case '.mjs':
        return LanguageConfig.javascript;
      case '.php':
        return LanguageConfig.php;
      case '.html':
      case '.htm':
        return LanguageConfig.html;
      case '.css':
        return LanguageConfig.css;
      case '.dart':
      default:
        return LanguageConfig.dart;
    }
  }

  // ── Run / Stop ──

  CodeRunner? _currentRunner;

  void _onRun() async {
    final code = _textController.text.trim();
    if (code.isEmpty) {
      _logToTerminal('⚠️ No hay código para ejecutar.');
      return;
    }

    // Detectar lenguaje por contenido
    final detected = LanguageDetector.detect(code,
        hintExtension: _currentExtension);
    String ext = _currentExtension;
    if (detected.isValid && detected.extension != _currentExtension) {
      _logToTerminal(
          '🔍 Detectado ${detected.language} por contenido del código');
      ext = detected.extension;
    }

    final runner = runnerForExtension(ext);
    if (runner == null) {
      _logToTerminal('❌ No hay runner disponible para $_currentExtension');
      _logToTerminal('   Lenguajes soportados: .py, .c, .cpp, .js, .php, .dart, .html, .css');
      return;
    }

    setState(() {
      _isRunning = true;
      _showTerminal = true;
      _terminalLog.clear();
      _currentRunner = runner;
    });

    _logToTerminal('╔══════════════════════════════════════════');
    _logToTerminal('║ ▶  Ejecutando: $_currentFileName');
    _logToTerminal('║    Lenguaje: ${runner.language}');
    _logToTerminal('║    ${_engine.lineCount} líneas · ${_engine.length} caracteres');
    _logToTerminal('╚══════════════════════════════════════════');
    _logToTerminal('');

    final stopwatch = Stopwatch()..start();

    if (runner is CRunner || runner is CppRunner) {
      _logToTerminal('🔨 Compilando...');
    } else {
      _logToTerminal('🚀 Ejecutando...');
    }
    _logToTerminal('');

    try {
      final result = await runner.run(
        code,
        onOutput: (line, isError) {
          if (!_isRunning && mounted) return; // cancelado
          _logToTerminal(isError ? '⚠️  $line' : '   $line');
        },
      );

      stopwatch.stop();

      if (!mounted) return;

      _logToTerminal('');
      if (result.success) {
        _logToTerminal('✅ Proceso completado (${result.duration.inMilliseconds}ms)');
      } else if (_isRunning) {
        _logToTerminal('❌ Proceso terminado con código ${result.exitCode}');
      }
    } catch (e) {
      if (!mounted) return;
      stopwatch.stop();
      _logToTerminal('');
      _logToTerminal('❌ Error del sistema: $e');
    }

    if (mounted) setState(() => _isRunning = false);
  }

  void _onStop() {
    _logToTerminal('');
    _logToTerminal('⛔ Deteniendo proceso...');
    _currentRunner?.cancel();
    _currentRunner = null;
    setState(() => _isRunning = false);
    _logToTerminal('⛔ Proceso detenido por el usuario.');
  }

  void _logToTerminal(String line) {
    setState(() => _terminalLog.add(line));
  }

  void _clearTerminal() {
    setState(() => _terminalLog.clear());
  }

  // ── Undo / Redo ──

  void _onUndo() {
    _engine.undo();
    _completionEngine.buildDocument(_engine.text);
    _syncControllerFromEngine();
  }

  void _onRedo() {
    _engine.redo();
    _completionEngine.buildDocument(_engine.text);
    _syncControllerFromEngine();
  }

  @override
  void dispose() {
    _lspDebounce?.cancel();
    _lspManager.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _editorFocus.dispose();
    _dismissCompletion();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final textColor =
        _isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1E1E1E);
    final gutterBg =
        _isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    final gutterText =
        _isDark ? const Color(0xFF858585) : const Color(0xFF999999);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentFileName,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Nuevo archivo (plantillas)',
            onPressed: _showTemplateDialog,
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
          // Botón Run
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              size: 22,
              color: _isRunning ? const Color(0xFF4EC9B0) : null,
            ),
            tooltip: 'Ejecutar código',
            onPressed: _isRunning ? null : _onRun,
          ),
          // Botón Stop
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.stop, size: 22, color: Colors.redAccent),
              tooltip: 'Detener ejecución',
              onPressed: _onStop,
            ),
        // ── Botón Run ──
        // Botón terminal
        IconButton(
          icon: Icon(
            _showTerminal ? Icons.terminal : Icons.terminal_outlined,
            size: 20,
          ),
          tooltip: 'Terminal',
          onPressed: () => setState(() => _showTerminal = !_showTerminal),
        ),
          IconButton(
            icon: Icon(
              _isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
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
          // Editor
          Expanded(
            child: Container(
              color: bgColor,
              child: Stack(
                children: [
                  // Gutter
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 50,
                      color: gutterBg,
                      padding:
                          const EdgeInsets.only(top: 10, right: 8, bottom: 8),
                      child: _LineNumbers(
                        text: _textController.text,
                        isDark: _isDark,
                        gutterTextColor: gutterText,
                      ),
                    ),
                  ),
                  // Editor
                  Padding(
                    padding: const EdgeInsets.only(left: 56.0),
                    child: CompositedTransformTarget(
                      link: _completionLayerLink,
                      child: TextField(
                        controller: _textController,
                        focusNode: _editorFocus,
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
                          color: textColor,
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
                  ),
                ],
              ),
            ),
          ),

          // Terminal (panel de salida)
          if (_showTerminal)
            _TerminalPanel(
              logs: _terminalLog,
              isDark: _isDark,
              onClear: _clearTerminal,
            ),

          // Barra de símbolos
          SymbolBar(
            fileExtension: _currentExtension,
            onSymbolTap: (symbol) {
              _engine.insertAtCursor(symbol);
              _syncControllerFromEngine();
            },
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

// ── Widgets auxiliares ──

/// Números de línea en el gutter.
class _LineNumbers extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color gutterTextColor;

  const _LineNumbers({
    required this.text,
    required this.isDark,
    required this.gutterTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final lines = '\n'.allMatches(text).length + 1;
    // Solo mostrar las primeras 200 líneas en el gutter
    final visible = lines > 200 ? 200 : lines;

    return ListView.builder(
      itemCount: visible,
      itemExtent: 21.0, // fontSize 14 * height 1.5
      itemBuilder: (context, i) {
        return Text(
          '${i + 1}',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.0,
            height: 1.75,
            color: gutterTextColor,
          ),
        );
      },
    );
  }
}

/// Panel de terminal para mostrar salida de ejecución.
class _TerminalPanel extends StatelessWidget {
  final List<String> logs;
  final bool isDark;
  final VoidCallback onClear;

  const _TerminalPanel({
    required this.logs,
    required this.isDark,
    required this.onClear,
  });

  void _copyAll(BuildContext context) {
    final text = logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Terminal copiado al portapapeles'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
      child: Column(
        children: [
          // Barra de título
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFDDDDDD),
            child: Row(
              children: [
                Text(
                  'TERMINAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF858585)
                        : const Color(0xFF666666),
                  ),
                ),
                const Spacer(),
                // Copiar todo
                if (logs.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _copyAll(context),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF858585)
                          : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF858585)
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'Presiona ▶ Run para ejecutar código',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFF999999),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      logs.join('\n'),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
