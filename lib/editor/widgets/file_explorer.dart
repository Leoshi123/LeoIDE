import 'package:flutter/material.dart';
import '../engine/file_manager.dart';

/// Panel de exploración de archivos con árbol de directorios.
///
/// Muestra la estructura completa del proyecto LeoIDE con
/// nodos colapsables por directorio.
class FileExplorer extends StatefulWidget {
  final FileManager fileManager;
  final void Function(String fileName) onFileTap;
  final void Function(String fileName) onFileDelete;
  final bool isDark;

  const FileExplorer({
    super.key,
    required this.fileManager,
    required this.onFileTap,
    required this.onFileDelete,
    required this.isDark,
  });

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  /// Nodos expandidos (paths relativos de directorios).
  final Set<String> _expandedDirs = {};

  /// Lista plana de items con profundidad.
  List<_FlatItem> _items = [];

  @override
  void initState() {
    super.initState();
    _rebuildTree();
  }

  void _rebuildTree() {
    final files = widget.fileManager.listFilesRecursive();
    _items = _buildFlatList(files, '', 0);
  }

  /// Construye lista plana desde paths relativos.
  List<_FlatItem> _buildFlatList(List<String> paths, String prefix, int depth) {
    final result = <_FlatItem>[];
    final dirs = <String>{};
    final filesHere = <String>[];

    // Separar archivos y directorios
    for (final path in paths) {
      final rest = path.startsWith(prefix) ? path.substring(prefix.length) : path;
      if (rest.contains('/')) {
        final dirName = rest.split('/').first;
        if (dirName.isNotEmpty) dirs.add(dirName);
      } else if (rest.isNotEmpty) {
        filesHere.add(path);
      }
    }

    final sortedDirs = dirs.toList()..sort();
    final sortedFiles = filesHere..sort();

    // Directorios primero
    for (final dir in sortedDirs) {
      final fullPrefix = '$prefix$dir/';
      final isExpanded = _expandedDirs.contains(fullPrefix);

      result.add(_FlatItem(
        name: dir,
        path: fullPrefix,
        depth: depth,
        isDirectory: true,
        isExpanded: isExpanded,
      ));

      if (isExpanded) {
        result.addAll(_buildFlatList(paths, fullPrefix, depth + 1));
      }
    }

    // Archivos después
    for (final file in sortedFiles) {
      result.add(_FlatItem(
        name: file.startsWith(prefix) ? file.substring(prefix.length) : file,
        path: file,
        depth: depth,
        isDirectory: false,
        isExpanded: false,
      ));
    }

    return result;
  }

  void _toggleDir(String path) {
    setState(() {
      if (_expandedDirs.contains(path)) {
        _expandedDirs.remove(path);
      } else {
        _expandedDirs.add(path);
      }
      _rebuildTree();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    final textColor = widget.isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
    final mutedColor = widget.isDark ? const Color(0xFF858585) : const Color(0xFF999999);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Cabecera
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.folder, size: 16, color: mutedColor),
                const SizedBox(width: 6),
                Text(
                  'EXPLORADOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedDirs.clear();
                      _rebuildTree();
                    });
                  },
                  child: Icon(Icons.refresh, size: 14, color: mutedColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Árbol
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'Vacío — guarda archivos\npara verlos aquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor,
                        height: 1.5,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) => _buildItem(
                      _items[i],
                      textColor,
                      mutedColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_FlatItem item, Color textColor, Color mutedColor) {
    final indent = 12.0 + item.depth * 16.0;

    if (item.isDirectory) {
      return GestureDetector(
        onTap: () => _toggleDir(item.path),
        child: Container(
          padding: EdgeInsets.only(left: indent, right: 8),
          height: 28,
          child: Row(
            children: [
              Icon(
                item.isExpanded ? Icons.folder_open : Icons.folder,
                size: 16,
                color: const Color(0xFF569CD6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                item.isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: mutedColor,
              ),
            ],
          ),
        ),
      );
    }

    // Archivo
    return GestureDetector(
      onTap: () => widget.onFileTap(item.path),
      onLongPress: () => _showContextMenu(item.path),
      child: Container(
        padding: EdgeInsets.only(left: indent, right: 8),
        height: 24,
        child: Row(
          children: [
            Icon(
              _iconForFile(item.path),
              size: 14,
              color: const Color(0xFF569CD6),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF0F0F0),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new, size: 20),
              title: const Text('Abrir'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onFileTap(fileName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(fileName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Eliminar "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onFileDelete(fileName);
              setState(() => _rebuildTree());
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  IconData _iconForFile(String path) {
    final ext = FileManager.extensionOf(path);
    switch (ext) {
      case '.dart':
        return Icons.code;
      case '.py':
        return Icons.code;
      case '.c':
      case '.cpp':
      case '.cc':
      case '.cxx':
        return Icons.memory;
      case '.js':
      case '.mjs':
        return Icons.javascript;
      case '.php':
        return Icons.code;
      case '.html':
      case '.htm':
        return Icons.web;
      case '.css':
        return Icons.palette;
      case '.json':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}

/// Item plano en la lista del árbol.
class _FlatItem {
  final String name;
  final String path;
  final int depth;
  final bool isDirectory;
  final bool isExpanded;

  const _FlatItem({
    required this.name,
    required this.path,
    required this.depth,
    required this.isDirectory,
    required this.isExpanded,
  });
}
