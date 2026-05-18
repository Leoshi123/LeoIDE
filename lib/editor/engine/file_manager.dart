import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Gestiona la persistencia de archivos en disco.
///
/// Proporciona un espacio de trabajo aislado en el sistema
/// de archivos con un directorio raíz dedicado a LeoIDE.
class FileManager {
  /// Directorio raíz del proyecto LeoIDE.
  final String projectRoot;

  /// Lista de archivos recientes (nombres, ordenados del más reciente al más viejo).
  List<String> recentFiles = [];

  FileManager({required this.projectRoot}) {
    _ensureDirectories();
    _loadRecent();
  }

  /// Crea el directorio raíz y el archivo de recientes si no existen.
  void _ensureDirectories() {
    final dir = Directory(projectRoot);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Ruta al archivo de metadatos (recientes).
  String get _metaPath => '$projectRoot/.leoide_meta.json';

  /// Guarda la lista de recientes en disco.
  void _saveRecent() {
    try {
      final data = jsonEncode({'recentFiles': recentFiles});
      File(_metaPath).writeAsStringSync(data);
    } catch (_) {
      // Ignorar errores de metadata
    }
  }

  /// Carga la lista de recientes desde disco.
  void _loadRecent() {
    try {
      final file = File(_metaPath);
      if (file.existsSync()) {
        final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        recentFiles = List<String>.from(data['recentFiles'] as List? ?? []);
      }
    } catch (_) {
      recentFiles = [];
    }
  }

  /// Agrega un archivo a la lista de recientes.
  void _addToRecent(String fileName) {
    recentFiles.remove(fileName);
    recentFiles.insert(0, fileName);
    if (recentFiles.length > 20) {
      recentFiles = recentFiles.sublist(0, 20);
    }
    _saveRecent();
  }

  /// Ruta completa de un archivo en el proyecto.
  String filePath(String fileName) => '$projectRoot/$fileName';

  /// Guarda contenido en un archivo.
  ///
  /// Crea directorios intermedios si es necesario.
  Future<void> saveFile(String fileName, String content) async {
    final file = File(filePath(fileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    _addToRecent(fileName);
  }

  /// Lee el contenido de un archivo.
  Future<String> loadFile(String fileName) async {
    final file = File(filePath(fileName));
    if (!await file.exists()) {
      throw FileSystemException('Archivo no encontrado', file.path);
    }
    _addToRecent(fileName);
    return await file.readAsString();
  }

  /// Lista archivos en el directorio raíz (solo 1 nivel).
  List<String> listFiles() {
    try {
      final dir = Directory(projectRoot);
      if (!dir.existsSync()) return [];

      return dir.listSync().whereType<File>().map((f) => f.path.split('/').last).toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }

  /// Lista archivos de forma recursiva (ordenados alfabéticamente).
  List<String> listFilesRecursive() {
    final files = <String>[];
    try {
      final dir = Directory(projectRoot);
      if (!dir.existsSync()) return files;

      _walkDir(dir, '', files);
      files.sort();
    } catch (_) {
      // Ignorar errores
    }
    return files;
  }

  void _walkDir(Directory dir, String prefix, List<String> result) {
    try {
      for (final entity in dir.listSync()) {
        if (entity is File) {
          result.add('$prefix${entity.path.split('/').last}');
        } else if (entity is Directory) {
          final name = entity.path.split('/').last;
          if (!name.startsWith('.')) {
            _walkDir(entity, '$prefix$name/', result);
          }
        }
      }
    } catch (_) {
      // Ignorar errores de permisos
    }
  }

  /// Elimina un archivo.
  Future<void> deleteFile(String fileName) async {
    final file = File(filePath(fileName));
    if (await file.exists()) {
      await file.delete();
      recentFiles.remove(fileName);
      _saveRecent();
    }
  }

  /// Obtiene la extensión de un nombre de archivo.
  static String extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot >= 0 ? fileName.substring(dot).toLowerCase() : '.txt';
  }
}
