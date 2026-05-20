import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' as io;

/// Modelo de una pestaña abierta en el editor.
class EditorTab {
  /// Identificador único (filename).
  final String id;

  /// Nombre del archivo para mostrar en la pestaña.
  final String name;

  /// Contenido actual del archivo.
  String content;

  /// Extensión del archivo (.dart, .py, etc).
  final String extension;

  /// Si el archivo tiene cambios sin guardar.
  bool isDirty;

  /// Si la pestaña está fija (pin).
  bool isPinned;

  EditorTab({
    required this.id,
    required this.name,
    required this.content,
    required this.extension,
    this.isDirty = false,
    this.isPinned = false,
  });

  /// Crea una pestaña desde un archivo del FileManager.
  factory EditorTab.fromFile(String fileName, String content) {
    final ext = _getExtension(fileName);
    return EditorTab(
      id: fileName,
      name: fileName,
      content: content,
      extension: ext,
    );
  }

  static String _getExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot >= 0 ? fileName.substring(dot) : '.txt';
  }

  /// Copia con nuevos valores.
  EditorTab copyWith({
    String? content,
    bool? isDirty,
    bool? isPinned,
  }) {
    return EditorTab(
      id: id,
      name: name,
      content: content ?? this.content,
      extension: extension,
      isDirty: isDirty ?? this.isDirty,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Serializa a JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'extension': extension,
        'isDirty': isDirty,
        'isPinned': isPinned,
      };

  /// Crea desde JSON.
  factory EditorTab.fromJson(Map<String, dynamic> json) => EditorTab(
        id: json['id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        extension: json['extension'] as String,
        isDirty: json['isDirty'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
      );
}

/// Gestor de pestañas del editor.
///
/// Maneja abrir, cerrar, cambiar y reordenar pestañas.
/// Mantiene estado de la pestaña activa.
class TabManager {
  /// Lista de pestañas abiertas (pinned primero, luego las normales).
  final List<EditorTab> tabs = [];

  /// Índice de la pestaña activa (-1 si no hay ninguna).
  int activeIndex = -1;

  /// Retorna la pestaña activa o null.
  EditorTab? get activeTab => 
      (activeIndex >= 0 && activeIndex < tabs.length) 
          ? tabs[activeIndex] 
          : null;

  /// Retorna true si hay pestañas abiertas.
  bool get hasTabs => tabs.isNotEmpty;

  /// Cantidad de pestañas.
  int get count => tabs.length;

  /// Cantidad de pestañas con cambios sin guardar.
  int get dirtyCount => tabs.where((t) => t.isDirty).length;

  /// Abre un archivo en nueva pestaña o enfoca si ya existe.
  /// Retorna el índice de la pestaña (activa o abierta).
  int openFile(String fileName, String content) {
    // Buscar si ya está abierta
    final existingIndex = tabs.indexWhere((t) => t.id == fileName);
    if (existingIndex != -1) {
      // Ya existe → enfocar
      activeIndex = existingIndex;
      return existingIndex;
    }

    // Nueva pestaña
    final newTab = EditorTab.fromFile(fileName, content);
    tabs.add(newTab);
    activeIndex = tabs.length - 1;
    return activeIndex;
  }

  /// Cierra una pestaña por índice.
  /// Si es la activa, enfoca la anterior o la siguiente.
  void closeTab(int index) {
    if (index < 0 || index >= tabs.length) return;

    final wasActive = index == activeIndex;
    tabs.removeAt(index);

    // Ajustar índice activo
    if (tabs.isEmpty) {
      activeIndex = -1;
    } else if (wasActive) {
      // Enfocar pestaña anterior o la siguiente
      if (index >= tabs.length) {
        activeIndex = tabs.length - 1; // última
      } else {
        activeIndex = index; // siguiente a la cerrada
      }
    } else if (index < activeIndex) {
      // Se cerró una antes de la activa
      activeIndex--;
    }
  }

  /// Cierra todas las pestañas no fijadas.
  void closeAllUnpinned() {
    tabs.removeWhere((t) => !t.isPinned);
    if (tabs.isEmpty) {
      activeIndex = -1;
    } else if (activeIndex >= tabs.length) {
      activeIndex = tabs.length - 1;
    }
  }

  /// Cambia la pestaña activa.
  void setActive(int index) {
    if (index >= 0 && index < tabs.length) {
      activeIndex = index;
    }
  }

  /// Marca una pestaña como modificada (isDirty).
  void markDirty(int index, bool dirty) {
    if (index >= 0 && index < tabs.length) {
      tabs[index] = tabs[index].copyWith(isDirty: dirty);
    }
  }

  /// Actualiza el contenido de una pestaña.
  void updateContent(int index, String content) {
    if (index >= 0 && index < tabs.length) {
      final wasDirty = tabs[index].isDirty;
      tabs[index] = tabs[index].copyWith(content: content);
      // Solo marcar dirty si realmente cambió de limpio a modificado
      if (!wasDirty && content != tabs[index].content) {
        tabs[index] = tabs[index].copyWith(isDirty: true);
      }
    }
  }

  /// Alterna el estado de pinned de una pestaña.
  void togglePin(int index) {
    if (index >= 0 && index < tabs.length) {
      tabs[index] = tabs[index].copyWith(isPinned: !tabs[index].isPinned);
      // Reordenar: pinned van al inicio
      _reorderTabs();
    }
  }

  /// Reordena para que pinned estén primero.
  void _reorderTabs() {
    tabs.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
  }

  /// Obtiene una pestaña por índice.
  EditorTab? getTab(int index) => 
      (index >= 0 && index < tabs.length) ? tabs[index] : null;

  /// Busca pestaña por nombre.
  EditorTab? findByName(String name) {
    for (final tab in tabs) {
      if (tab.name == name) return tab;
    }
    return null;
  }

  /// Limpia todas las pestañas.
  void closeAll() {
    tabs.clear();
    activeIndex = -1;
  }

  /// Serializa todo el estado a JSON.
  Map<String, dynamic> toJson() => {
        'tabs': tabs.map((t) => t.toJson()).toList(),
        'activeIndex': activeIndex,
      };

  /// Carga estado desde JSON.
  void fromJson(Map<String, dynamic> json) {
    final tabsList = json['tabs'] as List<dynamic>? ?? [];
    tabs.clear();
    for (final tabJson in tabsList) {
      tabs.add(EditorTab.fromJson(tabJson as Map<String, dynamic>));
    }
    activeIndex = json['activeIndex'] as int? ?? -1;
    // Reordenar para que pinned estén primero
    _reorderTabs();
  }

  /// Guarda estado a archivo.
  Future<void> saveToFile(String path) async {
    final file = io.File(path);
    final jsonStr = jsonEncode(toJson());
    await file.writeAsString(jsonStr);
  }

  /// Carga estado desde archivo.
  Future<void> loadFromFile(String path) async {
    final file = io.File(path);
    if (!await file.exists()) return;
    final jsonStr = await file.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    fromJson(json);
  }
}