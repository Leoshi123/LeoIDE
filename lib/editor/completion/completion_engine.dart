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
/// 5. Usage bonus: items usados frecuentemente suben en ranking
/// 6. Retorna top-N resultados
class CompletionEngine {
  final FuzzyScorer _scorer;
  late KeywordProvider _keywordProvider;
  late SnippetProvider _snippetProvider;
  late SymbolProvider _symbolProvider;
  late DocumentProvider _documentProvider;

  String _language = 'dart';

  // ── Uso reciente ──

  /// Frecuencia de uso por label.
  final Map<String, int> _usageCount = {};

  /// Orden de recencia (más reciente primero, max 10).
  final List<String> _recencyOrder = [];

  CompletionEngine() : _scorer = FuzzyScorer.instance {
    _keywordProvider = KeywordProvider(_language);
    _snippetProvider = SnippetProvider(_language);
    _symbolProvider = SymbolProvider(_language);
    _documentProvider = DocumentProvider();
  }

  /// Registra que un item fue usado/aceptado.
  void recordUsage(String label) {
    _usageCount[label] = (_usageCount[label] ?? 0) + 1;

    // Actualizar recencia
    _recencyOrder.remove(label);
    _recencyOrder.insert(0, label);
    if (_recencyOrder.length > 10) {
      _recencyOrder.removeLast();
    }
  }

  /// Bonus por uso reciente/frecuente (0.0 – 0.15).
  double _usageBonus(String label) {
    double bonus = 0.0;

    // Bonus por frecuencia: +0.02 por uso, max +0.10 (5 usos)
    final count = _usageCount[label] ?? 0;
    bonus += (count.clamp(0, 5)) * 0.02;

    // Bonus por recencia: top 3 → +0.05, top 10 → +0.02
    final index = _recencyOrder.indexOf(label);
    if (index >= 0 && index < 3) {
      bonus += 0.05;
    } else if (index >= 0 && index < 10) {
      bonus += 0.02;
    }

    return bonus.clamp(0.0, 0.15);
  }

  /// Bonus por tipo de elemento (0.0 – 0.08).
  ///
  /// En VS Code, el tipo del item influye en su posición:
  /// snippets > clases > métodos > propiedades > variables > keywords.
  /// Esto replica ese comportamiento como un boost numérico.
  static double _typeBonus(CompletionItemKind kind) {
    switch (kind) {
      case CompletionItemKind.snippet:
        return 0.08;
      case CompletionItemKind.classs:
      case CompletionItemKind.interface:
        return 0.06;
      case CompletionItemKind.method:
      case CompletionItemKind.function:
        return 0.05;
      case CompletionItemKind.constructor:
        return 0.04;
      case CompletionItemKind.property:
        return 0.03;
      case CompletionItemKind.variable:
        return 0.02;
      case CompletionItemKind.keyword:
        return 0.01;
      case CompletionItemKind.module:
      case CompletionItemKind.value:
      case CompletionItemKind.reference:
        return 0.0;
    }
  }

  // ── Fin UsageTracker ──

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
      // Sin prefijo → ordenar por tipo + uso reciente
      candidates.sort((a, b) {
        final aScore = _typeBonus(a.kind) + _usageBonus(a.label);
        final bScore = _typeBonus(b.kind) + _usageBonus(b.label);
        return bScore.compareTo(aScore);
      });
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
        // Boost por uso reciente + tipo de elemento
        final usageBoost = _usageBonus(item.label);
        final typeBoost = _typeBonus(item.kind);
        final adjusted = (score + usageBoost + typeBoost).clamp(0.0, 1.0);
        final ranked = CompletionItem(
          label: item.label,
          insertText: item.insertText,
          kind: item.kind,
          detail: item.detail,
          documentation: item.documentation,
          score: adjusted,
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
