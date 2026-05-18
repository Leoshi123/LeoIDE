/// Scorer fuzzy adaptado de Needleman-Wunsch (como clangd).
///
/// Evalúa qué tan bien el patrón (query) coincide con un candidato.
/// No solo dice "sí/no" — asigna un score del 0.0 al 1.0.
///
/// Reglas:
/// +1.0 por carácter consecutivo matching
/// +0.3 por match en word boundary (camelCase, snake_case)
/// +0.2 por match al inicio del candidato
/// -0.2 por cada salto entre caracteres matching
///
/// Ejemplo: query "uptr" contra:
///   "unique_ptr"   → 0.91 ✅
///   "upper_bound"  → 0.72
///   "uintptr_t"    → 0.85
///   "apple"        → 0.00 ❌
class FuzzyScorer {
  /// Scorer singleton.
  static const FuzzyScorer instance = FuzzyScorer._();

  const FuzzyScorer._();

  /// Calcula el score de [query] contra [candidate].
  /// Retorna 0.0 si no hay match.
  double score(String query, String candidate) {
    if (query.isEmpty) return 0.0;
    if (candidate.isEmpty) return 0.0;

    final queryLower = query.toLowerCase();
    final candidateLower = candidate.toLowerCase();

    // Match exacto → score perfecto
    if (candidateLower == queryLower) return 1.0;

    // Prefix match → score alto
    if (candidateLower.startsWith(queryLower)) {
      return 0.95 - (candidate.length - query.length) * 0.005;
    }

    // Fuzzy match: recorrer el query contra el candidate
    return _fuzzyScore(queryLower, candidateLower, candidate);
  }

  double _fuzzyScore(String query, String candidateLower, String candidate) {
    int qi = 0; // índice en query
    double score = 0.0;
    int? lastMatchIndex;
    int gaps = 0;
    bool firstCharMatched = false;

    for (int ci = 0; ci < candidateLower.length && qi < query.length; ci++) {
      if (candidateLower[ci] == query[qi]) {
        // Bonus por carácter consecutivo
        if (lastMatchIndex != null && ci == lastMatchIndex + 1) {
          score += 1.0;
        } else {
          // Hay un gap
          if (lastMatchIndex != null) {
            gaps++;
            score += 0.6; // match no consecutivo, menos peso
          } else {
            score += 1.0;
          }
        }

        // Bonus por match al inicio del candidato
        if (ci == 0) {
          score += 0.3;
          firstCharMatched = true;
        }

        // Bonus por word boundary (camelCase o snake_case)
        if (ci > 0 && _isWordBoundary(candidate[ci], candidate[ci - 1])) {
          score += 0.3;
        }

        // Bonus extra si el primer char del query matchea al inicio
        if (qi == 0 && ci == 0) {
          score += 0.2;
        }

        lastMatchIndex = ci;
        qi++;
      }
    }

    // No todos los caracteres del query matchearon
    if (qi < query.length) return 0.0;

    // Penalty por gaps
    score -= gaps * 0.2;

    // Penalty si el primer carácter no matcheó al inicio
    if (!firstCharMatched) {
      score -= 0.3;
    }

    // Normalizar: dividir por longitud del query para tener score 0.0-~1.5
    score = score / query.length;

    // Clamp a 0.0-1.0
    return score.clamp(0.0, 1.0);
  }

  /// Detecta si hay un word boundary entre [current] y [previous].
  bool _isWordBoundary(String current, String previous) {
    // snake_case: _ → letra
    if (previous == '_' || previous == '-') return true;
    // camelCase: minúscula → MAYÚSCULA
    if (_isLower(previous) && _isUpper(current)) return true;
    // kebab-case: - → letra
    return false;
  }

  bool _isUpper(String ch) => ch.toUpperCase() == ch && ch.toLowerCase() != ch;
  bool _isLower(String ch) => ch.toLowerCase() == ch && ch.toUpperCase() != ch;
}
