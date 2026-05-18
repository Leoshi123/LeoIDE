import '../models/completion_item.dart';

/// Provider de palabras del documento — extrae identificadores
/// del texto para sugerir palabras que el usuario ya escribió.
class DocumentProvider {
  final Set<String> _words = {};
  bool _built = false;

  /// Escanea el texto y extrae palabras significativas (>= 3 chars).
  void build(String text) {
    _words.clear();
    final matches = RegExp(r'\b[a-zA-Z_]\w{2,}\b').allMatches(text);
    for (final m in matches) {
      _words.add(m.group(0)!);
    }
    _built = true;
  }

  /// Retorna palabras del documento como CompletionItems.
  List<CompletionItem> getWords() {
    if (!_built) return [];
    return _words.map((w) {
      return CompletionItem(
        label: w,
        insertText: w,
        kind: CompletionItemKind.reference,
        detail: 'identifier',
      );
    }).toList();
  }
}
