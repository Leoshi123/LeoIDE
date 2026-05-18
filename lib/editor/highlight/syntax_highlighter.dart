import 'package:flutter/material.dart';
import 'syntax_token.dart';
import 'syntax_lexer.dart';

/// Convierte tokens sintácticos en TextSpan coloreados.
///
/// Colores estilo VS Code Dark+ (tema oscuro de LeoIDE).
class SyntaxHighlighter {
  // Tema oscuro VS Code
  static const Color _keyword = Color(0xFF569CD6); // Azul
  static const Color _type = Color(0xFF4EC9B0); // Verde agua
  static const Color _string = Color(0xFFCE9178); // Naranja
  static const Color _comment = Color(0xFF6A9955); // Verde
  static const Color _number = Color(0xFFB5CEA8); // Verde claro
  static const Color _annotation = Color(0xFFDCDCAA); // Amarillo
  static const Color _operator = Color(0xFFD4D4D4); // Blanco
  static const Color _punctuation = Color(0xFFD4D4D4); // Blanco
  static const Color _identifier = Color(0xFF9CDCFE); // Azul claro
  static const Color _variable = Color(0xFF9CDCFE); // Azul claro
  static const Color _property = Color(0xFFCE9178); // Naranja
  static const Color _preprocessor = Color(0xFFC586C0); // Morado
  static const Color _tag = Color(0xFF569CD6); // Azul
  static const Color _attribute = Color(0xFF9CDCFE); // Azul claro
  static const Color _plain = Color(0xFFD4D4D4); // Blanco

  final LanguageConfig config;

  SyntaxHighlighter(this.config);

  /// Convierte [text] con [tokens] en un TextSpan coloreado.
  TextSpan highlight(String text, List<SyntaxToken> tokens) {
    final children = <TextSpan>[];
    int lastEnd = 0;

    for (final token in tokens) {
      // Texto plano entre tokens
      if (token.start > lastEnd) {
        children.add(TextSpan(
          text: text.substring(lastEnd, token.start),
          style: const TextStyle(color: _plain),
        ));
      }

      children.add(TextSpan(
        text: text.substring(token.start, token.end),
        style: TextStyle(color: _colorFor(token.type)),
      ));

      lastEnd = token.end;
    }

    // Resto del texto después del último token
    if (lastEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(color: _plain),
      ));
    }

    return TextSpan(children: children);
  }

  Color _colorFor(TokenType type) {
    switch (type) {
      case TokenType.keyword:
        return _keyword;
      case TokenType.type:
        return _type;
      case TokenType.string:
        return _string;
      case TokenType.comment:
        return _comment;
      case TokenType.number:
        return _number;
      case TokenType.annotation:
        return _annotation;
      case TokenType.operator:
        return _operator;
      case TokenType.punctuation:
        return _punctuation;
      case TokenType.identifier:
        return _identifier;
      case TokenType.variable:
        return _variable;
      case TokenType.property:
        return _property;
      case TokenType.preprocessor:
        return _preprocessor;
      case TokenType.tag:
        return _tag;
      case TokenType.attribute:
        return _attribute;
      case TokenType.plain:
        return _plain;
    }
  }
}
