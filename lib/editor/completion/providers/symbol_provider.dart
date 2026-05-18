import 'dart:collection';

import '../models/completion_item.dart';

/// Provider de símbolos — extrae del documento actual:
/// - Funciones/métodos definidos
/// - Clases/interfaces
/// - Variables declaradas
/// - Imports/modules
class SymbolProvider {
  final String language;
  final _symbols = LinkedHashMap<String, CompletionItem>();

  SymbolProvider(this.language);

  /// Analiza el [text] completo y extrae símbolos.
  void build(String text) {
    _symbols.clear();
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      _scanLine(lines[i], i);
    }
  }

  void _scanLine(String line, int lineNum) {
    // Funciones: def nombre( | function nombre( | void nombre( | int nombre( etc
    final funcMatch =
        RegExp(r'(?:def|function|void|int|String|float|double|bool|auto|let|const|var|fun)\s+(\w+)\s*\(')
            .firstMatch(line);
    if (funcMatch != null) {
      final name = funcMatch.group(1)!;
      _symbols[name] = CompletionItem(
        label: name,
        insertText: '$name()',
        kind: CompletionItemKind.function,
        detail: 'function',
      );
    }

    // Clases: class Nombre | struct Nombre | interface Nombre
    final classMatch =
        RegExp(r'(?:class|struct|interface|mixin|trait)\s+(\w+)').firstMatch(line);
    if (classMatch != null) {
      final name = classMatch.group(1)!;
      _symbols[name] = CompletionItem(
        label: name,
        insertText: name,
        kind: CompletionItemKind.classs,
        detail: 'class',
      );
    }

    // Variables: tipo nombre = | tipo nombre :
    final varMatch =
        RegExp(r'(?:int|String|float|double|bool|var|let|const|val)\s+(\w+)\s*(?:=|:)')
            .firstMatch(line);
    if (varMatch != null) {
      final name = varMatch.group(1)!;
      _symbols[name] = CompletionItem(
        label: name,
        insertText: name,
        kind: CompletionItemKind.variable,
        detail: 'variable',
      );
    }

    // Imports
    final importMatch =
        RegExp(r'''(?:import|#include|using|require|from)\s+['"<]?(\w+)''')
            .firstMatch(line);
    if (importMatch != null) {
      final name = importMatch.group(1)!;
      _symbols[name] = CompletionItem(
        label: name,
        insertText: name,
        kind: CompletionItemKind.module,
        detail: 'module',
      );
    }
  }

  /// Retorna todos los símbolos extraídos.
  List<CompletionItem> getSymbols() => _symbols.values.toList();
}
