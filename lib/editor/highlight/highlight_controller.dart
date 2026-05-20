import 'package:flutter/material.dart';
import 'syntax_lexer.dart';
import 'syntax_highlighter.dart';
import '../lsp/models/lsp_types.dart';

/// TextEditingController que resalta sintaxis en tiempo real.
///
/// Además mantiene diagnostics del LSP para que el editor
/// pueda mostrar indicadores de error.
class HighlightController extends TextEditingController {
  LanguageConfig _config;
  SyntaxLexer? _lastLexer;
  SyntaxHighlighter? _lastHighlighter;
  String _lastText = '';

  /// Diagnostics activos del LSP (errores, warnings, etc).
  List<LspDiagnostic> diagnostics = const [];

  /// Líneas que tienen al menos un error (severity=1).
  Set<int> errorLines = {};

  /// Líneas que tienen al menos un warning (severity=2).
  Set<int> warningLines = {};

  HighlightController({String? text, LanguageConfig? config})
      : _config = config ?? LanguageConfig.dart,
        super(text: text);

  /// Cambia el lenguaje activo.
  void setLanguage(LanguageConfig config) {
    _config = config;
    _lastText = '';
    notifyListeners();
  }

  /// Actualiza diagnostics y refresca el editor.
  void updateDiagnostics(List<LspDiagnostic> diags) {
    diagnostics = diags;
    errorLines = {};
    warningLines = {};

    for (final d in diags) {
      switch (d.severity) {
        case DiagnosticSeverity.error:
          errorLines.add(d.startLine);
        case DiagnosticSeverity.warning:
          warningLines.add(d.startLine);
        default:
          break;
      }
    }
    notifyListeners();
  }

  bool _isParsing = false;
  List<SyntaxToken>? _lastTokens;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final currentText = this.text;

    if (currentText.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    if (currentText != _lastText && !_isParsing) {
      _isParsing = true;
      final parseText = currentText;
      SyntaxLexer.parseIsolate(_config, parseText).then((tokens) {
        _lastText = parseText;
        _lastTokens = tokens;
        _isParsing = false;
        
        // Only notify if we are still active and need a repaint
        if (text == parseText) {
          notifyListeners();
        } else {
          // The text changed while parsing, trigger another parse
          // But we don't do it here directly, notifyListeners() will trigger buildTextSpan again.
          notifyListeners(); 
        }
      });
    }

    // While parsing, or if tokens don't match text length, return plain text
    // (A more advanced solution would clamp tokens, but plain text avoids crash)
    if (_isParsing || _lastTokens == null || _lastText != currentText) {
      return TextSpan(text: currentText, style: style);
    }

    try {
      _lastHighlighter ??= SyntaxHighlighter(_config);
      final span = _lastHighlighter!.highlight(currentText, _lastTokens!);

      return TextSpan(
        style: style,
        children: span.children,
      );
    } catch (_) {
      return TextSpan(text: currentText, style: style);
    }
  }
}
