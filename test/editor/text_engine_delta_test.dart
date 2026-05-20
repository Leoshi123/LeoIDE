import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/engine/text_engine.dart';
import 'package:leoide/editor/models/cursor.dart';

void main() {
  group('TextEngine Delta Tests', () {
    test('insertAtCursor should emit delta with isInsert=true', () {
      final engine = TextEngine.empty();
      TextDelta? lastDelta;

      engine.onDelta = (delta) {
        lastDelta = delta;
      };

      engine.insertAtCursor('A');

      expect(lastDelta, isNotNull);
      expect(lastDelta!.isInsert, isTrue);
      expect(lastDelta!.text, equals('A'));
      expect(lastDelta!.offset, equals(0));
    });

    test('backspace should emit delta with isInsert=false', () {
      final engine = TextEngine('Hello');
      engine.moveCursorRight();
      engine.moveCursorRight();
      engine.moveCursorRight(); // offset 3
      
      TextDelta? lastDelta;
      engine.onDelta = (delta) {
        lastDelta = delta;
      };

      engine.backspace();

      expect(lastDelta, isNotNull);
      expect(lastDelta!.isInsert, isFalse);
      expect(lastDelta!.text, equals('l'));
      expect(lastDelta!.offset, equals(2)); // Deleted char at index 2
    });

    test('deleteForward should emit delta with isInsert=false', () {
      final engine = TextEngine('Hello');
      engine.moveCursorRight(); // offset 1
      
      TextDelta? lastDelta;
      engine.onDelta = (delta) {
        lastDelta = delta;
      };

      engine.deleteForward();

      expect(lastDelta, isNotNull);
      expect(lastDelta!.isInsert, isFalse);
      expect(lastDelta!.text, equals('e'));
      expect(lastDelta!.offset, equals(1)); // Deleted char at index 1
    });

    test('newline should emit delta with isInsert=true', () {
      final engine = TextEngine('Hello');
      
      TextDelta? lastDelta;
      engine.onDelta = (delta) {
        lastDelta = delta;
      };

      engine.insertNewline();

      expect(lastDelta, isNotNull);
      expect(lastDelta!.isInsert, isTrue);
      expect(lastDelta!.text, equals('\n'));
      expect(lastDelta!.offset, equals(0));
    });
  });
}
