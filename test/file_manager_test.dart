import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/engine/file_manager.dart';
import 'dart:io';

void main() {
  group('FileManager', () {
    late FileManager fm;
    final testRoot = '${Directory.systemTemp.path}/leoide_test_${DateTime.now().millisecondsSinceEpoch}';

    setUp(() {
      fm = FileManager(projectRoot: testRoot);
    });

    tearDown(() {
      Directory(testRoot).deleteSync(recursive: true);
    });

    test('crea directorio raíz automaticamente', () {
      expect(Directory(testRoot).existsSync(), isTrue);
    });

    test('guarda y carga archivos', () async {
      await fm.saveFile('test.py', 'print("hello")');
      final content = await fm.loadFile('test.py');
      expect(content, 'print("hello")');
    });

    test('extensionOf extrae extensión', () {
      expect(FileManager.extensionOf('script.py'), '.py');
      expect(FileManager.extensionOf('main.dart'), '.dart');
      expect(FileManager.extensionOf('sin_extension'), '.txt');
      expect(FileManager.extensionOf('style.css'), '.css');
    });

    test('listFiles retorna archivos guardados', () async {
      await fm.saveFile('a.dart', 'void main() {}');
      await fm.saveFile('b.py', 'print("hi")');
      final files = fm.listFiles();
      expect(files, contains('a.dart'));
      expect(files, contains('b.py'));
    });

    test('recentFiles ordena por uso', () async {
      await fm.saveFile('primero.py', '');
      await fm.saveFile('segundo.py', '');
      await fm.loadFile('primero.py');
      // primero debería estar primero (re-abierto)
      expect(fm.recentFiles.indexOf('primero.py'),
          lessThan(fm.recentFiles.indexOf('segundo.py')));
    });
  });
}
