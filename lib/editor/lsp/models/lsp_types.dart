/// Tipos de datos del protocolo LSP (solo los que necesitamos).

class LspPosition {
  final int line;
  final int character;

  const LspPosition({required this.line, required this.character});

  Map<String, dynamic> toJson() => {
        'line': line,
        'character': character,
      };

  factory LspPosition.fromJson(Map<String, dynamic> json) => LspPosition(
        line: json['line'] as int,
        character: json['character'] as int,
      );
}

class LspRange {
  final LspPosition start;
  final LspPosition end;

  const LspRange({required this.start, required this.end});

  Map<String, dynamic> toJson() => {
        'start': start.toJson(),
        'end': end.toJson(),
      };

  factory LspRange.fromJson(Map<String, dynamic> json) => LspRange(
        start: LspPosition.fromJson(json['start'] as Map<String, dynamic>),
        end: LspPosition.fromJson(json['end'] as Map<String, dynamic>),
      );
}

class LspTextDocumentItem {
  final String uri;
  final String languageId;
  final int version;
  final String text;

  const LspTextDocumentItem({
    required this.uri,
    required this.languageId,
    required this.version,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'languageId': languageId,
        'version': version,
        'text': text,
      };
}

class LspVersionedTextDocumentIdentifier {
  final String uri;
  final int version;

  const LspVersionedTextDocumentIdentifier({
    required this.uri,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        '_uri': uri,
        'uri': uri,
        'version': version,
      };
}

class LspCompletionItem {
  final String label;
  final String? insertText;
  final int? kind;
  final String? detail;
  final String? documentation;

  const LspCompletionItem({
    required this.label,
    this.insertText,
    this.kind,
    this.detail,
    this.documentation,
  });

  factory LspCompletionItem.fromJson(Map<String, dynamic> json) =>
      LspCompletionItem(
        label: json['label'] as String,
        insertText: json['insertText'] as String?,
        kind: json['kind'] as int?,
        detail: json['detail'] as String?,
        documentation: json['documentation'] as String?,
      );
}

/// Mapa de languageId LSP → extensión de archivo.
const Map<String, String> lspLanguageExtensions = {
  'dart': '.dart',
  'python': '.py',
  'cpp': '.cpp',
  'c': '.c',
  'javascript': '.js',
  'typescript': '.ts',
  'php': '.php',
  'html': '.html',
  'css': '.css',
};

/// Mapa de extensión → languageId LSP.
const Map<String, String> extensionToLspLanguage = {
  '.dart': 'dart',
  '.py': 'python',
  '.cpp': 'cpp',
  '.cc': 'cpp',
  '.cxx': 'cpp',
  '.c': 'c',
  '.js': 'javascript',
  '.mjs': 'javascript',
  '.php': 'php',
  '.html': 'html',
  '.htm': 'html',
  '.css': 'css',
};
