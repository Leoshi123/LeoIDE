import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/completion/completion_engine.dart';
import 'package:leoide/editor/completion/models/completion_item.dart';

void main() {
  group('UsageTracker', () {
    test('item reciente sube en ranking', () {
      final engine = CompletionEngine();
      engine.setLanguage('dart');

      // Sin uso → ambos aparecen
      final result1 = engine.requestCompletions(
        fullText: 'pri',
        cursorOffset: 3,
      );
      // print está en la lista
      expect(result1.items.any((i) => i.label == 'print'), isTrue);

      // Usar print 3 veces
      engine.recordUsage('print');
      engine.recordUsage('print');
      engine.recordUsage('print');

      // Ahora print debería tener mejor score
      final result2 = engine.requestCompletions(
        fullText: 'pri',
        cursorOffset: 3,
      );
      final printIndex = result2.items.indexWhere((i) => i.label == 'print');
      expect(printIndex, lessThan(5)); // debe estar en top 5
    });

    test('recencia ordena items', () {
      final engine = CompletionEngine();
      engine.setLanguage('python');

      // Usar varios items en orden
      engine.recordUsage('print');
      engine.recordUsage('def');
      engine.recordUsage('class');
      engine.recordUsage('print');

      // print fue el último usado → debe tener más bonus
      final result = engine.requestCompletions(
        fullText: '',
        cursorOffset: 0,
      );

      // print debe aparecer antes que def y class
      final pIdx = result.items.indexWhere((i) => i.label == 'print');
      final dIdx = result.items.indexWhere((i) => i.label == 'def');
      expect(pIdx, lessThan(dIdx));
    });
  });
}
