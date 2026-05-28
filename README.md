# LeoIDE ⚡

> IDE móvil personal de alto rendimiento. Hecho para quien escribe código de verdad desde el teléfono. Sin publicidad. Sin telemetría.

LeoIDE es un entorno de desarrollo integrado construido con Flutter, diseñado para ejecutar y editar código directamente en el dispositivo.

---

## Estado Actual

```
Motor de Texto    ████████████  Piece Table + Virtual Viewport
Editor            ████████████  Highlight + LSP + Completado
Interfaz          ████████████  EditorShell 3-panel + ActivityBar + Toolbar responsive
LSP               ████████████  Diagnostics + Autocompletado
Runner C/C++      ████████████  Compilación por stdin
Runner Python     ████████████  Ejecución local
Runner PHP/JS     ████████░░░░  En desarrollo
Build Android     ████████████  JDK 21 + APK funcional
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

- 🎨 **EditorShell 3-panel** — layout tipo VS Code con ActivityBar, Sidebar animado y Terminal
- 📱 **Toolbar responsive** — se adapta a móvil (<600px) agrupando acciones en menú emergente
- 📑 **TabBar con overflow** — flechas de scroll lateral + menú desplegable para tabs ocultos
- ✏️ **Piece Table Engine** — edición O(1), undo sin duplicar memoria
- 🎨 **Resaltado sintaxis** — 8 lenguajes con FSM lexer
- 🔍 **LSP integrado** — errores/warnings en gutter, autocompletado inteligente
- 📂 **File Explorer** — navegación por árbol de archivos, crear/eliminar
- 📊 **Status Bar** — Ln/Col, errores, warnings, encoding, lenguaje
- ⌨️ **Barra de símbolos** — teclado extendido sobre el teclado virtual
- 🌙 **Tema oscuro/claro**
- 🏃 **Runner multi-lenguaje** — ejecución por stdin, salida en vivo con cancelación
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

## Captura de Pantalla

```
┌──────────────────────────────────────────────────┐
│ [PYTHON] script.py        [☰][+][▶][🔄][💾]... │
├──────────────────────────────────────────────────┤
│ main.dart │ ● script.py │ * test.js │  <  >  ☰  │
├──────┬───────────────────────────────────────────┤
│ 📁   │  1 │ def hola():                          │
│ src/ │  2 │     print("Mundo")                   │
│      │  3 │                                       │
│      │  4 │ hola()                                │
│      │    │───────────────────────────────────────│
│      │    │  ⚠ 2 warnings                        │
├──────┴───────────────────────────────────────────┤
│ 🔲 Listo         Ln 2, Col 12  UTF-8 PY          │
└──────────────────────────────────────────────────┘
```

## Arquitectura

```
┌──────────────────────────────────────────────────┐
│              EditorShell (Layout)                │
│  ┌──────────┬──────────────┬───────────────────┐ │
│  │Activity  │  Sidebar     │  Central Area     │ │
│  │Bar       │  (animated)  ├───────────────────┤ │
│  │          │  FileExplorer │  TabBar + Toolbar │ │
│  │ 📁       │  Search       │  ┌─────────────┐ │ │
│  │ 🔍       │  AI Agent     │  │ EditorCanvas│ │ │
│  │ 🤖       │  Settings     │  │(RepaintBdry)│ │ │
│  │ ⚙️       │              │  ├─────────────┤ │ │
│  │          │              │  │ Diagnostics │ │ │
│  │          │              │  ├─────────────┤ │ │
│  │          │              │  │ Terminal    │ │ │
│  │          │              │  └─────────────┘ │ │
│  └──────────┴──────────────┴───────────────────┘ │
└─────────────────────┬────────────────────────────┘
                      │
┌─────────────────────▼────────────────────────────┐
│              Text Engine (Model)                 │
│  Piece Table · Virtual Viewport · Cursor         │
│  Undo/Redo · Sincronización TextField            │
└────────┬────────────┬────────────┬───────────────┘
         │            │            │
         ▼            ▼            ▼
┌──────────────┐ ┌────────┐ ┌─────────────┐
│  LSP Client  │ │ Runner │ │ Completion  │
│  Diagnostics │ │ stdin  │ │ Engine      │
│  Autocomplete│ │ stdout │ │ Frecuencia  │
└──────────────┘ └────────┘ └─────────────┘
```

## Construcción

```bash
# Requiere JDK 21 para build Android
# En Arch/CachyOS:
#   sudo pacman -S jdk21-openjdk
#   export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

# Android (APK debug)
JAVA_HOME=/usr/lib/jvm/java-21-openjdk flutter build apk --debug

# Linux (escritorio)
flutter build linux --debug
```

## Uso (Linux / Escritorio)

```bash
cd leoide_app
flutter run -d linux
```

## Atajos de Teclado

| Atajo            | Acción               |
|------------------|----------------------|
| `Ctrl+S`         | Guardar archivo      |
| `Ctrl+Z`         | Deshacer             |
| `Ctrl+Shift+Z`   | Rehacer              |
| `F5`             | Ejecutar código      |
| `Esc`            | Cerrar autocompletado |

## Roadmap

- [x] EditorShell 3-panel (ActivityBar + Sidebar + Central Area)
- [x] Toolbar responsive (móvil/desktop)
- [x] TabBar con overflow handling
- [x] APK build funcional
- [x] CodeRunner refactor (unificado con cancelación)
- [ ] Panel de búsqueda en archivos
- [ ] AI Agent integrado
- [ ] Refactor EditorController (extraer lógica de main.dart)
- [ ] Compilación C/C++ on-device real
- [ ] Pubspec editor visual

## Autor

**Leoshi** — Estudiante de Ingeniería · UPTEC-MS
