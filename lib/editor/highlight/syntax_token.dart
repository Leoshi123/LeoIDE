/// Tipo de token sintáctico.
enum TokenType {
  keyword,
  type,
  string,
  comment,
  number,
  annotation,
  operator,
  punctuation,
  identifier,
  variable,
  property,
  tag, // HTML/XML tags
  attribute, // HTML/XML attributes
  preprocessor, // #include, import, etc.
  plain, // texto plano sin resaltar
}

/// Un token sintáctico: tipo + rango en el texto.
class SyntaxToken {
  final TokenType type;
  final int start;
  final int end;

  const SyntaxToken({
    required this.type,
    required this.start,
    required this.end,
  });

  int get length => end - start;
}
