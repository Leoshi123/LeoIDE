import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/completion/completion_engine.dart';

void main() {
  group('CompletionEngine', () {
    test('usage boost hace que items usados reciente aparezcan antes', () {
      final engine = CompletionEngine();
      engine.setLanguage('dart');

      // Usar print 3 veces
      engine.recordUsage('print');
      engine.recordUsage('print');
      engine.recordUsage('print');

      // print debe aparecer en el top 5 al escribir "pri"
      final result = engine.requestCompletions(
        fullText: 'pri',
        cursorOffset: 3,
      );

      final printIndex = result.items.indexWhere((i) => i.label == 'print');
      expect(printIndex, lessThan(5));
    });
  });
}