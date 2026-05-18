/// Plantillas de código por lenguaje para el menú "Nuevo archivo".
class CodeTemplate {
  final String name;
  final String extension;
  final String code;

  const CodeTemplate({
    required this.name,
    required this.extension,
    required this.code,
  });

  static const List<CodeTemplate> all = [
    CodeTemplate(
      name: 'Dart - Hola Mundo',
      extension: '.dart',
      code: '''void main() {
  print("Hola, LeoIDE!");
}
''',
    ),
    CodeTemplate(
      name: 'Python - Hola Mundo',
      extension: '.py',
      code: '''print("Hola, LeoIDE!")

def main():
    print("Ejecutando desde LeoIDE")

if __name__ == "__main__":
    main()
''',
    ),
    CodeTemplate(
      name: 'C++ - Hola Mundo',
      extension: '.cpp',
      code: '''#include <iostream>

int main() {
    std::cout << "Hola, LeoIDE!" << std::endl;
    return 0;
}
''',
    ),
    CodeTemplate(
      name: 'C - Hola Mundo',
      extension: '.c',
      code: '''#include <stdio.h>

int main() {
    printf("Hola, LeoIDE!\\n");
    return 0;
}
''',
    ),
    CodeTemplate(
      name: 'HTML5 - Página básica',
      extension: '.html',
      code: '''<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LeoIDE</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #1e1e1e;
            color: #d4d4d4;
        }
    </style>
</head>
<body>
    <h1>Hola, LeoIDE!</h1>
    <script>
        console.log("Desde LeoIDE");
    </script>
</body>
</html>
''',
    ),
    CodeTemplate(
      name: 'PHP - Hola Mundo',
      extension: '.php',
      code: '''<?php
echo "Hola, LeoIDE!\\n";

function saludar(\$nombre) {
    return "Hola, \$nombre!";
}

echo saludar("Mundo");
?>
''',
    ),
    CodeTemplate(
      name: 'JavaScript - Hola Mundo',
      extension: '.js',
      code: '''function saludar(nombre) {
    console.log("Hola, " + nombre + "!");
    return "Hola, " + nombre + "!";
}

saludar("LeoIDE");

// Ejemplo con arrow function
const suma = (a, b) => a + b;
console.log(suma(3, 4));
''',
    ),
    CodeTemplate(
      name: 'CSS - Estilos básicos',
      extension: '.css',
      code: '''/* LeoIDE - Estilos básicos */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', sans-serif;
    background: #1e1e1e;
    color: #d4d4d4;
    line-height: 1.6;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.header {
    background: #252526;
    padding: 1rem;
    border-bottom: 2px solid #569CD6;
}
''',
    ),
    CodeTemplate(
      name: 'Python - Lista/Loop',
      extension: '.py',
      code: '''# Lista de ejemplo
numeros = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Filtrar pares
pares = [n for n in numeros if n % 2 == 0]
print(f"Pares: {pares}")

# Map y filter
cuadrados = list(map(lambda x: x**2, numeros))
print(f"Cuadrados: {cuadrados}")

# Diccionario
datos = {
    "nombre": "LeoIDE",
    "version": "1.0",
    "lenguajes": ["Python", "C++", "PHP", "JS"]
}

for key, value in datos.items():
    print(f"{key}: {value}")
''',
    ),
    CodeTemplate(
      name: 'C++ - Clase y Objeto',
      extension: '.cpp',
      code: '''#include <iostream>
#include <string>

class Persona {
private:
    std::string nombre;
    int edad;

public:
    Persona(std::string nombre, int edad)
        : nombre(nombre), edad(edad) {}

    void saludar() {
        std::cout << "Hola, soy " << nombre
                  << " y tengo " << edad << " anios"
                  << std::endl;
    }
};

int main() {
    Persona p("Leoshi", 20);
    p.saludar();
    return 0;
}
''',
    ),
  ];
}
