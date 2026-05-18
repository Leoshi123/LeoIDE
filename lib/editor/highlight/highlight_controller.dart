import 'package:flutter/material.dart';
import 'syntax_lexer.dart';
import 'syntax_highlighter.dart';

/// TextEditingController que resalta sintaxis en tiempo real.
///
/// Overridea [buildTextSpan] para devolver TextSpan coloreados
/// en lugar del texto plano default.
class HighlightController extends TextEditingController {
  LanguageConfig _config;
  SyntaxLexer? _lastLexer;
  SyntaxHighlighter? _lastHighlighter;
  String _lastText = '';

  HighlightController({String? text, LanguageConfig? config})
      : _config = config ?? LanguageConfig.dart,
        super(text: text);

  /// Cambia el lenguaje activo.
  void setLanguage(LanguageConfig config) {
    _config = config;
    _lastText = '';
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

      // Aplicar el style base del TextField (tamaño, font, etc.)
      return TextSpan(
        style: style,
        children: span.children,
      );
    } catch (_) {
      // Fallback: texto plano si algo falla
      return TextSpan(text: text, style: style);
    }
  }
}
