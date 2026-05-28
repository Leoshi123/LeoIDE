import 'package:flutter/material.dart';
import 'layout_controller.dart';
import 'activity_bar.dart';

/// Shell principal del editor con layout tipo VS Code.
///
/// Orquesta 4 zonas principales:
/// 1. [ActivityBar] — barra de iconos vertical (izquierda)
/// 2. Sidebar — panel lateral colapsable (explorador, búsqueda, etc.)
/// 3. Área central — tabs + editor + terminal + status bar
///
/// ## Responsive
/// - Compact (< 600px): sidebar de 220px
/// - Normal (>= 600px): sidebar de 260px
///
/// ## Rendimiento
/// El [editorContent] se envuelve en [RepaintBoundary] para evitar
/// repintados cuando se togglea la sidebar o terminal.
class EditorShell extends StatelessWidget {
  final LayoutController layoutController;
  final bool isDark;

  /// Widget del panel lateral (cambia según pestaña activa).
  final Widget sidebarContent;

  /// Widget del editor (Stack con gutter + TextField + overlays).
  final Widget editorContent;

  /// Widget del panel de terminal (logs + controles).
  final Widget terminalContent;

  /// Barra de pestañas del editor.
  final Widget? tabBar;

  /// Barra de diagnósticos LSP (errores/warnings).
  final Widget? diagnosticsBar;

  /// Barra de estado inferior (cursor, encoding, lenguaje).
  final Widget? statusBar;

  /// Barra de herramientas superior (AppBar-like con nombre archivo + acciones).
  final Widget? toolbar;

  /// Barra de símbolos (inferior).
  final Widget? bottomBar;

  const EditorShell({
    super.key,
    required this.layoutController,
    required this.isDark,
    required this.sidebarContent,
    required this.editorContent,
    required this.terminalContent,
    this.toolbar,
    this.tabBar,
    this.diagnosticsBar,
    this.statusBar,
    this.bottomBar,
  });

  Color get _bg => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. ACTIVITY BAR ──
            ActivityBar(
              activeTab: layoutController.activeTab,
              isDark: isDark,
              onTabSelected: layoutController.toggleTab,
            ),
            _verticalDivider(),

            // ── 2. SIDEBAR ──
            ListenableBuilder(
              listenable: layoutController,
              builder: (context, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: layoutController.sidebarVisible
                    ? (isCompact ? 220 : 260)
                    : 0,
                child: layoutController.sidebarVisible
                    ? sidebarContent
                    : const SizedBox.shrink(),
              ),
            ),
            if (layoutController.sidebarVisible) _verticalDivider(),

            // ── 3. ÁREA CENTRAL ──
            Expanded(
              child: Column(
                children: [
                  // Barra de herramientas (AppBar)
                  if (toolbar != null) toolbar!,

                  // Barra de pestañas
                  if (tabBar != null) tabBar!,

                  // Editor (envuelto en RepaintBoundary)
                  Expanded(child: RepaintBoundary(child: editorContent)),

                  // Barra de diagnósticos
                  if (diagnosticsBar != null) diagnosticsBar!,

                  // Terminal (colapsable animado)
                  _buildTerminalArea(),

                  // Barra de estado
                  if (statusBar != null) statusBar!,

                  // Barra de símbolos
                  if (bottomBar != null) bottomBar!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel de terminal con animación de altura.
  Widget _buildTerminalArea() {
    return ListenableBuilder(
      listenable: layoutController,
      builder: (context, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: layoutController.terminalVisible
            ? layoutController.terminalHeight
            : 0,
        child: layoutController.terminalVisible
            ? terminalContent
            : const SizedBox.shrink(),
      ),
    );
  }

  /// Divisor vertical de 1px con color de borde.
  Widget _verticalDivider() {
    return Container(
      width: 1,
      color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0),
    );
  }
}
