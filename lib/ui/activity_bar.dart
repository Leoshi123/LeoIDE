import 'package:flutter/material.dart';
import 'layout_controller.dart';

/// Barra de actividad vertical (estilo VS Code).
///
/// Renderiza iconos para: Explorador, Buscar, AI Agent, Configuración.
/// Usa un indicator izquierdo (barra de 2px) para el elemento activo.
/// La pestaña activa se alterna con [LayoutController.toggleTab].
class ActivityBar extends StatelessWidget {
  final SidebarTab activeTab;
  final bool isDark;
  final ValueChanged<SidebarTab> onTabSelected;

  const ActivityBar({
    super.key,
    required this.activeTab,
    required this.isDark,
    required this.onTabSelected,
  });

  Color get _bg => isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8);
  Color get _activeColor =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E1E);
  Color get _inactiveColor =>
      isDark ? const Color(0xFF858585) : const Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      color: _bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _ActivityIcon(
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder,
            isActive: activeTab == SidebarTab.explorer,
            activeColor: _activeColor,
            inactiveColor: _inactiveColor,
            tooltip: 'Explorador de archivos',
            onTap: () => onTabSelected(SidebarTab.explorer),
          ),
          const SizedBox(height: 4),
          _ActivityIcon(
            icon: Icons.search,
            activeIcon: Icons.search,
            isActive: activeTab == SidebarTab.search,
            activeColor: _activeColor,
            inactiveColor: _inactiveColor,
            tooltip: 'Buscar en archivos',
            onTap: () => onTabSelected(SidebarTab.search),
          ),
          const SizedBox(height: 4),
          _ActivityIcon(
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome,
            isActive: activeTab == SidebarTab.agent,
            activeColor: _activeColor,
            inactiveColor: _inactiveColor,
            tooltip: 'AI Agent',
            onTap: () => onTabSelected(SidebarTab.agent),
          ),
          const Spacer(),
          _ActivityIcon(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            isActive: activeTab == SidebarTab.settings,
            activeColor: _activeColor,
            inactiveColor: _inactiveColor,
            tooltip: 'Configuración',
            onTap: () => onTabSelected(SidebarTab.settings),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActivityIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          // Indicador izquierdo de elemento activo
          if (isActive)
            Positioned(
              left: 0,
              top: 6,
              bottom: 6,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          // Icono
          Center(
            child: Tooltip(
              message: tooltip,
              preferBelow: false,
              child: IconButton(
                icon: Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
                onPressed: onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                splashRadius: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
