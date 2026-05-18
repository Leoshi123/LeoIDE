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

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;

    // Solo re-tokenizar si el texto cambió
    if (text != _lastText) {
      _lastText = text;
      _lastLexer = SyntaxLexer(_config, text);
      _lastHighlighter = SyntaxHighlighter(_config);
    }

    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    try {
      final tokens = _lastLexer!.tokenize();
      final span = _lastHighlighter!.highlight(text, tokens);

      return TextSpan(
        style: style,
        children: span.children,
      );
    } catch (_) {
      return TextSpan(text: text, style: style);
    }
  }
}
