import 'package:flutter/material.dart';
import '../models/tab_manager.dart';

/// Barra de pestañas del editor con soporte responsive.
///
/// Características:
/// - Scroll horizontal infinito con auto-scroll al tab activo
/// - Overflow: cuando hay más tabs del espacio visible, muestra botones
///   de scroll lateral y un menú desplegable con la lista completa
/// - Indicador de activo (borde inferior azul)
/// - Indicador de modificado (punto rojo) y pin (icono 📌)
/// - Botón cerrar (X) en cada tab
class EditorTabBar extends StatefulWidget {
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
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {
  final ScrollController _scrollController = ScrollController();
  int _previousActiveIndex = -1;
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(EditorTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentActive = widget.tabManager.activeIndex;
    if (currentActive != _previousActiveIndex && currentActive >= 0) {
      _scrollToActive(currentActive);
    }
    _previousActiveIndex = currentActive;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detectar overflow comparando scroll extent con content extent
    if (!_scrollController.hasClients) return;
    final hasOverflow =
        _scrollController.position.maxScrollExtent > 0;
    if (hasOverflow != _hasOverflow) {
      setState(() => _hasOverflow = hasOverflow);
    }
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients) {
      // Si el scroll controller no está listo, esperar al next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActive(index);
      });
      return;
    }
    // Estimar posición: cada tab es ~140px con minWidth 100 y maxWidth 160
    final tabWidth = 140.0;
    final targetOffset = index * tabWidth - 30.0; // ligero offset para centrar
    final maxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tabManager.hasTabs) {
      return const SizedBox.shrink();
    }

    _previousActiveIndex = widget.tabManager.activeIndex;

    final bgColor =
        widget.isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    final iconColor =
        widget.isDark ? const Color(0xFF858585) : const Color(0xFF666666);

    final tabList = Expanded(
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabManager.tabs.length,
        itemBuilder: (context, index) => _buildTab(index),
      ),
    );

    return Container(
      height: 36,
      color: bgColor,
      child: _hasOverflow
          ? Row(
              children: [
                // Scroll izquierdo
                _ScrollArrow(
                  icon: Icons.chevron_left,
                  color: iconColor,
                  onTap: () => _scrollBy(-100.0),
                ),
                tabList,
                // Menú desplegable de tabs overflow
                _OverflowMenu(
                  tabManager: widget.tabManager,
                  isDark: widget.isDark,
                  onTabSelected: widget.onTabSelected,
                  onTabClosed: widget.onTabClosed,
                ),
                // Scroll derecho
                _ScrollArrow(
                  icon: Icons.chevron_right,
                  color: iconColor,
                  onTap: () => _scrollBy(100.0),
                ),
              ],
            )
          : tabList,
    );
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final target = (current + offset)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  Widget _buildTab(int index) {
    final tab = widget.tabManager.tabs[index];
    final isActive = index == widget.tabManager.activeIndex;

    final tabBg = widget.isDark
        ? (isActive ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D))
        : (isActive ? const Color(0xFFFFFFFF) : const Color(0xFFE8E8E8));
    final textColor =
        widget.isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
    final mutedColor =
        widget.isDark ? const Color(0xFF858585) : const Color(0xFF999999);

    return _TabItem(
      name: tab.name,
      extension: tab.extension,
      isActive: isActive,
      isDirty: tab.isDirty,
      isPinned: tab.isPinned,
      isDark: widget.isDark,
      tabBg: tabBg,
      textColor: textColor,
      mutedColor: mutedColor,
      onTap: () => widget.onTabSelected(index),
      onClose: () => widget.onTabClosed(index),
      onPin: () => widget.onTabPinToggle(index),
    );
  }
}

/// Botón de flecha para scroll lateral.
class _ScrollArrow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScrollArrow({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Menú desplegable para tabs en overflow.
class _OverflowMenu extends StatelessWidget {
  final TabManager tabManager;
  final bool isDark;
  final void Function(int index) onTabSelected;
  final void Function(int index) onTabClosed;

  const _OverflowMenu({
    required this.tabManager,
    required this.isDark,
    required this.onTabSelected,
    required this.onTabClosed,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? const Color(0xFF858585) : const Color(0xFF666666);

    return PopupMenuButton<int>(
      icon: Icon(Icons.arrow_drop_down, size: 18, color: iconColor),
      tooltip: 'Tabs abiertos',
      onSelected: onTabSelected,
      itemBuilder: (_) => tabManager.tabs.asMap().entries.map((entry) {
        final i = entry.key;
        final tab = entry.value;
        final isActive = i == tabManager.activeIndex;

        return PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              // Indicador de activo
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF569CD6),
                  ),
                )
              else
                const SizedBox(width: 12),
              // Indicador de modificado
              if (tab.isDirty)
                const Text('● ', style: TextStyle(color: Color(0xFFF14C4C), fontSize: 10)),
              // Nombre
              Expanded(
                child: Text(
                  tab.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: isActive
                        ? const Color(0xFF569CD6)
                        : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333)),
                  ),
                ),
              ),
              // Botón cerrar
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // cerrar popup primero
                  onTabClosed(i);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 14,
                      color: isDark ? const Color(0xFF858585) : const Color(0xFF999999)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Tab Item (sin cambios semánticos) ──

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
      onLongPress: _showContextMenu,
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
            if (isPinned)
              GestureDetector(
                onTap: onPin,
                child: Icon(
                  Icons.push_pin,
                  size: 12,
                  color: const Color(0xFF569CD6),
                ),
              ),
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
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14, color: mutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu() {
    onTap();
  }
}
