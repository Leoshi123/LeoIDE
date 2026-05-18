import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/engine/language_detector.dart';

void main() {
  group('LanguageDetector', () {
    // ── Python ──

    test('detecta Python por shebang', () {
      final result = LanguageDetector.detect('#!/usr/bin/python3\nprint("hi")');
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });

    test('detecta Python por def y print', () {
      final code = '''
def hola():
    print("Hola mundo")
hola()
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });

    test('detecta Python por if __name__', () {
      final code = '''
def main():
    pass

if __name__ == '__main__':
    main()
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });

    test('detecta Python por clase sin llaves', () {
      final code = '''
class Persona:
    def __init__(self, nombre):
        self.nombre = nombre
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });

    // ── Dart ──

    test('detecta Dart por main()', () {
      final code = '''
void main() {
  print("Hello");
}
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'dart');
      expect(result.isValid, isTrue);
    });

    test('detecta Dart por import dart:', () {
      final code = "import 'dart:io';\n\nvoid main() => print('ok');";
      final result = LanguageDetector.detect(code);
      expect(result.language, 'dart');
      expect(result.isValid, isTrue);
    });

    test('detecta Dart con clase, override, extends', () {
      final code = '''
import 'package:flutter/material.dart';

class MiWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'dart');
      expect(result.isValid, isTrue);
    });

    // ── C ──

    test('detecta C por #include <...> y printf', () {
      final code = '''
#include <stdio.h>

int main() {
    printf("Hola mundo\\n");
    return 0;
}
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'c');
      expect(result.isValid, isTrue);
    });

    // ── C++ ──

    test('detecta C++ por iostream y std::cout', () {
      final code = '''
#include <iostream>

int main() {
    std::cout << "Hola" << std::endl;
    return 0;
}
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'cpp');
      expect(result.isValid, isTrue);
    });

    test('detecta C++ por template y clase', () {
      final code = '''
template <typename T>
class Vector {
public:
    Vector() {}
private:
    T* data;
};
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'cpp');
      expect(result.isValid, isTrue);
    });

    // ── JavaScript ──

    test('detecta JavaScript por function y console.log', () {
      final code = '''
function saludo(nombre) {
    console.log("Hola " + nombre);
}
saludo("Mundo");
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'javascript');
      expect(result.isValid, isTrue);
    });

    test('detecta JavaScript por const/let y arrow', () {
      final code = '''
const suma = (a, b) => a + b;
let resultado = suma(3, 4);
console.log(resultado);
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'javascript');
      expect(result.isValid, isTrue);
    });

    // ── PHP ──

    test('detecta PHP por <?php', () {
      final code = '<?php\necho "Hola mundo";\n';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'php');
      expect(result.isValid, isTrue);
    });

    test('detecta PHP con variables', () {
      final code = '''<?php
\$nombre = "Mundo";
echo "Hola " . \$nombre;
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'php');
      expect(result.isValid, isTrue);
    });

    // ── HTML ──

    test('detecta HTML por doctype y tags', () {
      final code = '''<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body><p>Hola</p></body>
</html>''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'html');
      expect(result.isValid, isTrue);
    });

    // ── CSS ──

    test('detecta CSS por selectores y propiedades', () {
      final code = '''
body {
    margin: 0;
    padding: 0;
    color: #333;
}
.container {
    display: flex;
}
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'css');
      expect(result.isValid, isTrue);
    });

    test('detecta CSS por @media', () {
      final code = '''
@media (max-width: 600px) {
    body { font-size: 14px; }
}
''';
      final result = LanguageDetector.detect(code);
      expect(result.language, 'css');
      expect(result.isValid, isTrue);
    });

    // ── HINT extension ──

    test('usa hint extension para código ambiguo', () {
      final code = '''
print("hola")
print("mundo")
''';
      // Sin hint, podría ser Python o Dart
      final result = LanguageDetector.detect(code, hintExtension: '.py');
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });

    test('código vacío usa hint', () {
      final result = LanguageDetector.detect('', hintExtension: '.py');
      expect(result.language, 'python');
    });

    test('código vacío sin hint usa dart', () {
      final result = LanguageDetector.detect('');
      expect(result.language, 'dart');
    });

    // ── Override: Python en .dart ──

    test('Python code en .dart detecta Python (caso real)', () {
      final code = '''
nombre = input("Cómo te llamas? ")
print(f"Hola {nombre}")

for i in range(5):
    print(i)
''';
      final result = LanguageDetector.detect(code, hintExtension: '.dart');
      // Debe detectar python aunque el hint sea .dart
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });

    test('print suelto en .dart detecta Python', () {
      // Este es el caso exacto que falló: print("Hello") sin main()
      final code = 'print("Hello, LeoIDE!")';
      final result = LanguageDetector.detect(code, hintExtension: '.dart');
      expect(result.language, 'python');
      expect(result.isValid, isTrue);
    });
  });
}
