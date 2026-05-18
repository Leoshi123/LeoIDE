import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/text_engine.dart';
import '../engine/virtual_viewport.dart';
import '../engine/input_handler.dart';
import 'cursor_painter.dart';

/// Canvas personalizado que renderiza el editor de código.
///
/// Usa CustomPainter de Flutter para dibujar solo las líneas visibles
/// (virtual scrolling), más el cursor, números de línea y manejo de input.
class EditorCanvas extends StatefulWidget {
  final TextEngine engine;
  final VirtualViewport viewport;
  final Color backgroundColor;
  final Color textColor;
  final Color lineNumberColor;
  final Color lineNumberBgColor;

  /// Callback cuando el texto cambia (para que el padre actualice estado).
  final VoidCallback? onTextChanged;

  const EditorCanvas({
    super.key,
    required this.engine,
    required this.viewport,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.textColor = const Color(0xFFD4D4D4),
    this.lineNumberColor = const Color(0xFF858585),
    this.lineNumberBgColor = const Color(0xFF252526),
    this.onTextChanged,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas>
    with SingleTickerProviderStateMixin {
  late CursorPainter _cursorPainter;
  late AnimationController _blinkController;
  late FocusNode _focusNode;
  EditorInputHandler? _inputHandler;

  @override
  void initState() {
    super.initState();
    _cursorPainter = CursorPainter(
      charWidth: widget.viewport.charWidth,
      lineHeight: widget.viewport.lineHeight,
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _focusNode = FocusNode();
    _setupInputHandler();
  }

  void _setupInputHandler() {
    _inputHandler = EditorInputHandler(
      engine: widget.engine,
      focusNode: _focusNode,
      onTextChanged: () {
        _cursorPainter.resetBlink();
        _updateViewport();
        widget.onTextChanged?.call();
        if (mounted) setState(() {});
      },
      onCursorMoved: () {
        _cursorPainter.resetBlink();
        widget.viewport.ensureCursorVisible(
          widget.engine.cursor.line,
          widget.engine.cursor.column,
        );
        if (mounted) setState(() {});
      },
    );
  }

  void _updateViewport() {
    widget.viewport.totalLines = widget.engine.lineCount;
    // Actualizar maxLineWidth
    double maxWidth = 0;
    for (int i = 0; i < widget.engine.lineCount; i++) {
      final lineLen = widget.engine.lineAt(i).length.toDouble();
      maxWidth = maxWidth > lineLen ? maxWidth : lineLen;
    }
    widget.viewport.maxLineWidth = maxWidth * widget.viewport.charWidth;
  }

  @override
  void dispose() {
    _inputHandler?.dispose();
    _focusNode.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details.localPosition),
      onPanStart: (details) => _handlePanStart(details.localPosition),
      onPanUpdate: (details) => _handlePanUpdate(details.delta),
      onPanEnd: (_) => _handlePanEnd(),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        includeSemantics: false,
        onKeyEvent: (event) {
          _inputHandler?.handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              return CustomPaint(
                painter: _EditorPainter(
                  engine: widget.engine,
                  viewport: widget.viewport,
                  cursorPainter: _cursorPainter,
                  backgroundColor: widget.backgroundColor,
                  textColor: widget.textColor,
                  lineNumberColor: widget.lineNumberColor,
                  lineNumberBgColor: widget.lineNumberBgColor,
                  elapsedSeconds:
                      (_blinkController.lastElapsedDuration?.inMilliseconds ?? 0)
                              .toDouble() /
                          1000.0,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    _focusNode.requestFocus();
    widget.engine.moveCursorToTouch(
      touchX: position.dx,
      touchY: position.dy,
      scrollX: widget.viewport.scrollX,
      scrollY: widget.viewport.scrollY,
      charWidth: widget.viewport.charWidth,
      lineHeight: widget.viewport.lineHeight,
    );
    _cursorPainter.resetBlink();
    setState(() {});

    // En móvil, esto activa el teclado virtual
    _inputHandler?.connect();
  }

  void _handlePanStart(Offset position) {}

  void _handlePanUpdate(Offset delta) {
    widget.viewport.scrollBy(-delta.dx, -delta.dy);
    setState(() {});
  }

  void _handlePanEnd() {}
}

/// Painter que renderiza líneas de texto, cursor y números de línea.
class _EditorPainter extends CustomPainter {
  final TextEngine engine;
  final VirtualViewport viewport;
  final CursorPainter cursorPainter;
  final Color backgroundColor;
  final Color textColor;
  final Color lineNumberColor;
  final Color lineNumberBgColor;
  final double elapsedSeconds;

  static const double gutterWidth = 50.0;

  _EditorPainter({
    required this.engine,
    required this.viewport,
    required this.cursorPainter,
    required this.backgroundColor,
    required this.textColor,
    required this.lineNumberColor,
    required this.lineNumberBgColor,
    required this.elapsedSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawLineNumbers(canvas, size);
    _drawText(canvas, size);
    _drawCursor(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gutterWidth, size.height),
      Paint()..color = lineNumberBgColor,
    );
    canvas.drawLine(
      Offset(gutterWidth, 0),
      Offset(gutterWidth, size.height),
      Paint()
        ..color = lineNumberColor.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }

  void _drawLineNumbers(Canvas canvas, Size size) {
    final (start, end) = viewport.visibleRange;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = start; i < end; i++) {
      final y = viewport.lineToY(i);
      if (y < -viewport.lineHeight || y > size.height) continue;

      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          color: lineNumberColor,
          fontSize: viewport.lineHeight * 0.7,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout(maxWidth: gutterWidth - 10);
      textPainter.paint(
        canvas,
        Offset(gutterWidth - textPainter.width - 8, y + 3),
      );
    }
  }

  void _drawText(Canvas canvas, Size size) {
    final (start, end) = viewport.visibleRange;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: textColor,
      fontSize: viewport.lineHeight * 0.75,
      fontFamily: 'monospace',
    );

    for (int i = start; i < end; i++) {
      final y = viewport.lineToY(i);
      if (y < -viewport.lineHeight || y > size.height) continue;

      final lineText = engine.lineAt(i);
      final displayText = lineText.replaceAll('\t', '  ');
      final x = gutterWidth + 8 - viewport.scrollX;

      textPainter.text = TextSpan(text: displayText, style: textStyle);
      textPainter.layout(maxWidth: size.width - gutterWidth - 16);
      textPainter.paint(canvas, Offset(x, y + 2));
    }
  }

  void _drawCursor(Canvas canvas) {
    final cursor = engine.cursor;
    final (x, y) = cursor.toPixel(
      scrollX: viewport.scrollX,
      scrollY: viewport.scrollY,
      charWidth: viewport.charWidth,
      lineHeight: viewport.lineHeight,
    );
    final cursorScreenX = x + gutterWidth + 8;
    cursorPainter.paint(canvas, cursorScreenX, y, elapsedSeconds);
  }

  @override
  bool shouldRepaint(covariant _EditorPainter oldDelegate) => true;
}

/// Wrapper para animación del parpadeo del cursor.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
