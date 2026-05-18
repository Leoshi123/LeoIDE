import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/lsp/models/lsp_types.dart';

void main() {
  group('LspDiagnostic', () {
    test('parsea diagnóstico básico', () {
      final json = {
        'range': {
          'start': {'line': 5, 'character': 10},
          'end': {'line': 5, 'character': 20},
        },
        'severity': 1,
        'message': "Expected ';' after return statement",
        'source': 'dart',
      };

      final diag = LspDiagnostic.fromJson(json);
      expect(diag.startLine, 5);
      expect(diag.startCol, 10);
      expect(diag.endLine, 5);
      expect(diag.endCol, 20);
      expect(diag.severity, DiagnosticSeverity.error);
      expect(diag.message, "Expected ';' after return statement");
      expect(diag.source, 'dart');
    });

    test('parsea warning', () {
      final json = {
        'range': {
          'start': {'line': 2, 'character': 0},
          'end': {'line': 2, 'character': 5},
        },
        'severity': 2,
        'message': 'Unused import',
      };

      final diag = LspDiagnostic.fromJson(json);
      expect(diag.startLine, 2);
      expect(diag.severity, DiagnosticSeverity.warning);
      expect(diag.message, 'Unused import');
    });

    test('severidad default es error si no se especifica', () {
      final json = {
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 0, 'character': 1},
        },
        'message': 'Something wrong',
      };

      final diag = LspDiagnostic.fromJson(json);
      expect(diag.severity, DiagnosticSeverity.error);
    });

    test('DiagnosticSeverity.fromValue', () {
      expect(DiagnosticSeverity.fromValue(1), DiagnosticSeverity.error);
      expect(DiagnosticSeverity.fromValue(2), DiagnosticSeverity.warning);
      expect(DiagnosticSeverity.fromValue(3), DiagnosticSeverity.info);
      expect(DiagnosticSeverity.fromValue(4), DiagnosticSeverity.hint);
      expect(DiagnosticSeverity.fromValue(99), DiagnosticSeverity.info);
    });
  });
}
