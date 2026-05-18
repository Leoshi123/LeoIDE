import 'package:flutter/material.dart';

/// Temas de la aplicación LeoIDE.
///
/// Define colores y estilos consistentes para toda la app.
/// Soporta modo claro y oscuro desde el inicio.
class AppTheme {
  // ── Tema Oscuro (por defecto) ──

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF569CD6),       // Azul tipo VS Code
      secondary: Color(0xFFCE9178),     // Naranja cálido
      surface: Color(0xFF252526),       // Superficie ligeramente más clara
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFFD4D4D4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF323233),
      foregroundColor: Color(0xFFCCCCCC),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF252526),
      selectedItemColor: Color(0xFF569CD6),
      unselectedItemColor: Color(0xFF858585),
    ),
  );

  // ── Tema Claro ──

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0066B8),       // Azul intenso
      secondary: Color(0xFFD16969),     // Rojo suave
      surface: Color(0xFFF3F3F3),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFDDDDDD),
      foregroundColor: Color(0xFF333333),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF3F3F3),
      selectedItemColor: Color(0xFF0066B8),
      unselectedItemColor: Color(0xFF999999),
    ),
  );

  // ── Colores del editor ──

  static const editorDark = EditorColors(
    background: Color(0xFF1E1E1E),
    text: Color(0xFFD4D4D4),
    lineNumber: Color(0xFF858585),
    lineNumberBg: Color(0xFF252526),
    cursor: Color(0xFF569CD6),
    gutterBorder: Color(0xFF3C3C3C),
    selection: Color(0xFF264F78),
    lineHighlight: Color(0xFF2A2D2E),
  );

  static const editorLight = EditorColors(
    background: Color(0xFFFFFFFF),
    text: Color(0xFF1E1E1E),
    lineNumber: Color(0xFF999999),
    lineNumberBg: Color(0xFFF3F3F3),
    cursor: Color(0xFF0066B8),
    gutterBorder: Color(0xFFE0E0E0),
    selection: Color(0xFFADD6FF),
    lineHighlight: Color(0xFFF5F5F5),
  );
}

/// Colores del editor de código.
class EditorColors {
  final Color background;
  final Color text;
  final Color lineNumber;
  final Color lineNumberBg;
  final Color cursor;
  final Color gutterBorder;
  final Color selection;
  final Color lineHighlight;

  const EditorColors({
    required this.background,
    required this.text,
    required this.lineNumber,
    required this.lineNumberBg,
    required this.cursor,
    required this.gutterBorder,
    required this.selection,
    required this.lineHighlight,
  });
}
