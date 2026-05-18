import 'dart:collection';

/// Tabla de símbolos para autocompletado.
///
/// Analiza el texto del documento y construye un mapa de:
/// - Palabras clave del lenguaje
/// - Nombres de funciones definidas por el usuario
/// - Nombres de variables
/// - Símbolos importados/incluidos
class SymTable {
  final String _language;

  /// Mapa: nombre del símbolo → tipo/descripción
  final LinkedHashMap<String, SymEntry> _symbols = LinkedHashMap();

  SymTable(this._language);

  /// Palabras clave por lenguaje
  static const Map<String, List<String>> keywords = {
    'dart': [
      'import', 'class', 'void', 'int', 'String', 'bool', 'double',
      'final', 'const', 'var', 'if', 'else', 'for', 'while', 'do',
      'switch', 'case', 'break', 'continue', 'return', 'true', 'false',
      'null', 'this', 'super', 'new', 'abstract', 'extends', 'implements',
      'mixin', 'enum', 'typedef', 'static', 'late', 'required', 'async',
      'await', 'try', 'catch', 'finally', 'throw', 'rethrow', 'in', 'is',
      'as', 'print', 'assert', 'override', 'factory', 'get', 'set',
    ],
    'python': [
      'import', 'from', 'class', 'def', 'return', 'if', 'elif', 'else',
      'for', 'while', 'break', 'continue', 'try', 'except', 'finally',
      'raise', 'with', 'as', 'pass', 'None', 'True', 'False', 'and',
      'or', 'not', 'in', 'is', 'lambda', 'yield', 'global', 'nonlocal',
      'async', 'await', 'print', 'range', 'len', 'type', 'int', 'str',
      'list', 'dict', 'set', 'tuple', 'float', 'bool', 'self', 'cls',
    ],
    'cpp': [
      '#include', 'int', 'float', 'double', 'char', 'bool', 'void',
      'auto', 'const', 'static', 'class', 'struct', 'enum', 'union',
      'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break',
      'continue', 'return', 'new', 'delete', 'this', 'virtual',
      'override', 'public', 'private', 'protected', 'namespace',
      'using', 'template', 'typename', 'typedef', 'sizeof', 'true',
      'false', 'nullptr', 'std', 'cout', 'cin', 'endl', 'string',
      'vector', 'map', 'list', 'set', 'pair', 'printf', 'scanf',
    ],
    'c': [
      '#include', 'int', 'float', 'double', 'char', 'void', 'short',
      'long', 'unsigned', 'signed', 'const', 'static', 'struct', 'enum',
      'union', 'typedef', 'if', 'else', 'for', 'while', 'do', 'switch',
      'case', 'break', 'continue', 'return', 'sizeof', 'true', 'false',
      'NULL', 'printf', 'scanf', 'malloc', 'calloc', 'free', 'FILE',
    ],
    'php': [
      '<?php', 'echo', 'print', 'function', 'class', 'return', 'if',
      'else', 'elseif', 'for', 'foreach', 'while', 'do', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
      'new', 'this', 'self', 'parent', 'public', 'private', 'protected',
      'static', 'const', 'var', 'true', 'false', 'null', 'array',
      'isset', 'empty', 'count', 'strlen', 'implode', 'explode',
      'require', 'include', 'namespace', 'use', 'as', 'interface',
      'implements', 'abstract', 'final', 'trait', 'readonly', 'match',
    ],
    'html': [
      '<html>', '<head>', '<body>', '<div>', '<span>', '<p>', '<a>',
      '<img>', '<ul>', '<ol>', '<li>', '<table>', '<tr>', '<td>',
      '<th>', '<form>', '<input>', '<button>', '<select>', '<option>',
      '<textarea>', '<h1>', '<h2>', '<h3>', '<h4>', '<h5>', '<h6>',
      '<br>', '<hr>', '<meta>', '<link>', '<script>', '<style>',
      '<section>', '<article>', '<header>', '<footer>', '<nav>',
      '<main>', '<aside>', '<figure>', '<figcaption>',
    ],
    'css': [
      'margin', 'padding', 'color', 'background', 'font-size',
      'font-family', 'font-weight', 'text-align', 'display', 'position',
      'top', 'left', 'right', 'bottom', 'width', 'height', 'max-width',
      'min-width', 'max-height', 'min-height', 'border', 'border-radius',
      'box-shadow', 'flex', 'grid', 'gap', 'align-items', 'justify-content',
      'overflow', 'z-index', 'opacity', 'transform', 'transition',
      'animation', 'cursor', 'list-style', 'text-decoration', 'float',
      'clear', 'visibility', 'outline', 'box-sizing', '@media', '@keyframes',
      '@import', '!important',
    ],
    'javascript': [
      'function', 'const', 'let', 'var', 'if', 'else', 'for', 'while',
      'do', 'switch', 'case', 'break', 'continue', 'return', 'try',
      'catch', 'finally', 'throw', 'new', 'this', 'class', 'extends',
      'import', 'export', 'default', 'from', 'async', 'await', 'yield',
      'typeof', 'instanceof', 'true', 'false', 'null', 'undefined', 'NaN',
      'console', 'log', 'document', 'window', 'Array', 'Object', 'String',
      'Number', 'Boolean', 'Map', 'Set', 'Promise', 'JSON', 'Math',
      'require', 'module', 'exports', 'process', 'setTimeout', 'setInterval',
      'addEventListener', 'querySelector', 'createElement', 'appendChild',
      'map', 'filter', 'reduce', 'forEach', 'find', 'includes', 'push',
    ],
  };

  /// Construye la tabla de símbolos desde el texto del documento.
  void build(String text) {
    _symbols.clear();

    // 1. Agregar palabras clave del lenguaje
    final langKeywords = keywords[_language] ?? keywords['dart']!;
    for (final kw in langKeywords) {
      _symbols[kw] = SymEntry(kw, SymType.keyword, 'keyword');
    }

    // 2. Escanear el texto en busca de definiciones de usuario
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      _scanLine(line, i);
    }

    // 3. Extraer palabras del texto para sugerencias contextuales
    final words = RegExp(r'\b[a-zA-Z_]\w{2,}\b').allMatches(text);
    for (final match in words) {
      final word = match.group(0)!;
      if (!_symbols.containsKey(word)) {
        _symbols[word] = SymEntry(word, SymType.variable, 'identifier');
      }
    }
  }

  void _scanLine(String line, int lineNum) {
    // Detectar funciones: (def | function | void | int | String) nombre(
    final funcMatch = RegExp(
      r'(?:def|function|void|int|String|float|double|bool|auto|let|const|var|fun)\s+(\w+)\s*\(',
    ).firstMatch(line);
    if (funcMatch != null) {
      _symbols[funcMatch.group(1)!] = SymEntry(
        funcMatch.group(1)!,
        SymType.function,
        'function',
        line: lineNum,
      );
    }

    // Detectar clases: (class | struct | interface) Nombre
    final classMatch = RegExp(
      r'(?:class|struct|interface|mixin|trait)\s+(\w+)',
    ).firstMatch(line);
    if (classMatch != null) {
      _symbols[classMatch.group(1)!] = SymEntry(
        classMatch.group(1)!,
        SymType.className,
        'class',
        line: lineNum,
      );
    }

    // Detectar variables: (int|String|var|let|const) nombre = / :
    final varMatch = RegExp(
      r'(?:int|String|float|double|bool|var|let|const|val)\s+(\w+)\s*(?:=|:)',
    ).firstMatch(line);
    if (varMatch != null) {
      _symbols[varMatch.group(1)!] = SymEntry(
        varMatch.group(1)!,
        SymType.variable,
        'variable',
        line: lineNum,
      );
    }

    // Detectar imports: (import|include|using) nombre
    final importMatch = RegExp(
      r'''(?:import|#include|using|require|from)\s+['"<]?(\w+)''',
    ).firstMatch(line);
    if (importMatch != null) {
      _symbols[importMatch.group(1)!] = SymEntry(
        importMatch.group(1)!,
        SymType.module,
        'module',
        line: lineNum,
      );
    }
  }

  /// Busca sugerencias para un prefijo dado.
  List<SymEntry> query(String prefix) {
    if (prefix.length < 2) return [];

    final lower = prefix.toLowerCase();
    final results = <SymEntry>[];

    for (final entry in _symbols.values) {
      if (entry.name.toLowerCase().startsWith(lower)) {
        results.add(entry);
      }
    }

    // Ordenar: primero funciones, luego keywords, luego variables
    results.sort((a, b) {
      final typeOrder = {
        SymType.function: 0,
        SymType.keyword: 1,
        SymType.className: 2,
        SymType.module: 3,
        SymType.variable: 4,
      };
      final cmp = typeOrder[a.type]!.compareTo(typeOrder[b.type]!);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return results.take(10).toList(); // Máximo 10 sugerencias
  }

  void setLanguage(String lang) => _language; // No-op, language set in constructor
}

/// Entrada en la tabla de símbolos.
class SymEntry {
  final String name;
  final SymType type;
  final String description;
  final int? line;

  const SymEntry(this.name, this.type, this.description, {this.line});

  /// Icono representativo para la UI.
  String get icon {
    switch (type) {
      case SymType.function:
        return 'ƒ';
      case SymType.className:
        return 'C';
      case SymType.keyword:
        return 'K';
      case SymType.variable:
        return 'x';
      case SymType.module:
        return '■';
    }
  }
}

enum SymType { keyword, function, className, variable, module }
