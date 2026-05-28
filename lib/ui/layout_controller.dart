import 'package:flutter/material.dart';

/// Pestañas de la barra de actividad lateral.
enum SidebarTab { explorer, search, agent, settings }

/// Controlador de estado del layout responsive.
///
/// Maneja visibilidad de la sidebar, panel de terminal, y pestaña activa
/// de la barra de actividad. Extiende [ChangeNotifier] para usarse con
/// [ListenableBuilder] o [AnimatedBuilder].
///
/// ## Comportamiento toggle:
/// - Primero toque en icono activo → oculta sidebar
/// - Toca en icono inactivo → cambia de pestaña y muestra sidebar
class LayoutController extends ChangeNotifier {
  bool _sidebarVisible = true;
  bool _terminalVisible = false;
  double _terminalHeight = 200;
  SidebarTab _activeTab = SidebarTab.explorer;

  // ── Getters ──

  bool get sidebarVisible => _sidebarVisible;
  bool get terminalVisible => _terminalVisible;
  double get terminalHeight => _terminalHeight;
  SidebarTab get activeTab => _activeTab;

  // ── Sidebar ──

  void toggleSidebar() {
    _sidebarVisible = !_sidebarVisible;
    notifyListeners();
  }

  void showSidebar() {
    _sidebarVisible = true;
    notifyListeners();
  }

  void hideSidebar() {
    _sidebarVisible = false;
    notifyListeners();
  }

  /// Cambia de pestaña activa con toggle.
  ///
  /// Si la pestaña ya está activa y la sidebar visible → la oculta.
  /// Si la pestaña está inactiva → la activa y muestra la sidebar.
  void toggleTab(SidebarTab tab) {
    if (_activeTab == tab && _sidebarVisible) {
      _sidebarVisible = false;
    } else {
      _activeTab = tab;
      _sidebarVisible = true;
    }
    notifyListeners();
  }

  void setActiveTab(SidebarTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  // ── Terminal ──

  void toggleTerminal() {
    _terminalVisible = !_terminalVisible;
    notifyListeners();
  }

  void showTerminal() {
    _terminalVisible = true;
    notifyListeners();
  }

  void hideTerminal() {
    _terminalVisible = false;
    notifyListeners();
  }

  void setTerminalHeight(double height) {
    _terminalHeight = height;
    notifyListeners();
  }
}
