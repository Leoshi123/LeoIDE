# LeoIDE ⚡

> IDE móvil personal de alto rendimiento. Hecho para quien escribe código de verdad desde el teléfono. Sin publicidad. Sin telemetría.

LeoIDE es un entorno de desarrollo integrado construido con Flutter, diseñado para ejecutar y editar código directamente en el dispositivo.

---

## Estado Actual

```
Motor de Texto    ████████████  Piece Table + Virtual Viewport
Editor            ████████████  Highlight + LSP + Completado
Interfaz          ████████████  Tabs + Status Bar + Explorador
LSP               ████████████  Diagnostics + Autocompletado
Runner C/C++      ████████░░░░  Compilación por stdin
Runner Python     ████████░░░░  Ejecución local
Runner PHP/JS     ████░░░░░░░░  En desarrollo
Build Android     ░░░░░░░░░░░░  Pendiente
```

## Lenguajes Soportados

| Lenguaje    | Editor | Resaltado | Ejecución |
|-------------|--------|-----------|-----------|
| Dart        | ✅     | ✅        | ✅        |
| Python      | ✅     | ✅        | ✅        |
| C           | ✅     | ✅        | ✅        |
| C++         | ✅     | ✅        | ✅        |
| JavaScript  | ✅     | ✅        | 🚧        |
| PHP         | ✅     | ✅        | 🚧        |
| HTML        | ✅     | ✅        | 🚧        |
| CSS         | ✅     | ✅        | 🚧        |

## Características

- ✏️ **Piece Table Engine** — edición O(1), undo sin duplicar memoria
- 🎨 **Resaltado sintaxis** — 8 lenguajes con FSM lexer
- 🔍 **LSP integrado** — errores/warnings en gutter, autocompletado inteligente
- 📂 **File Explorer** — navegación por árbol de archivos, crear/eliminar
- 📑 **Sistema de Tabs** — pestañas con pin, persistencia entre sesiones
- 📊 **Status Bar** — Ln/Col, errores, warnings, encoding, lenguaje
- ⌨️ **Barra de símbolos** — teclado extendido sobre el teclado virtual
- 🌙 **Tema oscuro/claro**
- 🏃 **Runner multi-lenguaje** — ejecución por stdin, salida en vivo
- 🧠 **Completion Engine** — ranking por frecuencia + tipo de símbolo
- 🔎 **Detector de Lenguaje** — 3 estrategias: extensión, shebang, heurística

## Stack Tecnológico

| Capa          | Tecnología                        |
|---------------|-----------------------------------|
| UI            | Flutter + CustomPainter           |
| Lenguaje      | Dart                              |
| Texto         | Piece Table (buffer dual)         |
| Renderizado   | Virtual Viewport (solo visibles)  |
| Análisis      | LSP Client (JSON-RPC sobre stdin) |
| Compilación   | NDK (Clang) / Python3             |

## Detección de Lenguaje

LeoIDE usa 3 estrategias para detectar el lenguaje sin conexión:

1. **Extensión** `.py` → Python, `.dart` → Dart (rápido, 90% casos)
2. **Shebang** `#!/usr/bin/python3` → Python, `#!/usr/bin/node` → JS
3. **Heurística** `def `, `class X:`, `print(` → Python (peso por patrón)

## Captura de Pantalla

```
┌──────────────────────────────────────┐
│ [PYTHON] script.py        [☰][+][▶] │
├──────────────────────────────────────┤
│ main.dart │ ● script.py │ * test.js │
├──────────────────────────────────────┤
│  1 │ def hola():                     │
│  2 │     print("Mundo")             │
│  3 │                                 │
│  4 │ hola()                          │
│    │─────────────────────────────────│
│    │  ⚠ 2 warnings                  │
├──────────────────────────────────────┤
│ Listo         Ln 2, Col 12  UTF-8 PY│
└──────────────────────────────────────┘
```

## Arquitectura

```
┌────────────────────────────────────────────┐
│              UI (Flutter)                  │
│  Tabs · Editor Canvas · Status Bar        │
│  File Explorer · Completion Popup         │
└─────────────────────┬──────────────────────┘
                      │
┌─────────────────────▼──────────────────────┐
│          Text Engine (Model)               │
│  Piece Table · Virtual Viewport · Cursor   │
│  Undo/Redo · Sincronización TextField      │
└────────┬────────────┬────────────┬─────────┘
         │            │            │
         ▼            ▼            ▼
┌──────────────┐ ┌────────┐ ┌─────────────┐
│  LSP Client  │ │ Runner │ │ Completion  │
│ Diagnostics  │ │ stdin  │ │ Engine      │
│ Autocomplete │ │ stdout │ │ Frecuencia  │
└──────────────┘ └────────┘ └─────────────┘
```

## Uso (Linux / Escritorio)

```bash
cd leoide_app
flutter run -d linux
```

## Atajos de Teclado

| Atajo       | Acción               |
|-------------|----------------------|
| `Ctrl+S`    | Guardar archivo      |
| `Ctrl+Z`    | Deshacer             |
| `Ctrl+Shift+Z` | Rehacer          |
| `F5`        | Ejecutar código      |
| `Esc`       | Cerrar autocompletado |

## Construcción

```bash
# Linux (desarrollo)
flutter build linux --debug

# Android
flutter build apk --debug
```

## Autor

**Leoshi** — Estudiante de Ingeniería · UPTEC-MS
