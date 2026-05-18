/// Detector de lenguaje de programación basado en contenido.
///
/// Analiza el código fuente y lo puntúa contra patrones propios de
/// cada lenguaje. Útil cuando la extensión del archivo no coincide
/// con el contenido (ej: código Python en sin_titulo.dart).
///
/// Diseño:
///   - Cada lenguaje tiene una lista de patrones con peso
///   - Los patrones se evalúan línea por línea
///   - El lenguaje con mayor puntuación total gana
///   - Confianza = (score del ganador) / (score total de todos)
///   - Se requiere confianza ≥ 0.5 para considerar la detección válida
library;

/// Resultado de la detección de lenguaje.
class DetectedLanguage {
  /// Nombre del lenguaje detectado ('python', 'dart', etc).
  final String language;

  /// Extensión de archivo correspondiente ('.py', '.dart', etc).
  final String extension;

  /// Puntaje bruto del ganador.
  final double score;

  /// Confianza normalizada 0.0–1.0.
  final double confidence;

  /// Patrones específicos que hicieron match.
  final List<String> matchedPatterns;

  const DetectedLanguage({
    required this.language,
    required this.extension,
    required this.score,
    required this.confidence,
    required this.matchedPatterns,
  });

  bool get isValid => confidence >= 0.5 && score >= 2.0;
}

/// Un patrón de detección con su peso.
class _Pattern {
  final RegExp regex;
  final double weight;
  final String description;

  const _Pattern(this.regex, this.weight, this.description);
}

/// Detector de lenguaje de programación por análisis de contenido.
class LanguageDetector {
  // ── Patrones por lenguaje ──

  static final List<_Pattern> _pyPatterns = [
    _Pattern(RegExp(r'^#!\s*/.*python'), 10, 'shebang python'),
    _Pattern(RegExp(r'^\s*def\s+\w+\s*\('), 4, 'def function'),
    _Pattern(RegExp(r'^\s*class\s+\w+\s*:'), 4, 'class: (no braces)'),
    _Pattern(RegExp(r"""^\s*if\s+__name__\s*==\s*["']__main__["']\s*:"""), 8,
        'if __name__'),
    _Pattern(RegExp(r'^\s*elif\s'), 5, 'elif'),
    _Pattern(RegExp(r'^\s*(else|try|finally)\s*:'), 3, 'else/try/finally:'),
    _Pattern(RegExp(r'^\s*except\s'), 4, 'except'),
    _Pattern(RegExp(r'^\s*with\s+\w+\s+as\s'), 4, 'with ... as'),
    _Pattern(RegExp(r'^\s*from\s+\w+\s+import\s'), 3, 'from import'),
    _Pattern(RegExp(r'^\s*import\s+\w+'), 2, 'import'),
    _Pattern(RegExp(r'^\s*@\w+'), 2, 'decorator'),
    _Pattern(RegExp(r'^\s*print\s*\('), 1, 'print('),
    _Pattern(RegExp(r'^\s*yield\s'), 4, 'yield'),
    _Pattern(RegExp(r'^\s*lambda\s'), 3, 'lambda'),
    _Pattern(RegExp(r'^\s*async\s+def\s'), 3, 'async def'),
    _Pattern(RegExp(r'^\s*raise\s'), 3, 'raise'),
    _Pattern(RegExp(r'^\s*assert\s'), 2, 'assert'),
    _Pattern(RegExp(r'^\s*del\s'), 2, 'del'),
    _Pattern(RegExp(r'^\s*pass\s*$'), 1, 'pass'),
  ];

  static final List<_Pattern> _dartPatterns = [
    _Pattern(RegExp(r'^\s*(void\s+)?main\s*\(\s*\)'), 5, 'main()'),
    _Pattern(RegExp(r'''^\s*import\s+['"]dart:'''), 6, "import 'dart:"),
    _Pattern(RegExp(r'''^\s*import\s+['"]package:'''), 4, "import 'package:"),
    _Pattern(RegExp(r'^\s*@override\b'), 3, '@override'),
    _Pattern(RegExp(r'^\s*@deprecated\b'), 3, '@deprecated'),
    _Pattern(RegExp(r'^\s*class\s+\w+\s*\{'), 4, 'class {'),
    _Pattern(RegExp(r'^\s*(final|const)\s+\w'), 2, 'final/const'),
    _Pattern(RegExp(r'^\s*(mixin|enum)\s'), 5, 'mixin/enum'),
    _Pattern(RegExp(r'^\s*factory\s'), 4, 'factory'),
    _Pattern(RegExp(r'^\s*extends\s'), 3, 'extends'),
    _Pattern(RegExp(r'^\s*implements\s'), 3, 'implements'),
    _Pattern(RegExp(r'^\s*with\s+\w+\s*\{'), 3, 'mixin with {'),
    _Pattern(RegExp(r'\{?\s*required\s+this\.'), 3, 'required this.'),
    _Pattern(RegExp(r'^\s*static\s'), 1, 'static'),
    _Pattern(RegExp(r'^\s*typedef\s'), 4, 'typedef'),
    _Pattern(RegExp(r'^\s*late\s'), 2, 'late'),
    _Pattern(RegExp(r"""'[a-z]+(?:_[a-z]+)*'\s*:"""), 1, 'string key in map'),
  ];

  static final List<_Pattern> _cPatterns = [
    _Pattern(RegExp(r'^\s*#\s*include\s+<[a-z]+\.h>'), 4, '#include <.h>'),
    _Pattern(RegExp(r'^\s*#\s*define\s'), 3, '#define'),
    _Pattern(RegExp(r'^\s*int\s+main\s*\('), 5, 'int main('),
    _Pattern(RegExp(r'^\s*printf\s*\('), 4, 'printf('),
    _Pattern(RegExp(r'^\s*scanf\s*\('), 4, 'scanf('),
    _Pattern(RegExp(r'^\s*struct\s+\w+\s*\{'), 4, 'struct {'),
    _Pattern(RegExp(r'^\s*typedef\s'), 3, 'typedef'),
    _Pattern(RegExp(r'^\s*#\s*(ifdef|ifndef|endif|pragma)\b'), 3,
        'preprocessor conditional'),
    _Pattern(RegExp(r'\breturn\s+-?\d+\s*;'), 3, 'return N;'),
    _Pattern(RegExp(r'^\s*(double|float|char|long|short|unsigned)\s+\w'),
        2, 'C type prefix'),
  ];

  static final List<_Pattern> _cppPatterns = [
    _Pattern(RegExp(r'^\s*#\s*include\s+<(iostream|vector|string|map|set|algorithm|fstream|memory|utility|functional|c\w+)>'),
        4, '#include <C++ header>'),
    _Pattern(RegExp(r'\bstd::'), 5, 'std::'),
    _Pattern(RegExp(r'\bcout\b'), 4, 'cout'),
    _Pattern(RegExp(r'\bcin\b'), 4, 'cin'),
    _Pattern(RegExp(r'^\s*template\s*<'), 5, 'template <'),
    _Pattern(RegExp(r'^\s*class\s+\w+\s*\{'), 3, 'class {'),
    _Pattern(RegExp(r'^\s*(public|private|protected)\s*:'), 4,
        'access specifier'),
    _Pattern(RegExp(r'\b(constexpr|noexcept|virtual|override)\b'), 3,
        'C++ keyword'),
    _Pattern(RegExp(r'^\s*namespace\s'), 4, 'namespace'),
    _Pattern(RegExp(r'\bauto\b'), 1, 'auto'),
    _Pattern(RegExp(r'\bnullptr\b'), 3, 'nullptr'),
  ];

  static final List<_Pattern> _jsPatterns = [
    _Pattern(RegExp(r'^\s*(const|let|var)\s+\w+\s*='), 2, 'const/let/var ='),
    _Pattern(RegExp(r'^\s*function\s+\w+\s*\('), 3, 'function name('),
    _Pattern(RegExp(r'\bconsole\.(log|error|warn|debug)\b'), 3, 'console.*'),
    _Pattern(RegExp(r'^\s*require\s*\('), 4, 'require('),
    _Pattern(RegExp(r'^\s*module\.exports\b'), 5, 'module.exports'),
    _Pattern(RegExp(r"""^\s*export\s+(default|const|function|class|let|var)\s"""),
        4, 'export'),
    _Pattern(RegExp(r"""^\s*import\s+.*\s+from\s+['\"]"""), 3, 'import from'),
    _Pattern(RegExp(r'\bundefined\b'), 2, 'undefined'),
    _Pattern(RegExp(r'\b===?\b'), 1, '==='),
    _Pattern(RegExp(r'\.addEventListener\b'), 3, 'addEventListener'),
    _Pattern(RegExp(r'\bdocument\.'), 3, 'document.'),
    _Pattern(RegExp(r'\bwindow\.'), 2, 'window.'),
    _Pattern(RegExp(r'\basync\s+function\b'), 2, 'async function'),
    _Pattern(RegExp(r'^\s*import\s+[\w{]'), 2, 'import {'),
    _Pattern(RegExp(r'`[^`]*\$\{[^}]*\}`'), 3, 'template literal'),
    _Pattern(RegExp(r'^\s*class\s+\w+\s*\{'), 2, 'class {'),
  ];

  static final List<_Pattern> _phpPatterns = [
    _Pattern(RegExp(r'^<\?php'), 10, '<?php'),
    _Pattern(RegExp(r'^<\?='), 8, '<?='),
    _Pattern(RegExp(r'^\s*\$[a-zA-Z_]'), 4, '\$variable'),
    _Pattern(RegExp(r'^\s*echo\s'), 3, 'echo'),
    _Pattern(RegExp(r'^\s*function\s+\w+\s*\('), 2, 'function'),
    _Pattern(RegExp(r'->\s*\w+\s*\('), 2, '->method()'),
    _Pattern(RegExp(r'^\s*namespace\s'), 4, 'namespace'),
    _Pattern(RegExp(r'^\s*use\s+\w+'), 2, 'use'),
    _Pattern(RegExp(r'\b\$_GET\b'), 4, '\$_GET'),
    _Pattern(RegExp(r'\b\$_POST\b'), 4, '\$_POST'),
    _Pattern(RegExp(r'\b\$_SESSION\b'), 4, '\$_SESSION'),
    _Pattern(RegExp(r'^\s*__(construct|destruct|get|set|call|toString)\b'),
        4, '__magic method'),
    _Pattern(RegExp(r'^\s*<\?'), 2, '<? (short)'),
  ];

  static final List<_Pattern> _htmlPatterns = [
    _Pattern(RegExp(r'^<!DOCTYPE\s+html', caseSensitive: false), 8,
        '<!DOCTYPE html>'),
    _Pattern(RegExp(r'^\s*<html[\s>]'), 5, '<html>'),
    _Pattern(RegExp(r'^\s*<head[\s>]'), 3, '<head>'),
    _Pattern(RegExp(r'^\s*<body[\s>]'), 3, '<body>'),
    _Pattern(RegExp(r'^\s*<div[\s>]'), 2, '<div>'),
    _Pattern(RegExp(r'^\s*<p[\s>]'), 1, '<p>'),
    _Pattern(RegExp(r'^\s*<a\s'), 1, '<a'),
    _Pattern(RegExp(r'^\s*<img\s'), 2, '<img'),
    _Pattern(RegExp(r'^\s*<script[\s>]'), 4, '<script>'),
    _Pattern(RegExp(r'^\s*<style[\s>]'), 4, '<style>'),
    _Pattern(RegExp(r'^\s*</(div|p|a|span|ul|li|h[1-6]|section|header|footer|nav|main|article)>'),
        1, 'closing tag'),
    _Pattern(RegExp(r'^\s*<link\s'), 2, '<link>'),
    _Pattern(RegExp(r'^\s*<meta\s'), 2, '<meta>'),
    _Pattern(RegExp(r'^\s*<br\s*/?>'), 1, '<br>'),
    _Pattern(RegExp(r'^\s*<input\s'), 2, '<input>'),
  ];

  static final List<_Pattern> _cssPatterns = [
    _Pattern(RegExp(r'^\s*[.#]?[a-zA-Z][\w-]*\s*\{'), 3, 'selector {'),
    _Pattern(RegExp(r'^\s*@media\s'), 6, '@media'),
    _Pattern(RegExp(r'^\s*@import\s'), 5, '@import'),
    _Pattern(RegExp(r'^\s*@font-face\s'), 6, '@font-face'),
    _Pattern(RegExp(r'^\s*@keyframes\s'), 6, '@keyframes'),
    _Pattern(RegExp(r'^\s*color\s*:\s*'), 2, 'color:'),
    _Pattern(RegExp(r'^\s*(margin|padding)\s*:\s*'), 2, 'margin/padding:'),
    _Pattern(RegExp(r'^\s*(display|position|overflow)\s*:\s*'), 2,
        'display/position:'),
    _Pattern(RegExp(r'^\s*(font-size|font-weight|font-family)\s*:\s*'), 2,
        'font-*:'),
    _Pattern(RegExp(r'^\s*(background|border|flex|grid|gap)\s*:'), 2,
        'layout property:'),
    _Pattern(RegExp(r'^\s*@charset\s'), 5, '@charset'),
    _Pattern(RegExp(r'^\s*@supports\s'), 5, '@supports'),
    _Pattern(RegExp(r'^\s*::?[a-z-]+\s*\{'), 2, 'pseudo selector'),
  ];

  /// Registro completo de lenguajes con nombre, extensión y patrones.
  static final Map<String, _LanguageEntry> _languages = {
    'python': _LanguageEntry('.py', _pyPatterns),
    'dart': _LanguageEntry('.dart', _dartPatterns),
    'c': _LanguageEntry('.c', _cPatterns),
    'cpp': _LanguageEntry('.cpp', _cppPatterns),
    'javascript': _LanguageEntry('.js', _jsPatterns),
    'php': _LanguageEntry('.php', _phpPatterns),
    'html': _LanguageEntry('.html', _htmlPatterns),
    'css': _LanguageEntry('.css', _cssPatterns),
  };

  /// Detecta el lenguaje del código dado.
  ///
  /// [hintExtension] es la extensión actual del archivo (opcional).
  /// Si se provee, suma un pequeño bonus al lenguaje correspondiente,
  /// permitiendo que el detector "confíe" más en la extensión actual
  /// cuando el código es ambiguo.
  static DetectedLanguage detect(String code, {String? hintExtension}) {
    if (code.trim().isEmpty) {
      // Sin código → usar hint si existe, sino dart por defecto
      final ext = hintExtension ?? '.dart';
      final lang = _extToLang(ext);
      return DetectedLanguage(
        language: lang,
        extension: ext,
        score: 0,
        confidence: 0,
        matchedPatterns: [],
      );
    }

    final lines = code.split('\n');
    final scores = <String, double>{};
    final matches = <String, List<String>>{};

    // Inicializar
    for (final lang in _languages.keys) {
      scores[lang] = 0;
      matches[lang] = [];
    }

    // Evaluar cada línea contra todos los patrones
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('//')) continue;

      for (final entry in _languages.entries) {
        final langName = entry.key;
        final langEntry = entry.value;

        for (final pattern in langEntry.patterns) {
          if (pattern.regex.hasMatch(line)) {
            scores[langName] = (scores[langName] ?? 0) + pattern.weight;
            matches[langName]!.add(pattern.description);
          }
        }
      }
    }

    // Bonus por extensión (factor 1.0 = mismo peso que 1 match de peso 1)
    if (hintExtension != null) {
      final hintLang = _extToLang(hintExtension);
      scores[hintLang] = (scores[hintLang] ?? 0) + 1.0;
    }

    // Encontrar ganador
    String bestLang = 'dart';
    double bestScore = 0;
    double totalScore = 0;

    for (final entry in scores.entries) {
      totalScore += entry.value;
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestLang = entry.key;
      }
    }

    final langEntry = _languages[bestLang]!;
    final confidence = totalScore > 0 ? bestScore / totalScore : 0.0;

    return DetectedLanguage(
      language: bestLang,
      extension: langEntry.extension,
      score: bestScore,
      confidence: confidence,
      matchedPatterns: matches[bestLang] ?? [],
    );
  }

  /// Extensión → nombre de lenguaje (misma lógica que en runner).
  static String _extToLang(String ext) {
    switch (ext) {
      case '.py':
        return 'python';
      case '.c':
        return 'c';
      case '.cpp':
      case '.cc':
      case '.cxx':
        return 'cpp';
      case '.js':
      case '.mjs':
        return 'javascript';
      case '.php':
        return 'php';
      case '.html':
      case '.htm':
        return 'html';
      case '.css':
        return 'css';
      case '.dart':
      default:
        return 'dart';
    }
  }
}

/// Entrada de lenguaje en el registro de detección.
class _LanguageEntry {
  final String extension;
  final List<_Pattern> patterns;

  const _LanguageEntry(this.extension, this.patterns);
}
