import '../models/completion_item.dart';

/// Provider de palabras clave del lenguaje.
class KeywordProvider {
  /// Keywords por lenguaje. Misma base que SymTable pero más completo.
  static const Map<String, List<String>> _keywords = {
    'dart': [
      'import', 'class', 'void', 'int', 'String', 'bool', 'double',
      'final', 'const', 'var', 'if', 'else', 'for', 'while', 'do',
      'switch', 'case', 'break', 'continue', 'return', 'true', 'false',
      'null', 'this', 'super', 'new', 'abstract', 'extends', 'implements',
      'mixin', 'enum', 'typedef', 'static', 'late', 'required', 'async',
      'await', 'try', 'catch', 'finally', 'throw', 'rethrow', 'in', 'is',
      'as', 'assert', 'override', 'factory', 'get', 'set', 'library',
      'export', 'part', 'show', 'hide', 'dynamic', 'covariant', 'deferred',
      'function', 'record', 'sealed', 'base', 'interface',
    ],
    'python': [
      'import', 'from', 'class', 'def', 'return', 'if', 'elif', 'else',
      'for', 'while', 'break', 'continue', 'try', 'except', 'finally',
      'raise', 'with', 'as', 'pass', 'None', 'True', 'False', 'and',
      'or', 'not', 'in', 'is', 'lambda', 'yield', 'global', 'nonlocal',
      'async', 'await', 'range', 'len', 'type', 'int', 'str',
      'list', 'dict', 'set', 'tuple', 'float', 'bool', 'self', 'cls',
      'super', 'del', 'elif', 'except', 'finally', 'match', 'case',
      'print', 'input', 'open', 'sorted', 'enumerate', 'zip', 'map',
      'filter', 'reversed', 'any', 'all', 'sum', 'min', 'max', 'abs',
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
      'constexpr', 'noexcept', 'nullptr', 'const_cast', 'static_cast',
      'dynamic_cast', 'reinterpret_cast', 'try', 'catch', 'throw',
      'friend', 'explicit', 'mutable', 'register', 'volatile',
      'long', 'short', 'unsigned', 'signed', 'size_t',
    ],
    'c': [
      '#include', 'int', 'float', 'double', 'char', 'void', 'short',
      'long', 'unsigned', 'signed', 'const', 'static', 'struct', 'enum',
      'union', 'typedef', 'if', 'else', 'for', 'while', 'do', 'switch',
      'case', 'break', 'continue', 'return', 'sizeof', 'true', 'false',
      'NULL', 'printf', 'scanf', 'malloc', 'calloc', 'realloc', 'free',
      'FILE', 'fopen', 'fclose', 'fprintf', 'fscanf', 'fgets', 'fputs',
      'fread', 'fwrite', 'size_t', 'exit', 'atexit', 'volatile',
      'register', 'extern', 'goto',
    ],
    'php': [
      'echo', 'print', 'function', 'class', 'return', 'if',
      'else', 'elseif', 'for', 'foreach', 'while', 'do', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
      'new', 'this', 'self', 'parent', 'public', 'private', 'protected',
      'static', 'const', 'var', 'true', 'false', 'null', 'array',
      'isset', 'empty', 'count', 'strlen', 'str_replace', 'substr',
      'implode', 'explode', 'require', 'include', 'require_once',
      'include_once', 'namespace', 'use', 'as', 'interface',
      'implements', 'abstract', 'final', 'trait', 'readonly', 'match',
      'enum', 'mixed', 'never', 'void', 'int', 'float', 'string',
      'bool', 'array', 'object', 'iterable', 'callable', 'die', 'var_dump',
    ],
    'javascript': [
      'function', 'const', 'let', 'var', 'if', 'else', 'for', 'while',
      'do', 'switch', 'case', 'break', 'continue', 'return', 'try',
      'catch', 'finally', 'throw', 'new', 'this', 'class', 'extends',
      'import', 'export', 'default', 'from', 'async', 'await', 'yield',
      'typeof', 'instanceof', 'true', 'false', 'null', 'undefined', 'NaN',
      'console', 'log', 'warn', 'error', 'document', 'window',
      'Array', 'Object', 'String', 'Number', 'Boolean', 'Map', 'Set',
      'Promise', 'JSON', 'Math', 'parseInt', 'parseFloat',
      'require', 'module', 'exports', 'process', 'setTimeout',
      'setInterval', 'addEventListener', 'querySelector',
      'querySelectorAll', 'createElement', 'appendChild',
      'map', 'filter', 'reduce', 'forEach', 'find', 'includes', 'push',
      'pop', 'shift', 'unshift', 'slice', 'splice', 'join', 'split',
      'charAt', 'charCodeAt', 'toUpperCase', 'toLowerCase', 'trim',
      'hasOwnProperty', 'isArray', 'keys', 'values', 'entries',
    ],
  };

  final String language;

  KeywordProvider(this.language);

  /// Retorna todos los keywords como CompletionItems.
  List<CompletionItem> getKeywords() {
    final keys = _keywords[language] ?? _keywords['dart']!;
    return keys.map((k) {
      return CompletionItem(
        label: k,
        insertText: k,
        kind: CompletionItemKind.keyword,
        detail: 'keyword',
      );
    }).toList();
  }
}
