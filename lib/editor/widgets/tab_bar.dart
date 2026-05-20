import 'package:flutter/material.dart';
import '../models/tab_manager.dart';

/// Barra de pestañas del editor.
///
/// Muestra tabs scrollable horizontalmente con:
/// - Indicador de activo (borde inferior azul)
/// - Indicador de modificado (punto rojo)
/// - Indicador de pin (icono 📌)
/// - Botón cerrar (X)
/// - Nombre del archivo con extensión
class EditorTabBar extends StatelessWidget {
  final TabManager tabManager;
  final void Function(int index) onTabSelected;
  final void Function(int index) onTabClosed;
  final void Function(int index) onTabPinToggle;
  final bool isDark;

  const EditorTabBar({
    super.key,
    required this.tabManager,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabPinToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!tabManager.hasTabs) {
      return const SizedBox.shrink(); // No mostrar si no hay tabs
    }

    final bgColor = isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    final tabBg = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8);
    final activeTabBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
    final mutedColor = isDark ? const Color(0xFF858585) : const Color(0xFF999999);

    return Container(
      height: 36,
      color: bgColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabManager.tabs.length,
        itemBuilder: (context, index) {
          final tab = tabManager.tabs[index];
          final isActive = index == tabManager.activeIndex;

          return _TabItem(
            name: tab.name,
            extension: tab.extension,
            isActive: isActive,
            isDirty: tab.isDirty,
            isPinned: tab.isPinned,
            isDark: isDark,
            tabBg: isActive ? activeTabBg : tabBg,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: () => onTabSelected(index),
            onClose: () => onTabClosed(index),
            onPin: () => onTabPinToggle(index),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String name;
  final String extension;
  final bool isActive;
  final bool isDirty;
  final bool isPinned;
  final bool isDark;
  final Color tabBg;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onPin;

  const _TabItem({
    required this.name,
    required this.extension,
    required this.isActive,
    required this.isDirty,
    required this.isPinned,
    required this.isDark,
    required this.tabBg,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
    required this.onClose,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: _showContextMenu, // Context menu
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160, minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: tabBg,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF569CD6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin indicator
            if (isPinned)
              GestureDetector(
                onTap: onPin,
                child: Icon(
                  Icons.push_pin,
                  size: 12,
                  color: const Color(0xFF569CD6),
                ),
              ),

            // Modified indicator (punto rojo)
            if (isDirty)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF14C4C),
                ),
              ),

            // File name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isActive ? textColor : mutedColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Close button
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: mutedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu() {
    // Mostrar menu contextual (se implementa desde el padre)
    onTap(); // por ahora solo selecciona
  }
}