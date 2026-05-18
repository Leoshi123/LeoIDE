import '../models/completion_item.dart';

/// Provider de snippets de código.
///
/// Ofrece templates abreviados como:
///   "fori" → for (int i = 0; i < n; i++)
///   "main" → int main() { ... }
///   "class" → class Nombre { ... }
class SnippetProvider {
  final String language;

  SnippetProvider(this.language);

  /// Snippets por lenguaje.
  List<CompletionItem> getSnippets() {
    switch (language) {
      case 'dart':
        return _dartSnippets;
      case 'python':
        return _pythonSnippets;
      case 'cpp':
      case 'c':
        return _cSnippets;
      case 'javascript':
        return _jsSnippets;
      case 'php':
        return _phpSnippets;
      case 'html':
        return _htmlSnippets;
      default:
        return [];
    }
  }

  static const _dartSnippets = [
    CompletionItem(
      label: 'main',
      insertText: 'void main() {\n  \n}',
      kind: CompletionItemKind.snippet,
      detail: 'Función main',
    ),
    CompletionItem(
      label: 'class',
      insertText: 'class \$1 {\n  \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de clase',
    ),
    CompletionItem(
      label: 'stful',
      insertText: 'class \$1 extends StatefulWidget {\n  @override\n  State<\$1> createState() => _\${1}State();\n}\n\nclass _\${1}State extends State<\$1> {\n  @override\n  Widget build(BuildContext context) {\n    return \$0;\n  }\n}',
      kind: CompletionItemKind.snippet,
      detail: 'StatefulWidget',
    ),
    CompletionItem(
      label: 'stless',
      insertText: 'class \$1 extends StatelessWidget {\n  @override\n  Widget build(BuildContext context) {\n    return \$0;\n  }\n}',
      kind: CompletionItemKind.snippet,
      detail: 'StatelessWidget',
    ),
    CompletionItem(
      label: 'fori',
      insertText: 'for (int i = 0; i < \$1; i++) {\n  \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Bucle for con índice',
    ),
    CompletionItem(
      label: 'print',
      insertText: 'print("\$1");',
      kind: CompletionItemKind.snippet,
      detail: 'Print statement',
    ),
  ];

  static const _pythonSnippets = [
    CompletionItem(
      label: 'main',
      insertText: 'def main():\n    \$0\n\nif __name__ == "__main__":\n    main()',
      kind: CompletionItemKind.snippet,
      detail: 'Función main',
    ),
    CompletionItem(
      label: 'class',
      insertText: 'class \$1:\n    def __init__(self):\n        \$0',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de clase',
    ),
    CompletionItem(
      label: 'for',
      insertText: 'for \$1 in \$2:\n    \$0',
      kind: CompletionItemKind.snippet,
      detail: 'Bucle for',
    ),
    CompletionItem(
      label: 'ifmain',
      insertText: 'if __name__ == "__main__":\n    \$0',
      kind: CompletionItemKind.snippet,
      detail: 'Guard main',
    ),
    CompletionItem(
      label: 'def',
      insertText: 'def \$1(\$2):\n    """\$3"""\n    \$0',
      kind: CompletionItemKind.snippet,
      detail: 'Define función',
    ),
  ];

  static const _cSnippets = [
    CompletionItem(
      label: 'main',
      insertText: 'int main() {\n    \$0\n    return 0;\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Función main',
    ),
    CompletionItem(
      label: 'for',
      insertText: 'for (int \$1 = 0; \$1 < \$2; \$1++) {\n    \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Bucle for',
    ),
    CompletionItem(
      label: 'printf',
      insertText: 'printf("\$1\\\\n", \$2);',
      kind: CompletionItemKind.snippet,
      detail: 'Print con formato',
    ),
    CompletionItem(
      label: 'class',
      insertText: 'class \$1 {\npublic:\n    \$1() {}\n    \$0\n};',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de clase',
    ),
    CompletionItem(
      label: 'include',
      insertText: '#include <\$1>\n\$0',
      kind: CompletionItemKind.snippet,
      detail: 'Directiva include',
    ),
  ];

  static const _jsSnippets = [
    CompletionItem(
      label: 'function',
      insertText: 'function \$1(\$2) {\n    \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de función',
    ),
    CompletionItem(
      label: 'arrow',
      insertText: 'const \$1 = (\$2) => {\n    \$0\n};',
      kind: CompletionItemKind.snippet,
      detail: 'Arrow function',
    ),
    CompletionItem(
      label: 'for',
      insertText: 'for (let \$1 = 0; \$1 < \$2; \$1++) {\n    \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Bucle for',
    ),
    CompletionItem(
      label: 'class',
      insertText: 'class \$1 {\n    constructor(\$2) {\n        \$0\n    }\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de clase ES6',
    ),
    CompletionItem(
      label: 'clog',
      insertText: 'console.log(\$1);',
      kind: CompletionItemKind.snippet,
      detail: 'Console log',
    ),
  ];

  static const _phpSnippets = [
    CompletionItem(
      label: 'class',
      insertText: 'class \$1 {\n    public function __construct() {\n        \$0\n    }\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de clase PHP',
    ),
    CompletionItem(
      label: 'function',
      insertText: 'function \$1(\$2) {\n    \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Declaración de función',
    ),
    CompletionItem(
      label: 'foreach',
      insertText: 'foreach (\$1 as \$2) {\n    \$0\n}',
      kind: CompletionItemKind.snippet,
      detail: 'Bucle foreach',
    ),
    CompletionItem(
      label: 'echo',
      insertText: 'echo "\$1";',
      kind: CompletionItemKind.snippet,
      detail: 'Echo statement',
    ),
  ];

  static const _htmlSnippets = [
    CompletionItem(
      label: 'div',
      insertText: '<div>\n    \$0\n</div>',
      kind: CompletionItemKind.snippet,
      detail: 'Div container',
    ),
    CompletionItem(
      label: 'linkcss',
      insertText: '<link rel="stylesheet" href="\$1">',
      kind: CompletionItemKind.snippet,
      detail: 'Link CSS externo',
    ),
    CompletionItem(
      label: 'script',
      insertText: '<script src="\$1"></script>',
      kind: CompletionItemKind.snippet,
      detail: 'Script tag',
    ),
    CompletionItem(
      label: 'img',
      insertText: '<img src="\$1" alt="\$2">',
      kind: CompletionItemKind.snippet,
      detail: 'Image tag',
    ),
    CompletionItem(
      label: 'form',
      insertText: '<form action="\$1" method="\$2">\n    \$0\n</form>',
      kind: CompletionItemKind.snippet,
      detail: 'Formulario',
    ),
  ];
}
