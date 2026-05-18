import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/engine/virtual_viewport.dart';

void main() {
  group('VirtualViewport - Inicialización', () {
    test('crea viewport con valores por defecto', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        totalLines: 100,
      );
      expect(vp.visibleLineCount, greaterThan(0));
      expect(vp.firstVisibleLine, 0);
      expect(vp.totalLines, 100);
    });

    test('calcula líneas visibles correctamente', () {
      final vp = VirtualViewport(
        viewportHeight: 240,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      // 240 / 24 = 10 líneas + 1 = 11 visibles sin safety buffer
      expect(vp.visibleLineCount, 11);
    });
  });

  group('VirtualViewport - Rango visible', () {
    test('al inicio muestra desde línea 0', () {
      final vp = VirtualViewport(
        viewportHeight: 240,
        viewportWidth: 400,
        lineHeight: 24,
        safetyBuffer: 2,
        totalLines: 100,
      );
      final (start, end) = vp.visibleRange;
      expect(start, 0);
      expect(end, greaterThan(0));
    });

    test('con scroll hacia abajo cambia el rango', () {
      final vp = VirtualViewport(
        viewportHeight: 240,
        viewportWidth: 400,
        lineHeight: 24,
        safetyBuffer: 2,
        totalLines: 100,
      );
      vp.scrollToLine(30);
      final (start, end) = vp.visibleRange;
      expect(start, greaterThan(0));
      expect(end, greaterThan(start));
    });

    test('el safety buffer añade líneas extra', () {
      final vp = VirtualViewport(
        viewportHeight: 240,
        viewportWidth: 400,
        lineHeight: 24,
        safetyBuffer: 5,
        totalLines: 100,
      );
      vp.scrollToLine(50);
      final (start, end) = vp.visibleRange;
      // Con safety=5, debería mostrar 5 líneas antes de la 50
      expect(start, 45);
    });
  });

  group('VirtualViewport - Scroll', () {
    test('scroll hacia abajo incrementa scrollY', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      vp.scrollBy(0, 100);
      expect(vp.scrollY, 100);
    });

    test('scroll no excede maxScrollY', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 10, // solo 10 líneas
      );
      vp.scrollBy(0, 99999);
      expect(vp.scrollY, vp.maxScrollY);
    });

    test('scroll no va por debajo de 0', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      vp.scrollBy(0, -99999);
      expect(vp.scrollY, 0);
    });
  });

  group('VirtualViewport - Cursor visible', () {
    test('ensureCursorVisible mueve scroll si cursor fuera de vista', () {
      final vp = VirtualViewport(
        viewportHeight: 240,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      // Cursor en línea 50, muy por debajo del viewport inicial
      vp.ensureCursorVisible(50, 0);
      expect(vp.scrollY, greaterThan(0));
    });

    test('ensureCursorVisible no mueve scroll si cursor ya visible', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      vp.ensureCursorVisible(2, 0); // línea 2 está visible inicialmente
      expect(vp.scrollY, 0);
    });
  });

  group('VirtualViewport - Conversión coordenadas', () {
    test('yToLine convierte posición Y a línea', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      expect(vp.yToLine(48), 2); // 48 / 24 = 2
    });

    test('lineToY convierte línea a posición Y', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      expect(vp.lineToY(5), 120); // 5 * 24 = 120
    });

    test('conversión con scroll', () {
      final vp = VirtualViewport(
        viewportHeight: 600,
        viewportWidth: 400,
        lineHeight: 24,
        totalLines: 100,
      );
      vp.scrollToLine(10); // scrollY = 240
      // Línea 12 en pantalla = (12 * 24) - 240 = 48
      expect(vp.lineToY(12), 48);
    });
  });
}
