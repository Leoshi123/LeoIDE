import 'models/completion_context.dart';

/// Analiza el texto antes del cursor y determina:
/// - ¿Qué trigger activó el autocompletado? (word, dot, scope, import)
/// - ¿Cuál es el prefijo actual?
/// - ¿En qué scope estamos (clase, función)?
/// - ¿Cuál es el token anterior?
class ContextParser {
  /// Analiza el contexto de completado.
  static CompletionContext parse({
    required String fullText,
    required int cursorOffset,
    required String language,
  }) {
    if (cursorOffset <= 0) {
      return CompletionContext(
        prefix: '',
        trigger: CompletionTrigger.manual,
        language: language,
        textBeforeCursor: '',
        cursorOffset: 0,
      );
    }

    final textBefore = fullText.substring(0, cursorOffset);

    // Detectar trigger
    final trigger = _detectTrigger(textBefore);
    // Extraer prefijo
    final prefix = _extractPrefix(textBefore, trigger);
    // Detectar scope actual
    final scope = _detectScope(fullText, cursorOffset);
    // Token anterior
    final previousToken = _extractPreviousToken(textBefore, prefix);

    return CompletionContext(
      prefix: prefix,
      trigger: trigger,
      language: language,
      textBeforeCursor: textBefore,
      currentScope: scope,
      previousToken: previousToken,
      cursorOffset: cursorOffset,
    );
  }

  /// Detecta qué activó el trigger.
  static CompletionTrigger _detectTrigger(String textBefore) {
    if (textBefore.endsWith('.')) {
      return CompletionTrigger.dot;
    }
    if (textBefore.endsWith('::')) {
      return CompletionTrigger.scope;
    }
    if (_isAfterImport(textBefore)) {
      return CompletionTrigger.import_;
    }

    // Verificar si hay una palabra parcial antes del cursor
    final wordMatch = RegExp(r'(\w+)$').firstMatch(textBefore);
    if (wordMatch != null && wordMatch.group(1)!.isNotEmpty) {
      // Solo trigger si la palabra tiene al menos 1 char
      // y hay espacio antes (o es inicio de línea)
      return CompletionTrigger.word;
    }

    return CompletionTrigger.manual;
  }

  /// Extrae el prefijo (palabra que el usuario está escribiendo).
  static String _extractPrefix(String textBefore, CompletionTrigger trigger) {
    if (trigger == CompletionTrigger.dot ||
        trigger == CompletionTrigger.scope) {
      // Después de . o ::, no hay prefijo
      return '';
    }

    if (trigger == CompletionTrigger.import_) {
      return '';
    }

    final wordMatch = RegExp(r'(\w+)$').firstMatch(textBefore);
    return wordMatch?.group(1) ?? '';
  }

  /// Detecta si estamos después de una palabra de importación.
  static bool _isAfterImport(String textBefore) {
    return RegExp(r'(?:^|\n)(?:import|from|#include|using|require)\s+\w*$',
            multiLine: true)
        .hasMatch(textBefore);
  }

  /// Extrae el token anterior al prefijo.
  static String? _extractPreviousToken(String textBefore, String prefix) {
    if (prefix.isEmpty && textBefore.isNotEmpty) {
      // Caso: "obj." — extraer "obj"
      final before = textBefore.substring(0, textBefore.length - 1);
      if (before.endsWith('.') || before.endsWith(':')) {
        final trimmed = before.substring(0, before.length - 1);
        final match = RegExp(r'(\w+)$').firstMatch(trimmed);
        return match?.group(1);
      }
      final match = RegExp(r'(\w+)$').firstMatch(before);
      return match?.group(1);
    }

    if (prefix.isEmpty) return null;

    // Caso: "palabra" donde palabra es el prefijo
    final beforePrefix = textBefore.substring(
        0, textBefore.length - prefix.length);
    if (beforePrefix.endsWith('.') || beforePrefix.endsWith(':')) {
      // "obj." — extraer "obj"
      final trimmed = beforePrefix.substring(0, beforePrefix.length - 1);
      final match = RegExp(r'(\w+)$').firstMatch(trimmed);
      return match?.group(1);
    }

    // Palabra antes del prefijo
    final trim = beforePrefix.trim();
    if (trim.isEmpty) return null;
    final match = RegExp(r'(\w+)$').firstMatch(beforePrefix);
    return match?.group(1);
  }

  /// Detecta el scope actual (clase/función donde está el cursor).
  static String? _detectScope(String fullText, int cursorOffset) {
    if (fullText.isEmpty || cursorOffset <= 0) return null;

    final beforeCursor = fullText.substring(0, cursorOffset);
    final lines = beforeCursor.split('\n');

    // Buscar hacia atrás la clase o función más cercana
    String? lastClass;
    String? lastFunction;

    for (final line in lines) {
      // Detectar clase
      final classMatch =
          RegExp(r'(?:class|struct|interface|mixin)\s+(\w+)').firstMatch(line);
      if (classMatch != null) {
        lastClass = classMatch.group(1);
        lastFunction = null; // nueva clase resetea función
      }

      // Detectar función
      final funcMatch =
          RegExp(r'(?:def|function|void|int|String|float|double)\s+(\w+)\s*\(')
              .firstMatch(line);
      if (funcMatch != null) {
        lastFunction = funcMatch.group(1);
      }
    }

    return lastFunction ?? lastClass;
  }
}
