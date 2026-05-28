import 'package:flutter/material.dart';
import '../editor/widgets/file_explorer.dart';
import '../editor/models/workspace_manager.dart';
import '../editor/engine/file_manager.dart';
import 'layout_controller.dart';

/// Panel lateral que muestra el contenido según la pestaña activa.
///
/// - [SidebarTab.explorer]: explorador de archivos con cabecera de workspace
/// - [SidebarTab.search]: buscador (placeholder, próximamente)
/// - [SidebarTab.agent]: AI Agent (placeholder, próximamente)
/// - [SidebarTab.settings]: configuración (placeholder, próximamente)
class SidebarPanel extends StatelessWidget {
  final SidebarTab activeTab;
  final bool isDark;
  final FileManager fileManager;
  final WorkspaceManager workspaceManager;
  final void Function(String) onFileTap;
  final void Function(String) onFileDelete;
  final VoidCallback onChangeWorkspace;

  const SidebarPanel({
    super.key,
    required this.activeTab,
    required this.isDark,
    required this.fileManager,
    required this.workspaceManager,
    required this.onFileTap,
    required this.onFileDelete,
    required this.onChangeWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    switch (activeTab) {
      case SidebarTab.explorer:
        return _buildExplorer();
      case SidebarTab.search:
        return _buildPlaceholder('Buscar', Icons.search);
      case SidebarTab.agent:
        return _buildPlaceholder('AI Agent', Icons.auto_awesome);
      case SidebarTab.settings:
        return _buildPlaceholder('Configuración', Icons.settings);
    }
  }

  Widget _buildExplorer() {
    final bg = isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    final headerColor =
        isDark ? const Color(0xFF858585) : const Color(0xFF616161);

    return Container(
      color: bg,
      child: Column(
        children: [
          // Cabecera con nombre de workspace
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPLORADOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: headerColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF4FC1FF)
                          : const Color(0xFF0066B8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        workspaceManager.workspaceName ?? 'LeoIDE',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 14),
                      tooltip: 'Cambiar workspace',
                      onPressed: onChangeWorkspace,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de archivos
          Expanded(
            child: FileExplorer(
              fileManager: fileManager,
              isDark: isDark,
              onFileTap: onFileTap,
              onFileDelete: onFileDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String label, IconData icon) {
    final bg = isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    final textColor =
        isDark ? const Color(0xFF858585) : const Color(0xFF999999);

    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: textColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Próximamente',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
