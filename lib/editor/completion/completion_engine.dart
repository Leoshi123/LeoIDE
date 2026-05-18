import 'models/completion_item.dart';
import 'models/completion_context.dart';
import 'fuzzy_scorer.dart';
import 'context_parser.dart';
import 'providers/keyword_provider.dart';
import 'providers/snippet_provider.dart';
import 'providers/symbol_provider.dart';
import 'providers/document_provider.dart';

/// Engine principal de autocompletado.
///
/// 1. Toma el texto completo + posición del cursor
/// 2. ContextParser analiza qué se está escribiendo
/// 3. Providers recolectan candidatos según el contexto
/// 4. FuzzyScorer ordena por relevancia
/// 5. Retorna top-N resultados
class CompletionEngine {
  final FuzzyScorer _scorer;
  late final KeywordProvider _keywordProvider;
  late final SnippetProvider _snippetProvider;
  late final SymbolProvider _symbolProvider;
  late final DocumentProvider _documentProvider;

  String _language = 'dart';

  CompletionEngine() : _scorer = FuzzyScorer.instance {
    _keywordProvider = KeywordProvider(_language);
    _snippetProvider = SnippetProvider(_language);
    _symbolProvider = SymbolProvider(_language);
    _documentProvider = DocumentProvider();
  }

  /// Cambia el lenguaje activo.
  void setLanguage(String language) {
    _language = language;
    _keywordProvider = KeywordProvider(_language);
    _snippetProvider = SnippetProvider(_language);
    _symbolProvider = SymbolProvider(_language);
  }

  /// Reconstruye símbolos y palabras del documento.
  void buildDocument(String text) {
    _symbolProvider.build(text);
    _documentProvider.build(text);
  }

  /// Solicita completaciones en [cursorOffset] del documento [fullText].
  CompletionResult requestCompletions({
    required String fullText,
    required int cursorOffset,
  }) {
    // 1. Analizar contexto
    final context = ContextParser.parse(
      fullText: fullText,
      cursorOffset: cursorOffset,
      language: _language,
    );

    // Si el prefijo es muy largo, limitar
    if (context.prefix.length > 30) {
      return CompletionResult(context: context, items: []);
    }

    // 2. Recolectar candidatos según trigger
    final candidates = <CompletionItem>[];

    switch (context.trigger) {
      case CompletionTrigger.word:
        candidates.addAll(_keywordProvider.getKeywords());
        candidates.addAll(_symbolProvider.getSymbols());
        candidates.addAll(_snippetProvider.getSnippets());
        candidates.addAll(_documentProvider.getWords());
        break;

      case CompletionTrigger.dot:
      case CompletionTrigger.scope:
        // Después de . o :: — solo símbolos y miembros
        candidates.addAll(_symbolProvider.getSymbols());
        break;

      case CompletionTrigger.import_:
        // En imports — solo modules
        candidates.addAll(_symbolProvider.getSymbols());
        break;

      case CompletionTrigger.manual:
        candidates.addAll(_keywordProvider.getKeywords());
        candidates.addAll(_symbolProvider.getSymbols());
        candidates.addAll(_snippetProvider.getSnippets());
        break;
    }

    // 3. Filtrar y ordenar por fuzzy score
    final prefix = context.prefix;

    if (prefix.isEmpty) {
      // Sin prefijo → ordenar por prioridad de tipo
      candidates.sort((a, b) => a.priority.compareTo(b.priority));
      return CompletionResult(
        context: context,
        items: candidates.take(15).toList(),
      );
    }

    // Con prefijo → fuzzy scoring
    final scored = <double, List<CompletionItem>>{};

    for (final item in candidates) {
      final score = _scorer.score(prefix, item.label);
      if (score > 0.0) {
        // Boost extra para snippets (siempre útiles)
        final adjusted = item.kind == CompletionItemKind.snippet
            ? score + 0.1
            : score;
        final ranked = CompletionItem(
          label: item.label,
          insertText: item.insertText,
          kind: item.kind,
          detail: item.detail,
          documentation: item.documentation,
          score: adjusted.clamp(0.0, 1.0),
        );
        scored.putIfAbsent(adjusted, () => []).add(ranked);
      }
    }

    // Ordenar por score descendente
    final keys = scored.keys.toList()..sort((a, b) => b.compareTo(a));
    final sorted = <CompletionItem>[];
    for (final key in keys) {
      final items = scored[key]!;
      items.sort((a, b) => a.priority.compareTo(b.priority));
      sorted.addAll(items);
    }

    return CompletionResult(
      context: context,
      items: sorted.take(15).toList(),
    );
  }
}
