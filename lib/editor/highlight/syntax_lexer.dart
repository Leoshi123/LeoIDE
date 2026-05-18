import 'syntax_token.dart';

/// Configuración de tokenización para un lenguaje.
class LanguageConfig {
  final List<String> keywords;
  final List<String> types;
  final List<String> preprocessors;
  final List<String> lineComments; // ["//"], ["#"], ["--"]
  final List<String> blockCommentStart; // ["/*"], ["<!--"]
  final List<String> blockCommentEnd; // ["*/"], ["-->"]
  final List<String> stringChars; // ['"', "'", "`"]
  final bool hasTripleStrings; // Python/Dart: """ y '''
  final List<String> annotationChars; // ["@"]
  final bool isHtml; // HTML/XML special mode
  final List<String> htmlTags;
  final List<String> htmlAttributes;

  const LanguageConfig({
    required this.keywords,
    this.types = const [],
    this.preprocessors = const [],
    this.lineComments = const ['//'],
    this.blockCommentStart = const ['/*'],
    this.blockCommentEnd = const ['*/'],
    this.stringChars = const ['"', "'"],
    this.hasTripleStrings = false,
    this.annotationChars = const ['@'],
    this.isHtml = false,
    this.htmlTags = const [],
    this.htmlAttributes = const [],
  });

  /// Lenguajes predefinidos.
  static const dart = LanguageConfig(
    keywords: [
      'import', 'class', 'void', 'int', 'String', 'bool', 'double',
      'final', 'const', 'var', 'if', 'else', 'for', 'while', 'do',
      'switch', 'case', 'break', 'continue', 'return', 'true', 'false',
      'null', 'this', 'super', 'new', 'abstract', 'extends', 'implements',
      'mixin', 'enum', 'typedef', 'static', 'late', 'required', 'async',
      'await', 'try', 'catch', 'finally', 'throw', 'rethrow', 'in', 'is',
      'as', 'assert', 'override', 'factory', 'get', 'set', 'library',
      'export', 'part', 'show', 'hide', 'dynamic', 'covariant', 'sealed',
      'base', 'interface', 'with', 'on',
    ],
    types: ['int', 'String', 'bool', 'double', 'void', 'dynamic', 'num', 'Never', 'Null', 'Object'],
    preprocessors: ['import', 'export', 'part', 'library'],
    lineComments: ['//'],
    blockCommentStart: ['/*'],
    blockCommentEnd: ['*/'],
    stringChars: ['"', "'"],
    hasTripleStrings: true,
    annotationChars: ['@'],
  );

  static const python = LanguageConfig(
    keywords: [
      'import', 'from', 'class', 'def', 'return', 'if', 'elif', 'else',
      'for', 'while', 'break', 'continue', 'try', 'except', 'finally',
      'raise', 'with', 'as', 'pass', 'and', 'or', 'not', 'in', 'is',
      'lambda', 'yield', 'global', 'nonlocal', 'async', 'await', 'del',
      'assert', 'match', 'case',
    ],
    types: ['int', 'str', 'float', 'bool', 'list', 'dict', 'set', 'tuple', 'None', 'True', 'False', 'type', 'object'],
    preprocessors: ['import', 'from', 'def', 'class'],
    lineComments: ['#'],
    stringChars: ['"', "'"],
    hasTripleStrings: true,
    annotationChars: ['@'],
  );

  static const cpp = LanguageConfig(
    keywords: [
      'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break',
      'continue', 'return', 'new', 'delete', 'this', 'virtual',
      'override', 'public', 'private', 'protected', 'namespace',
      'using', 'template', 'typename', 'typedef', 'sizeof',
      'constexpr', 'noexcept', 'nullptr', 'const_cast', 'static_cast',
      'dynamic_cast', 'reinterpret_cast', 'try', 'catch', 'throw',
      'friend', 'explicit', 'mutable', 'register', 'volatile',
      'true', 'false', 'class', 'struct', 'enum', 'union', 'const',
      'static', 'auto',
    ],
    types: ['int', 'float', 'double', 'char', 'bool', 'void', 'long', 'short', 'unsigned', 'signed', 'size_t', 'string', 'vector', 'map', 'list', 'set', 'pair', 'ostream', 'istream'],
    preprocessors: ['#include', '#define', '#ifdef', '#ifndef', '#endif', '#pragma', '#error'],
    lineComments: ['//'],
    blockCommentStart: ['/*'],
    blockCommentEnd: ['*/'],
    stringChars: ['"', "'"],
    hasTripleStrings: false,
  );

  static const c = LanguageConfig(
    keywords: [
      'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break',
      'continue', 'return', 'sizeof', 'true', 'false', 'NULL',
      'struct', 'enum', 'union', 'typedef', 'const', 'static', 'volatile',
      'register', 'extern', 'goto',
    ],
    types: ['int', 'float', 'double', 'char', 'void', 'long', 'short', 'unsigned', 'signed', 'size_t', 'FILE'],
    preprocessors: ['#include', '#define', '#ifdef', '#ifndef', '#endif', '#pragma', '#error'],
    lineComments: ['//'],
    blockCommentStart: ['/*'],
    blockCommentEnd: ['*/'],
    stringChars: ['"', "'"],
    hasTripleStrings: false,
  );

  static const javascript = LanguageConfig(
    keywords: [
      'function', 'const', 'let', 'var', 'if', 'else', 'for', 'while',
      'do', 'switch', 'case', 'break', 'continue', 'return', 'try',
      'catch', 'finally', 'throw', 'new', 'this', 'class', 'extends',
      'import', 'export', 'default', 'from', 'async', 'await', 'yield',
      'typeof', 'instanceof', 'true', 'false', 'null', 'undefined',
      'in', 'of', 'delete', 'void',
    ],
    types: ['Number', 'String', 'Boolean', 'Array', 'Object', 'Function', 'Map', 'Set', 'Promise', 'Symbol', 'Error', 'RegExp', 'Date'],
    preprocessors: ['import', 'export', 'require', 'from'],
    lineComments: ['//'],
    blockCommentStart: ['/*'],
    blockCommentEnd: ['*/'],
    stringChars: ['"', "'", '`'],
    hasTripleStrings: false,
  );

  static const php = LanguageConfig(
    keywords: [
      'echo', 'print', 'function', 'class', 'return', 'if',
      'else', 'elseif', 'for', 'foreach', 'while', 'do', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
      'new', 'this', 'self', 'parent', 'public', 'private', 'protected',
      'static', 'const', 'var', 'true', 'false', 'null',
      'isset', 'empty', 'require', 'include', 'namespace', 'use', 'as',
      'interface', 'implements', 'abstract', 'final', 'trait', 'match',
      'enum', 'die', 'exit', 'list', 'array', 'global', 'echo',
    ],
    types: ['int', 'float', 'string', 'bool', 'array', 'object', 'mixed', 'void', 'never', 'iterable', 'callable', 'self', 'parent', 'static'],
    preprocessors: ['require', 'include', 'require_once', 'include_once', 'namespace', 'use'],
    lineComments: ['//', '#'],
    blockCommentStart: ['/*'],
    blockCommentEnd: ['*/'],
    stringChars: ['"', "'"],
    hasTripleStrings: false,
  );

  static const html = LanguageConfig(
    keywords: [],
    types: [],
    preprocessors: [],
    lineComments: [],
    blockCommentStart: ['<!--'],
    blockCommentEnd: ['-->'],
    stringChars: ['"', "'"],
    hasTripleStrings: false,
    annotationChars: [],
    isHtml: true,
    htmlTags: [
      'html', 'head', 'body', 'div', 'span', 'p', 'a', 'img', 'ul', 'ol',
      'li', 'table', 'tr', 'td', 'th', 'form', 'input', 'button', 'select',
      'option', 'textarea', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'br', 'hr',
      'meta', 'link', 'script', 'style', 'section', 'article', 'header',
      'footer', 'nav', 'main', 'aside', 'figure', 'figcaption', 'label',
      'fieldset', 'legend', 'datalist', 'output', 'progress', 'meter',
      'details', 'summary', 'dialog', 'template', 'canvas', 'svg',
      'iframe', 'video', 'audio', 'source', 'track', 'picture', 'pre',
      'code', 'em', 'strong', 'i', 'b', 'u', 'small', 'sub', 'sup',
    ],
    htmlAttributes: [
      'class', 'id', 'style', 'src', 'href', 'alt', 'title', 'type',
      'name', 'value', 'placeholder', 'disabled', 'readonly', 'required',
      'checked', 'selected', 'autofocus', 'autocomplete', 'action',
      'method', 'enctype', 'target', 'rel', 'media', 'lang', 'dir',
      'width', 'height', 'data-', 'aria-', 'role',
    ],
  );

  static const css = LanguageConfig(
    keywords: [
      'auto', 'inherit', 'initial', 'unset', 'none', 'hidden', 'visible',
      'scroll', 'solid', 'dashed', 'dotted', 'double', 'groove', 'ridge',
      'inset', 'outset', 'relative', 'absolute', 'fixed', 'sticky',
      'flex', 'grid', 'inline', 'block', 'inline-block', 'table',
      'center', 'left', 'right', 'top', 'bottom', 'middle', 'baseline',
      'repeat', 'no-repeat', 'cover', 'contain', 'auto', 'hidden',
      'ellipsis', 'clip', 'nowrap', 'wrap', 'column', 'row', 'wrap-reverse',
      'space-between', 'space-around', 'space-evenly', 'start', 'end',
      'stretch', 'baseline', 'serif', 'sans-serif', 'monospace',
      'cursive', 'fantasy',
    ],
    types: [],
    preprocessors: [],
    lineComments: [],
    blockCommentStart: ['/*'],
    blockCommentEnd: ['*/'],
    stringChars: ['"', "'"],
    hasTripleStrings: false,
    annotationChars: [],
  );

  /// Mapa de nombre de lenguaje → config.
  static const Map<String, LanguageConfig> all = {
    'dart': dart,
    'python': python,
    'cpp': cpp,
    'c': c,
    'javascript': javascript,
    'php': php,
    'html': html,
    'css': css,
  };
}

/// Lexer FSM que tokeniza código fuente.
class SyntaxLexer {
  final LanguageConfig config;
  final String text;

  SyntaxLexer(this.config, this.text);

  /// Tokeniza el texto completo.
  List<SyntaxToken> tokenize() {
    final tokens = <SyntaxToken>[];
    int i = 0;

    while (i < text.length) {
      // Probar block comments
      for (int b = 0; b < config.blockCommentStart.length; b++) {
        if (_matchAt(i, config.blockCommentStart[b])) {
          final start = i;
          i += config.blockCommentStart[b].length;
          while (i < text.length &&
              !_matchAt(i, config.blockCommentEnd[b])) {
            i++;
          }
          if (i < text.length) {
            i += config.blockCommentEnd[b].length;
          }
          tokens.add(SyntaxToken(
              type: TokenType.comment, start: start, end: i));
          continue;
        }
      }

      if (i >= text.length) break;

      // Probar line comments
      bool matched = false;
      for (final lc in config.lineComments) {
        if (_matchAt(i, lc)) {
          final start = i;
          while (i < text.length && text[i] != '\n') {
            i++;
          }
          tokens.add(SyntaxToken(
              type: TokenType.comment, start: start, end: i));
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // HTML mode: detectar tags
      if (config.isHtml) {
        if (text[i] == '<') {
          if (i + 1 < text.length && text[i + 1] == '/') {
            // Closing tag </tagname>
            final start = i;
            while (i < text.length && text[i] != '>') i++;
            if (i < text.length) i++;
            tokens.add(SyntaxToken(
                type: TokenType.tag, start: start, end: i));
            continue;
          }
          // Opening tag <tagname ...>
          final start = i;
          i++; // skip <
          // Tag name
          final tagStart = i;
          while (i < text.length &&
              _isIdentChar(text[i]) && text[i] != '>') {
            i++;
          }
          final tagName = text.substring(tagStart, i);
          tokens.add(SyntaxToken(
              type: config.htmlTags.contains(tagName)
                  ? TokenType.tag
                  : TokenType.identifier,
              start: start,
              end: i));
          // Attributes
          while (i < text.length && text[i] != '>') {
            if (text[i] == '/' && i + 1 < text.length &&
                text[i + 1] == '>') {
              i += 2;
              tokens.add(SyntaxToken(
                  type: TokenType.tag, start: i - 2, end: i));
              break;
            }
            if (text[i] == '>') {
              tokens.add(SyntaxToken(
                  type: TokenType.punctuation,
                  start: i,
                  end: i + 1));
              i++;
              break;
            }
            // Skip whitespace
            if (_isWhitespace(text[i])) {
              i++;
              continue;
            }
            // Attribute name
            final attrStart = i;
            while (i < text.length &&
                _isIdentChar(text[i]) && text[i] != '=' &&
                text[i] != '>' && text[i] != '/') {
              i++;
            }
            final attrName = text.substring(attrStart, i);
            tokens.add(SyntaxToken(
                type: config.htmlAttributes.any(
                        (a) => attrName == a || attrName.startsWith(a))
                    ? TokenType.attribute
                    : TokenType.identifier,
                start: attrStart,
                end: i));
            // =
            if (i < text.length && text[i] == '=') {
              tokens.add(SyntaxToken(
                  type: TokenType.operator,
                  start: i,
                  end: i + 1));
              i++;
            }
            // "value"
            if (i < text.length &&
                (text[i] == '"' || text[i] == "'")) {
              final strStart = i;
              final quote = text[i];
              i++;
              while (i < text.length && text[i] != quote) i++;
              if (i < text.length) i++;
              tokens.add(SyntaxToken(
                  type: TokenType.string,
                  start: strStart,
                  end: i));
            }
          }
          if (i < text.length && text[i] == '>') {
            i++;
          }
          continue;
        }
      }

      // Triples quotes (Python/Dart)
      if (config.hasTripleStrings &&
          (text[i] == '"' || text[i] == "'")) {
        if (i + 2 < text.length &&
            text[i] == text[i + 1] && text[i] == text[i + 2]) {
          final quote = text[i];
          final start = i;
          i += 3;
          while (i + 2 < text.length &&
              !(text[i] == quote && text[i + 1] == quote &&
                  text[i + 2] == quote)) {
            i++;
          }
          if (i + 2 < text.length) i += 3;
          tokens.add(SyntaxToken(
              type: TokenType.string, start: start, end: i));
          continue;
        }
      }

      // Strings
      if (config.stringChars.contains(text[i])) {
        final start = i;
        final quote = text[i];
        i++;
        while (i < text.length && text[i] != quote &&
            text[i] != '\n') {
          if (text[i] == '\\') i++; // escape
          i++;
        }
        if (i < text.length) i++;
        tokens.add(SyntaxToken(
            type: TokenType.string, start: start, end: i));
        continue;
      }

      // Preprocessor (#include, import, etc.)
      if (config.preprocessors.isNotEmpty &&
          text[i] == '#') {
        final start = i;
        i++;
        while (i < text.length &&
            _isIdentChar(text[i]) && text[i] != '\n') {
          i++;
        }
        tokens.add(SyntaxToken(
            type: TokenType.preprocessor, start: start, end: i));
        continue;
      }

      // Annotation (@Override, @deprecated)
      if (config.annotationChars.contains(text[i]) &&
          i + 1 < text.length &&
          _isAlpha(text[i + 1])) {
        final start = i;
        i++;
        while (i < text.length && _isIdentChar(text[i])) i++;
        tokens.add(SyntaxToken(
            type: TokenType.annotation, start: start, end: i));
        continue;
      }

      // Numbers
      if (_isDigit(text[i]) ||
          (text[i] == '.' && i + 1 < text.length &&
              _isDigit(text[i + 1]))) {
        final start = i;
        // Hex
        if (text[i] == '0' && i + 1 < text.length &&
            (text[i + 1] == 'x' || text[i + 1] == 'X')) {
          i += 2;
          while (i < text.length && _isHexDigit(text[i])) i++;
        } else {
          while (i < text.length && (_isDigit(text[i]) || text[i] == '.')) {
            i++;
          }
        }
        tokens.add(SyntaxToken(
            type: TokenType.number, start: start, end: i));
        continue;
      }

      // Identifiers / Keywords / Types
      if (_isIdentStart(text[i])) {
        final start = i;
        while (i < text.length && _isIdentChar(text[i])) i++;
        final word = text.substring(start, i);

        TokenType type;
        if (config.keywords.contains(word)) {
          type = TokenType.keyword;
        } else if (config.types.contains(word)) {
          type = TokenType.type;
        } else if (config.preprocessors.contains(word)) {
          type = TokenType.preprocessor;
        } else if (i < text.length && text[i] == '(') {
          type = TokenType.annotation; // function call — use annotation color
        } else {
          // Check if it's a $variable (PHP)
          type = TokenType.identifier;
        }

        tokens.add(SyntaxToken(type: type, start: start, end: i));
        continue;
      }

      // PHP variables ($var)
      if (text[i] == '\$' && i + 1 < text.length &&
          _isIdentStart(text[i + 1])) {
        final start = i;
        i++;
        while (i < text.length && _isIdentChar(text[i])) i++;
        tokens.add(SyntaxToken(
            type: TokenType.variable, start: start, end: i));
        continue;
      }

      // Operators
      if (_isOperator(text[i])) {
        final start = i;
        i++;
        tokens.add(SyntaxToken(
            type: TokenType.operator, start: start, end: i));
        continue;
      }

      // Punctuation
      if (_isPunctuation(text[i])) {
        final start = i;
        i++;
        tokens.add(SyntaxToken(
            type: TokenType.punctuation, start: start, end: i));
        continue;
      }

      // Whitespace / plain
      i++;
    }

    return _mergePlainTokens(tokens);
  }

  /// Fusiona tokens adyacentes de tipo plain.
  List<SyntaxToken> _mergePlainTokens(List<SyntaxToken> tokens) {
    if (tokens.isEmpty) return tokens;
    final merged = <SyntaxToken>[tokens.first];
    for (int i = 1; i < tokens.length; i++) {
      final last = merged.last;
      final curr = tokens[i];
      if (last.type == TokenType.plain &&
          curr.type == TokenType.plain &&
          last.end == curr.start) {
        merged[merged.length - 1] = SyntaxToken(
            type: TokenType.plain, start: last.start, end: curr.end);
      } else {
        merged.add(curr);
      }
    }
    return merged;
  }

  bool _matchAt(int pos, String pattern) {
    if (pos + pattern.length > text.length) return false;
    for (int i = 0; i < pattern.length; i++) {
      if (text[pos + i] != pattern[i]) return false;
    }
    return true;
  }

  bool _isIdentStart(String ch) =>
      _isAlpha(ch) || ch == '_';
  bool _isIdentChar(String ch) =>
      _isAlpha(ch) || _isDigit(ch) || ch == '_';
  bool _isAlpha(String ch) =>
      (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) ||
      (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122);
  bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
  bool _isHexDigit(String ch) =>
      _isDigit(ch) ||
      (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 70) ||
      (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 102);
  bool _isWhitespace(String ch) =>
      ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
  bool _isOperator(String ch) =>
      '+ - * / % = < > ! & | ^ ~ ? :'.contains(ch);
  bool _isPunctuation(String ch) =>
      '( ) { } [ ] ; , .'.contains(ch);
}
