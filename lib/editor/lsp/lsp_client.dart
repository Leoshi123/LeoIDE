import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models/lsp_types.dart';

/// Callback para completaciones recibidas.
typedef LspCompletionCallback = void Function(
    List<LspCompletionItem> items);

/// Callback para diagnostics/publicación de errores.
typedef LspDiagnosticsCallback = void Function(
    List<Map<String, dynamic>> diagnostics);

/// Cliente LSP ligero — comunicación JSON-RPC sobre stdio.
///
/// Gestiona el lifecycle completo:
///   start → initialize → didOpen → didChange → completion → shutdown
class LspClient {
  final String executable;
  final List<String> args;
  final Map<String, String>? environment;
  final String languageId;
  final String filePath;

  Process? _process;
  int _messageId = 0;
  int _docVersion = 0;
  bool _initialized = false;
  bool _shutdown = false;

  final Completer<void> _readyCompleter = Completer();
  final Map<int, Completer<Map<String, dynamic>?>> _pendingRequests = {};

  /// Buffer para mensajes entrantes.
  String _incomingBuffer = '';

  LspCompletionCallback? onCompletion;
  LspDiagnosticsCallback? onDiagnostics;

  LspClient({
    required this.executable,
    this.args = const [],
    this.environment,
    required this.languageId,
    required this.filePath,
    this.onCompletion,
    this.onDiagnostics,
  });

  bool get isRunning => _process != null && !_shutdown;
  bool get isReady => _initialized;

  /// Inicia el servidor LSP y envía initialize.
  Future<void> start() async {
    if (_process != null) return;

    _process = await Process.start(
      executable,
      args,
      runInShell: true,
      environment: environment,
    );

    // Leer stdout del servidor (línea por línea según Content-Length)
    _process!.stdout
        .transform(utf8.decoder)
        .listen(_onData);

    // Stderr del servidor (logs internos)
    _process!.stderr
        .transform(utf8.decoder)
        .listen((data) {
      // Servidores LSP a veces mandan logs por stderr
    });

    // Detectar si el proceso muere inesperadamente (Heartbeat pasivo)
    _process!.exitCode.then((code) {
      if (!_shutdown) {
        _initialized = false;
        _process = null;
        // In a real IDE, we could trigger an auto-restart here.
      }
    });

    // Enviar initialize
    await _initialize();
  }

  /// Envía el mensaje initialize y espera la respuesta.
  Future<void> _initialize() async {
    final caps = {
      'textDocument': {
        'completion': {
          'completionItem': {
            'snippetSupport': true,
          },
        },
      },
    };

    final result = await _sendRequest('initialize', {
      'processId': pid,
      'clientInfo': {'name': 'LeoIDE', 'version': '1.0.0'},
      'capabilities': caps,
    });

    if (result != null) {
      _initialized = true;
      // Enviar initialized notification
      _sendNotification('initialized', {});
      _readyCompleter.complete();
    } else {
      _readyCompleter.completeError(Exception('LSP initialize failed'));
    }
  }

  /// Espera a que el servidor esté listo.
  Future<void> get ready => _readyCompleter.future;

  /// Abre un documento en el servidor LSP.
  Future<void> openDocument(String text) async {
    await ready;
    _docVersion++;
    _sendNotification('textDocument/didOpen', {
      'textDocument': LspTextDocumentItem(
        uri: _fileUri,
        languageId: languageId,
        version: _docVersion,
        text: text,
      ).toJson(),
    });
  }

  /// Notifica cambios en el documento.
  Future<void> updateDocument(String text) async {
    if (!_initialized || _shutdown) return;
    _docVersion++;
    _sendNotification('textDocument/didChange', {
      'textDocument': LspVersionedTextDocumentIdentifier(
        uri: _fileUri,
        version: _docVersion,
      ).toJson(),
      'contentChanges': [
        {'text': text},
      ],
    });
  }

  /// Solicita completaciones en una posición.
  Future<List<LspCompletionItem>> requestCompletions(
      int line, int character) async {
    if (!_initialized || _shutdown) return [];

    final result = await _sendRequest('textDocument/completion', {
      'textDocument': {'uri': _fileUri},
      'position': {'line': line, 'character': character},
    });

    if (result == null) return [];

    final items = <LspCompletionItem>[];

    // La respuesta puede ser CompletionList o List<CompletionItem>
    final raw = result['items'] ?? result[''] ?? result;
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(LspCompletionItem.fromJson(item));
        }
      }
    }

    return items;
  }

  /// Cierra el documento actual.
  void closeDocument() {
    if (!_initialized || _shutdown) return;
    _sendNotification('textDocument/didClose', {
      'textDocument': {'uri': _fileUri},
    });
  }

  /// Detiene el servidor LSP.
  Future<void> stop() async {
    if (_shutdown) return;
    _shutdown = true;

    if (_initialized) {
      await _sendRequest('shutdown', {});
      _sendNotification('exit', {});
    }

    _process?.kill();
    _process = null;
    _initialized = false;
  }

  // ── Comunicación JSON-RPC ──

  int get pid => _process?.pid ?? 0;
  String get _fileUri => 'file://$filePath';

  /// Envía un request (con id, espera respuesta).
  Future<Map<String, dynamic>?> _sendRequest(
      String method, Map<String, dynamic> params) async {
    if (_process == null) return null;

    final id = _messageId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    _sendMessage({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });

    // Timeout de 5 segundos
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingRequests.remove(id);
        return <String, dynamic>{};
      },
    );
  }

  /// Envía una notificación (sin id).
  void _sendNotification(String method, Map<String, dynamic> params) {
    if (_process == null) return;
    _sendMessage({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
  }

  /// Envía un mensaje JSON-RPC al servidor.
  void _sendMessage(Map<String, dynamic> message) {
    final json = jsonEncode(message);
    final header = 'Content-Length: ${json.length}\r\n\r\n';
    _process!.stdin.write(header + json);
  }

  /// Procesa datos entrantes del servidor.
  void _onData(String data) {
    _incomingBuffer += data;

    // Buffer limit of 1MB to prevent memory leaks from rogue LSPs
    const maxBuffer = 1 * 1024 * 1024;
    if (_incomingBuffer.length > maxBuffer) {
      _incomingBuffer = _incomingBuffer.substring(_incomingBuffer.length - maxBuffer);
    }

    while (true) {
      // Buscar Content-Length header
      final headerEnd = _incomingBuffer.indexOf('\r\n\r\n');
      if (headerEnd == -1) break;

      final header = _incomingBuffer.substring(0, headerEnd);
      final lengthMatch = RegExp(r'Content-Length: (\d+)').firstMatch(header);
      if (lengthMatch == null) break;

      final contentLength = int.parse(lengthMatch.group(1)!);
      final messageStart = headerEnd + 4;

      if (_incomingBuffer.length < messageStart + contentLength) break;

      final content =
          _incomingBuffer.substring(messageStart, messageStart + contentLength);
      _incomingBuffer = _incomingBuffer.substring(messageStart + contentLength);

      _handleMessage(content);
    }
  }

  /// Procesa un mensaje JSON-RPC.
  void _handleMessage(String content) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Response a un request nuestro
      if (json.containsKey('id') && json.containsKey('result')) {
        final id = json['id'] as int;
        final completer = _pendingRequests.remove(id);
        completer?.complete(json['result'] as Map<String, dynamic>? ?? {});
        return;
      }

      // Error response
      if (json.containsKey('id') && json.containsKey('error')) {
        final id = json['id'] as int;
        final completer = _pendingRequests.remove(id);
        completer?.complete(null);
        return;
      }

      // Notification del servidor (publishDiagnostics, etc.)
      if (json.containsKey('method')) {
        final method = json['method'] as String;
        final params = json['params'] as Map<String, dynamic>?;

        if (method == 'textDocument/publishDiagnostics' && params != null) {
          onDiagnostics?.call(
              List<Map<String, dynamic>>.from(params['diagnostics'] as List));
        }
        return;
      }
    } catch (_) {
      // Ignorar mensajes malformados
    }
  }

  /// Limpia recursos.
  void dispose() {
    stop();
    _pendingRequests.clear();
  }
}
