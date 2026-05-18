import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/text_engine.dart';
import '../engine/virtual_viewport.dart';
import '../engine/input_handler.dart';
import 'cursor_painter.dart';

/// Canvas personalizado que renderiza el editor de código.
///
/// Usa Focus.onKeyEvent para capturar el teclado físico (Linux/desktop).
/// Sin TextField oculto, sin TextEditingController — cada tecla se traduce
/// directamente a una operación del TextEngine.
class EditorCanvas extends StatefulWidget {
  final TextEngine engine;
  final VirtualViewport viewport;
  final Color backgroundColor;
  final Color textColor;
  final Color lineNumberColor;
  final Color lineNumberBgColor;
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
    _focusNode = FocusNode(debugLabel: 'LeoEditorFocus');
    _inputHandler = EditorInputHandler(
      engine: widget.engine,
      focusNode: _focusNode,
      onTextChanged: _onEngineChanged,
      onCursorMoved: _onCursorMoved,
    );
  }

  void _onEngineChanged() {
    _cursorPainter.resetBlink();
    _updateViewport();
    widget.onTextChanged?.call();
    if (mounted) setState(() {});
  }

  void _onCursorMoved() {
    _cursorPainter.resetBlink();
    widget.viewport.ensureCursorVisible(
      widget.engine.cursor.line,
      widget.engine.cursor.column,
    );
    if (mounted) setState(() {});
  }

  void _updateViewport() {
    widget.viewport.totalLines = widget.engine.lineCount;
    double maxWidth = 0;
    for (int i = 0; i < widget.engine.lineCount; i++) {
      maxWidth = maxWidth > widget.engine.lineAt(i).length
          ? maxWidth
          : widget.engine.lineAt(i).length.toDouble();
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
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        return _inputHandler?.handleKeyEvent(node, event) ??
            KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTapDown: (details) => _handleTap(details.localPosition),
        onPanUpdate: (details) {
          widget.viewport.scrollBy(-details.delta.dx, -details.delta.dy);
          setState(() {});
        },
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _blinkController,
            builder: (context, _) {
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
  }
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
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = start; i < end; i++) {
      final y = viewport.lineToY(i);
      if (y < -viewport.lineHeight || y > size.height) continue;

      tp.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          color: lineNumberColor,
          fontSize: viewport.lineHeight * 0.7,
          fontFamily: 'monospace',
        ),
      );
      tp.layout(maxWidth: gutterWidth - 10);
      tp.paint(canvas, Offset(gutterWidth - tp.width - 8, y + 3));
    }
  }

  void _drawText(Canvas canvas, Size size) {
    final (start, end) = viewport.visibleRange;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final style = TextStyle(
      color: textColor,
      fontSize: viewport.lineHeight * 0.75,
      fontFamily: 'monospace',
    );

    for (int i = start; i < end; i++) {
      final y = viewport.lineToY(i);
      if (y < -viewport.lineHeight || y > size.height) continue;

      tp.text = TextSpan(
        text: engine.lineAt(i).replaceAll('\t', '  '),
        style: style,
      );
      tp.layout(maxWidth: size.width - gutterWidth - 16);
      tp.paint(canvas, Offset(gutterWidth + 8 - viewport.scrollX, y + 2));
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
    cursorPainter.paint(canvas, x + gutterWidth + 8, y, elapsedSeconds);
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
