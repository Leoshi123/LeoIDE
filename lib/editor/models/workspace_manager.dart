import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Gestiona el directorio de trabajo (workspace) de LeoIDE.
///
/// Permite al usuario seleccionar una carpeta usando el selector nativo
/// del sistema (file_picker) y persiste la elección entre sesiones.
///
/// El workspace se guarda en un archivo JSON dentro del directorio
/// de datos de la aplicación (path_provider o similar), no en el
/// workspace mismo, para evitar contaminar los proyectos del usuario.
class WorkspaceManager {
  /// Ruta completa al directorio de trabajo seleccionado.
  String? _workspacePath;

  /// Ruta del archivo de configuración donde se persiste el workspace.
  final String configPath;

  WorkspaceManager({required this.configPath}) {
    _load();
  }

  /// Ruta del workspace actual (puede ser null si no se ha seleccionado).
  String? get workspacePath => _workspacePath;

  /// Nombre de la carpeta del workspace (para mostrar en UI).
  String? get workspaceName {
    if (_workspacePath == null) return null;
    final segments = _workspacePath!.split(Platform.pathSeparator);
    return segments.isNotEmpty ? segments.last : _workspacePath;
  }

  /// Carga la ruta guardada del workspace.
  void _load() {
    try {
      final file = File(configPath);
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final savedPath = data['workspacePath'] as String?;
      if (savedPath != null && Directory(savedPath).existsSync()) {
        _workspacePath = savedPath;
      }
    } catch (_) {
      // Si el archivo está corrupto, se ignora.
    }
  }

  /// Persiste la ruta del workspace a disco.
  void _save() {
    try {
      final dir = Directory(configPath).parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File(configPath).writeAsStringSync(
        jsonEncode({'workspacePath': _workspacePath}),
      );
    } catch (_) {
      // Silencioso — no crítico.
    }
  }

  /// Abre el selector nativo de directorios.
  ///
  /// Retorna true si el usuario seleccionó un directorio válido.
  Future<bool> selectWorkspace(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccionar carpeta de trabajo',
      );

      if (result != null) {
        _workspacePath = result;
        _save();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workspace cambiado a: $workspaceName'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selección de carpeta cancelada')),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar carpeta: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }

  /// Limpia la selección de workspace (vuelve al default).
  void reset() {
    _workspacePath = null;
    _save();
  }

  /// Retorna la ruta efectiva: workspace seleccionado o un default.
  String effectivePath(String defaultPath) => _workspacePath ?? defaultPath;
}
