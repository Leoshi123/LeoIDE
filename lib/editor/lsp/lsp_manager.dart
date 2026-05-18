import 'dart:io';
import 'lsp_client.dart';
import 'models/lsp_types.dart';

/// Orquestador de servidores LSP.
///
/// Decide qué servidor ejecutar según el lenguaje y gestiona
/// el ciclo de vida (start/stop por cambio de archivo).
class LspManager {
  LspClient? _currentClient;

  /// Servidor actualmente activo.
  LspClient? get current => _currentClient;
  bool get isActive => _currentClient != null && _currentClient!.isReady;

  /// Inicia el servidor LSP para una extensión de archivo.
  Future<LspClient?> startForExtension(
    String extension,
    String filePath,
  ) async {
    // Detener servidor anterior si existe
    await stop();

    final config = _getServerConfig(extension);
    if (config == null) return null;

    final client = LspClient(
      executable: config.executable,
      args: config.args,
      languageId: config.languageId,
      filePath: filePath,
    );

    try {
      await client.start();
      _currentClient = client;
      return client;
    } catch (e) {
      // Servidor LSP no disponible para este lenguaje
      return null;
    }
  }

  /// Abre o actualiza el documento actual.
  Future<void> openOrUpdateDocument(String text) async {
    if (_currentClient == null) return;
    if (!_currentClient!.isReady) {
      await _currentClient!.ready;
    }
    await _currentClient!.openDocument(text);
  }

  Future<void> updateDocument(String text) async {
    await _currentClient?.updateDocument(text);
  }

  /// Solicita completaciones al servidor LSP activo.
  Future<List<LspCompletionItem>> requestCompletions(
      int line, int character) async {
    if (_currentClient == null || !_currentClient!.isReady) return [];
    return _currentClient!.requestCompletions(line, character);
  }

  /// Detiene el servidor actual.
  Future<void> stop() async {
    if (_currentClient != null) {
      await _currentClient!.stop();
      _currentClient!.dispose();
      _currentClient = null;
    }
  }

  /// Limpia todo.
  void dispose() {
    stop();
  }

  /// Configuración de servidor LSP por extensión.
  _LspServerConfig? _getServerConfig(String extension) {
    switch (extension) {
      case '.dart':
        return const _LspServerConfig(
          executable: 'dart',
          args: ['/opt/dart-sdk/bin/snapshots/analysis_server.dart.snapshot', '--lsp'],
          languageId: 'dart',
        );
      case '.c':
      case '.cpp':
      case '.cc':
      case '.cxx':
        if (_isBinaryAvailable('clangd')) {
          return const _LspServerConfig(
            executable: 'clangd',
            args: ['--background-index'],
            languageId: 'cpp',
          );
        }
        return null;
      case '.py':
        if (_isBinaryAvailable('pylsp')) {
          return const _LspServerConfig(
            executable: 'pylsp',
            args: [],
            languageId: 'python',
          );
        }
        if (_isBinaryAvailable('pyright-langserver')) {
          return const _LspServerConfig(
            executable: 'pyright-langserver',
            args: ['--stdio'],
            languageId: 'python',
          );
        }
        return null;
      case '.js':
      case '.mjs':
        if (_isBinaryAvailable('typescript-language-server')) {
          return const _LspServerConfig(
            executable: 'typescript-language-server',
            args: ['--stdio'],
            languageId: 'javascript',
          );
        }
        return null;
      case '.php':
        if (_isBinaryAvailable('intelephense')) {
          return const _LspServerConfig(
            executable: 'intelephense',
            args: ['--stdio'],
            languageId: 'php',
          );
        }
        return null;
      default:
        return null;
    }
  }

  /// Verifica si un binario está disponible en el sistema.
  bool _isBinaryAvailable(String name) {
    try {
      final result = Process.runSync('which', [name]);
      return result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class _LspServerConfig {
  final String executable;
  final List<String> args;
  final String languageId;

  const _LspServerConfig({
    required this.executable,
    required this.args,
    required this.languageId,
  });
}
