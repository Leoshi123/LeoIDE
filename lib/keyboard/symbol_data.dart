/// Define los símbolos disponibles en la barra de herramientas del teclado.
///
/// Los símbolos se agrupan por categoría y pueden variar según el lenguaje
/// de programación detectado en el archivo abierto.
class SymbolData {
  /// Símbolos universales (disponibles en todos los lenguajes).
  static const List<String> universal = [
    '(',
    ')',
    '{',
    '}',
    '[',
    ']',
    '<',
    '>',
  ];

  /// Símbolos de operadores y puntuación.
  static const List<String> operators = [
    '=',
    '.',
    ',',
    ';',
    ':',
    "'",
    '"',
    '`',
  ];

  /// Símbolos matemáticos y lógicos.
  static const List<String> math = [
    '+',
    '-',
    '*',
    '/',
    '%',
    '!',
    '&',
    '|',
  ];

  /// Símbolos de flecha y puntero.
  static const List<String> arrows = [
    '->',
    '=>',
    '::',
    '..',
  ];

  /// Símbolos especiales de C/C++.
  static const List<String> cFamily = [
    '#',
    '~',
    '^',
    '?',
    '\\',
    '@',
    '\$',
    '_',
  ];

  /// Todos los símbolos combinados en orden lógico de uso.
  static const List<String> all = [
    // Fila 1: Paréntesis y llaves (los más usados)
    '(', ')', '{', '}', '[', ']',
    // Fila 2: Puntuación y asignación
    ';', ':', ',', '.', '=', '>', '<',
    // Fila 3: Operadores
    '+', '-', '*', '/', '%', '!', '&', '|',
    // Fila 4: Comillas y especiales
    "'", '"', '`', '#', '~', '^', '?', '\\',
    // Fila 5: Flechas (requieren 2 caracteres)
    '->', '=>', '::',
  ];

  /// Obtiene los símbolos más relevantes para un lenguaje específico.
  static List<String> forLanguage(String extension) {
    switch (extension) {
      case '.py':
        return [
          '(', ')', ':', ',', '.', '=', '>',
          '+', '-', '*', '/', '%', '!',
          "'", '"', '#', '_',
          '->', '=>',
        ];
      case '.cpp':
      case '.c':
      case '.h':
        return [
          '(', ')', '{', '}', '[', ']',
          ';', ':', ',', '.', '=', '<', '>',
          '+', '-', '*', '/', '%', '!', '&', '|',
          "'", '"', '#', '~', '^', '?', '\\',
          '->', '::',
        ];
      case '.php':
        return [
          '(', ')', '{', '}', '[', ']',
          ';', ':', ',', '.', '=', '<', '>',
          '+', '-', '*', '/', '%', '!',
          "'", '"', '\$', '\\', '->', '=>', '::',
        ];
      case '.html':
      case '.css':
        return [
          '(', ')', '{', '}', '[', ']',
          ';', ':', ',', '.', '=', '<', '>',
          '+', '-', '*', '/',
          "'", '"', '#', '/', '!',
          '->',
        ];
      default: // .js, .ts, .dart, etc.
        return [
          '(', ')', '{', '}', '[', ']',
          ';', ':', ',', '.', '=', '<', '>',
          '+', '-', '*', '/', '%', '!', '&', '|',
          "'", '"', '`', '\\',
          '=>', '...',
        ];
    }
  }
}
