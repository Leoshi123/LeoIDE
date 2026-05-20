# LeoIDE ⚡

> IDE móvil personal de alto rendimiento. Compila C/C++, Python, PHP y Web nativamente en Android. Sin publicidad. Sin telemetría. Hecho para quien escribe código de verdad desde el teléfono.

**IDE móvil personalizado — alto rendimiento, compilación nativa, cero publicidad.**

LeoIDE es un entorno de desarrollo integrado para Android diseñado desde cero para
la productividad personal. Compila y ejecuta código directamente en tu dispositivo.

---

## Lenguajes Soportados

| Lenguaje   | Motor de Ejecución                  | Método                          |
|------------|-------------------------------------|---------------------------------|
| C / C++    | Android NDK + Clang (ARM64)         | Compilación a binario ELF       |
| Python     | Chaquopy / BeeWare                  | Intérprete embebido             |
| HTML/CSS/JS| WebView (V8 Engine)                 | Renderizado local               |
| PHP        | PHP-CGI embebido                    | Servidor local :8080            |

## Arquitectura

```
┌─────────────────────────────────┐
│      EDITOR CANVAS (Flutter)     │
│  Virtual Scrolling + Lexer FSM   │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│       PIECE TABLE ENGINE         │
│  Buffer Original + Buffer Add    │
│  Undo/Redo en O(1)               │
└──────┬─────────┬─────────┬──────┘
       │         │         │
       ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐
│ C/C++  │ │ Python │ │  Web   │
│ NDK    │ │Chaquopy│ │ WebView│
└───┬────┘ └───┬────┘ └───┬────┘
    │          │          │
    ▼          ▼          ▼
┌─────────────────────────────────┐
│      TERMINAL EMULATOR          │
│   STDOUT / STDERR en vivo       │
└─────────────────────────────────┘
```

### Core técnico
- **Piece Table** — edición O(1), undo infinito sin duplicar memoria
- **Virtual Viewport** — renderizado solo de líneas visibles (60 FPS)
- **FSM Lexer** — máquina de estados finitos para resaltado en tiempo real
- **Static SymTable** — autocompletado local sin latencia

## Características

- ✏️ Editor con virtual scrolling y cursor preciso
- 🎨 Resaltado de sintaxis multi-lenguaje
- ⌨️ Barra de símbolos sobre el teclado móvil
- 🏃 Compilación y ejecución local offline
- 📂 File Explorer integrado
- 🌙 Temas claro/oscuro
- 🔄 Sincronización opcional con Supabase

## Stack Tecnológico

| Capa         | Tecnología                          |
|--------------|-------------------------------------|
| UI           | Flutter (CustomPainter + Canvas)    |
| Lenguaje     | Dart                                |
| Compilación  | Android NDK + Clang (ARM64)         |
| Python       | Chaquopy (Gradle plugin)            |
| PHP          | PHP-CGI embebido                    |
| Backend (opc)| Supabase                            |

## Estado del Proyecto

```
Fase 1 ████████░░░░  Motor de texto + Cursor + Barra de símbolos
Fase 2 ░░░░░░░░░░░░  Lexer multi-lenguaje
Fase 3 ░░░░░░░░░░░░  Runners de compilación
Fase 4 ░░░░░░░░░░░░  File Explorer + Temas + Sincronización
```

## Autor

**Leoshi** — Estudiante de Ingeniería · UPTEC-MS
