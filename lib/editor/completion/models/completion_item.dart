/// Tipo de item de completado.
enum CompletionItemKind {
  keyword,
  method,
  function,
  classs,
  variable,
  property,
  module,
  snippet,
  constructor,
  interface,
  value,
  reference,
}

/// Un item de completado individual.
class CompletionItem {
  final String label;
  final String insertText;
  final CompletionItemKind kind;
  final String detail;
  final String? documentation;
  final double score;

  const CompletionItem({
    required this.label,
    required this.insertText,
    required this.kind,
    this.detail = '',
    this.documentation,
    this.score = 0.0,
  });

  /// Orden de prioridad visual (menor = más arriba).
  int get priority {
    switch (kind) {
      case CompletionItemKind.snippet:
        return 0;
      case CompletionItemKind.classs:
      case CompletionItemKind.interface:
        return 1;
      case CompletionItemKind.method:
      case CompletionItemKind.function:
        return 2;
      case CompletionItemKind.constructor:
        return 3;
      case CompletionItemKind.property:
        return 4;
      case CompletionItemKind.variable:
        return 5;
      case CompletionItemKind.keyword:
        return 6;
      case CompletionItemKind.module:
        return 7;
      case CompletionItemKind.value:
        return 8;
      case CompletionItemKind.reference:
        return 9;
    }
  }

  /// Carácter icono para la UI.
  String get icon {
    switch (kind) {
      case CompletionItemKind.keyword:
        return 'K';
      case CompletionItemKind.method:
      case CompletionItemKind.function:
        return 'ƒ';
      case CompletionItemKind.classs:
      case CompletionItemKind.interface:
        return 'C';
      case CompletionItemKind.variable:
        return 'x';
      case CompletionItemKind.property:
        return '.';
      case CompletionItemKind.module:
        return '■';
      case CompletionItemKind.snippet:
        return '✂';
      case CompletionItemKind.constructor:
        return '▣';
      case CompletionItemKind.value:
        return 'v';
      case CompletionItemKind.reference:
        return '@';
    }
  }

  /// Color del icono.
  int get colorHex {
    switch (kind) {
      case CompletionItemKind.keyword:
        return 0xFF569CD6; // Azul
      case CompletionItemKind.method:
      case CompletionItemKind.function:
        return 0xFFDCDCAA; // Amarillo
      case CompletionItemKind.classs:
      case CompletionItemKind.interface:
        return 0xFF4EC9B0; // Verde agua
      case CompletionItemKind.variable:
        return 0xFF9CDCFE; // Azul claro
      case CompletionItemKind.property:
        return 0xFFCE9178; // Naranja
      case CompletionItemKind.module:
        return 0xFFC586C0; // Morado
      case CompletionItemKind.snippet:
        return 0xFF6A9955; // Verde
      case CompletionItemKind.constructor:
        return 0xFF4EC9B0;
      case CompletionItemKind.value:
        return 0xFFCE9178;
      case CompletionItemKind.reference:
        return 0xFFDCDCAA;
    }
  }
}
