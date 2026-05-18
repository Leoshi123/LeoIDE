import 'completion_item.dart';

/// Cómo se activó la completación.
enum CompletionTrigger {
  /// El usuario está escribiendo una palabra: `pri`
  word,

  /// Después de un punto: `obj.`
  dot,

  /// Después de dos puntos: `obj::` (C++)
  scope,

  /// Después de `import `, `from `, `#include `
  import_,

  /// No se pudo determinar / trigger manual (Ctrl+Space)
  manual,
}

/// Contexto completo en el que se solicita autocompletado.
class CompletionContext {
  /// El texto que está escribiendo el usuario (prefijo).
  final String prefix;

  /// Cómo se activó.
  final CompletionTrigger trigger;

  /// Lenguaje actual.
  final String language;

  /// Texto completo antes del cursor.
  final String textBeforeCursor;

  /// Scope actual (nombre de la clase/función donde está el cursor).
  final String? currentScope;

  /// Token inmediatamente anterior (palabra justo antes del prefijo).
  final String? previousToken;

  /// Offset global del cursor en el documento.
  final int cursorOffset;

  const CompletionContext({
    required this.prefix,
    required this.trigger,
    required this.language,
    required this.textBeforeCursor,
    this.currentScope,
    this.previousToken,
    this.cursorOffset = 0,
  });
}

/// Resultado del engine de completado.
class CompletionResult {
  final List<CompletionItem> items;
  final CompletionContext context;

  const CompletionResult({
    required this.items,
    required this.context,
  });

  bool get hasItems => items.isNotEmpty;

  /// Los items ordenados por score (mejor primero).
  List<CompletionItem> get sorted {
    final sorted = List<CompletionItem>.from(items);
    sorted.sort((a, b) {
      // Primero por score descendente
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      // Desempate por prioridad de tipo
      final prioCmp = a.priority.compareTo(b.priority);
      if (prioCmp != 0) return prioCmp;
      // Finalmente alfabético
      return a.label.compareTo(b.label);
    });
    return sorted;
  }
}
