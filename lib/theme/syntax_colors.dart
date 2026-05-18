import 'package:flutter/material.dart';

/// Colores base para el resaltado de sintaxis.
///
/// Estos colores se usarán en la Fase 2 cuando implementemos el Lexer.
/// Por ahora definimos la paleta completa para tenerla lista.
class SyntaxColors {
  // ── Tema Oscuro (VS Code Dark+) ──

  static const dark = SyntaxPalette(
    keyword: Color(0xFF569CD6),       // Azul: if, else, for, while, class
    string: Color(0xFFCE9178),        // Naranja: "texto", 'texto'
    number: Color(0xFFB5CEA8),        // Verde: 42, 3.14, 0xFF
    comment: Color(0xFF6A9955),       // Verde oliva: // comentario
    type: Color(0xFF4EC9B0),          // Verde agua: int, String, bool
    function: Color(0xFFDCDCAA),      // Amarillo: nombreFunción()
    variable: Color(0xFF9CDCFE),      // Azul claro: nombreVariable
    operator: Color(0xFFD4D4D4),      // Gris: +, -, *, /, =
    punctuation: Color(0xFFD4D4D4),   // Gris: ;, {, }, (, )
    constant: Color(0xFF4FC1FF),      // Azul cielo: true, false, null
    plain: Color(0xFFD4D4D4),         // Texto plano
    background: Color(0xFF1E1E1E),    // Fondo
  );

  // ── Tema Claro ──

  static const light = SyntaxPalette(
    keyword: Color(0xFF0000FF),       // Azul
    string: Color(0xFFA31515),        // Rojo oscuro
    number: Color(0xFF098658),        // Verde
    comment: Color(0xFF008000),       // Verde
    type: Color(0xFF267F99),          // Azul verdoso
    function: Color(0xFF795E26),      // Marrón
    variable: Color(0xFF001080),      // Azul oscuro
    operator: Color(0xFF000000),      // Negro
    punctuation: Color(0xFF000000),   // Negro
    constant: Color(0xFF0070C1),      // Azul
    plain: Color(0xFF000000),         // Negro
    background: Color(0xFFFFFFFF),    // Blanco
  );
}

/// Paleta de colores completa para un tema de sintaxis.
class SyntaxPalette {
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;
  final Color type;
  final Color function;
  final Color variable;
  final Color operator;
  final Color punctuation;
  final Color constant;
  final Color plain;
  final Color background;

  const SyntaxPalette({
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.type,
    required this.function,
    required this.variable,
    required this.operator,
    required this.punctuation,
    required this.constant,
    required this.plain,
    required this.background,
  });
}
