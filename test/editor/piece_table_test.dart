import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/models/piece_table.dart';

void main() {
  group('PieceTable - Inicialización', () {
    test('crea tabla vacía', () {
      final pt = PieceTable.empty();
      expect(pt.text, '');
      expect(pt.length, 0);
      expect(pt.pieceCount, 0);
    });

    test('crea tabla con texto inicial', () {
      final pt = PieceTable('Hola Mundo');
      expect(pt.text, 'Hola Mundo');
      expect(pt.length, 10);
      expect(pt.pieceCount, 1);
    });
  });

  group('PieceTable - Inserción', () {
    test('inserta al inicio', () {
      final pt = PieceTable('mundo');
      pt.insert(0, 'hola ');
      expect(pt.text, 'hola mundo');
    });

    test('inserta al final', () {
      final pt = PieceTable('hola ');
      pt.insert(5, 'mundo');
      expect(pt.text, 'hola mundo');
    });

    test('inserta en medio', () {
      final pt = PieceTable('homundo');
      pt.insert(3, 'l');
      expect(pt.text, 'holmundo');
    });

    test('inserta caracteres especiales', () {
      final pt = PieceTable('');
      pt.insert(0, '(){}[];\'"');
      expect(pt.text, '(){}[];\'"');
    });
  });

  group('PieceTable - Borrado', () {
    test('elimina caracteres en medio', () {
      final pt = PieceTable('hola mundo');
      pt.delete(4, 1); // elimina el espacio
      expect(pt.text, 'holamundo');
    });

    test('elimina al inicio', () {
      final pt = PieceTable('hola mundo');
      pt.delete(0, 5); // elimina "hola "
      expect(pt.text, 'mundo');
    });

    test('elimina al final', () {
      final pt = PieceTable('hola mundo');
      pt.delete(5, 5); // elimina "mundo"
      expect(pt.text, 'hola ');
    });

    test('eliminar 0 caracteres no cambia nada', () {
      final pt = PieceTable('test');
      pt.delete(0, 0);
      expect(pt.text, 'test');
    });

    test('eliminar más allá del límite se clamp', () {
      final pt = PieceTable('abc');
      pt.delete(0, 100);
      expect(pt.text, '');
    });
  });

  group('PieceTable - Undo/Redo', () {
    test('undo después de insertar', () {
      final pt = PieceTable('hola');
      pt.insert(4, ' mundo');
      expect(pt.text, 'hola mundo');
      pt.undo();
      expect(pt.text, 'hola');
    });

    test('redo después de undo', () {
      final pt = PieceTable('hola');
      pt.insert(4, ' mundo');
      pt.undo();
      pt.redo();
      expect(pt.text, 'hola mundo');
    });

    test('undo múltiple', () {
      final pt = PieceTable('');
      pt.insert(0, 'a');
      pt.insert(1, 'b');
      pt.insert(2, 'c');
      expect(pt.text, 'abc');
      pt.undo();
      expect(pt.text, 'ab');
      pt.undo();
      expect(pt.text, 'a');
      pt.undo();
      expect(pt.text, '');
    });
  });

  group('PieceTable - Navegación', () {
    test('cuenta líneas correctamente', () {
      final pt = PieceTable('l1\nl2\nl3');
      expect(pt.lineCount, 3);
    });

    test('línea vacía cuenta como 1', () {
      final pt = PieceTable('');
      expect(pt.lineCount, 1);
    });

    test('lineAt retorna línea específica', () {
      final pt = PieceTable('primera\nsegunda\ntercera');
      expect(pt.lineAt(0), 'primera');
      expect(pt.lineAt(1), 'segunda');
      expect(pt.lineAt(2), 'tercera');
    });

    test('lineLengths retorna longitudes correctas', () {
      final pt = PieceTable('ab\ncd\ne');
      expect(pt.lineLengths, [2, 2, 1]);
    });

    test('positionToLineCol', () {
      final pt = PieceTable('abc\ndef');
      // a=0, b=1, c=2, \n=3, d=4, e=5, f=6
      final (line, col) = pt.positionToLineCol(5);
      expect(line, 1);
      expect(col, 1); // 'e' está en línea 1, columna 1
    });

    test('lineColToPosition', () {
      final pt = PieceTable('abc\ndef');
      final pos = pt.lineColToPosition(1, 0); // inicio de línea 1
      expect(pos, 4); // 'd' está en posición global 4
    });
  });

  group('PieceTable - Casos borde', () {
    test('insertar en tabla vacía', () {
      final pt = PieceTable.empty();
      pt.insert(0, 'test');
      expect(pt.text, 'test');
    });

    test('múltiples inserciones seguidas', () {
      final pt = PieceTable('');
      pt.insert(0, 'a');
      pt.insert(1, 'b');
      pt.insert(2, 'c');
      expect(pt.text, 'abc');
    });

    test('insertar y borrar alternadamente', () {
      final pt = PieceTable('abc');
      pt.delete(1, 1); // 'ac'
      pt.insert(1, 'X'); // 'aXc'
      expect(pt.text, 'aXc');
    });

    test('charAt en posición válida', () {
      final pt = PieceTable('abc');
      expect(pt.charAt(0), 'a');
      expect(pt.charAt(1), 'b');
      expect(pt.charAt(2), 'c');
    });

    test('charAt lanza error en posición inválida', () {
      final pt = PieceTable('abc');
      expect(() => pt.charAt(5), throwsRangeError);
    });
  });
}
