import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Resultado de una ejecución.
class RunResult {
  final int exitCode;
  final List<String> stdout;
  final List<String> stderr;
  final Duration duration;
  final bool wasCancelled;

  const RunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
    this.wasCancelled = false,
  });

  bool get success => exitCode == 0 && !wasCancelled;
  List<String> get allOutput => [...stdout, ...stderr];
}

/// Callback para salida en tiempo real.
typedef OutputCallback = void Function(String line, bool isError);

/// Runner abstracto — ejecuta código de un lenguaje específico.
abstract class CodeRunner {
  String get language;
  String get extension;

  Process? _currentProcess;
  bool _cancelRequested = false;

  /// Callback opcional que se dispara cuando el usuario solicita cancelación.
  void Function()? onCancelRequested;

  /// Cancela la ejecución en curso.
  void cancel() {
    _cancelRequested = true;
    _currentProcess?.kill(ProcessSignal.sigterm);
    _currentProcess = null;
    onCancelRequested?.call();
  }

  /// Resuelve la ruta del binario según la plataforma.
  String getBinaryPath(String binary) {
    // En Android los binarios no están en PATH del sistema;
    // se requiere ruta absoluta al NDK.
    if (Platform.isAndroid) {
      return '/data/data/com.leoide.app/files/ndk/$binary';
    }
    return binary;
  }

  /// Ejecuta un proceso con captura garantizada de stdout/stderr,
  /// orden correcto de registro de listeners, y clasificación de errores.
  ///
  /// Orden:
  /// 1. Iniciar proceso
  /// 2. Crear StreamControllers síncronos para output en tiempo real
  /// 3. Registrar listeners de stdout/stderr (ANTES de escribir stdin)
  /// 4. Escribir código en stdin y cerrar
  /// 5. Future.wait([exitCode, stdoutDone, stderrDone])
  /// 6. Retornar RunResult con wasCancelled
  Future<RunResult> _executeProcess({
    required Future<Process> Function() processStarter,
    required String code,
    OutputCallback? onOutput,
  }) async {
    final stopwatch = Stopwatch()..start();
    final stdoutLines = <String>[];
    final stderrLines = <String>[];
    _cancelRequested = false;

    try {
      final process = await processStarter();
      _currentProcess = process;

      // StreamControllers síncronos para output en tiempo real thread-safe
      final stdoutController = StreamController<String>.broadcast(sync: true);
      final stderrController = StreamController<String>.broadcast(sync: true);

      // Registrar listeners ANTES de escribir stdin
      // para no perder salida de procesos rápidos
      final stdoutDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stdoutLines.add(line);
        stdoutController.add(line);
      }).asFuture();

      final stderrDone = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderrLines.add(line);
        stderrController.add(line);
      }).asFuture();

      // Conectar callbacks de salida en tiempo real
      // (thread-safety la gestiona el caller mediante addPostFrameCallback)
      if (onOutput != null) {
        stdoutController.stream.listen((line) => onOutput(line, false));
        stderrController.stream.listen((line) => onOutput(line, true));
      }

      // Escribir código en stdin y cerrar
      // (después de registrar listeners — orden crítico)
      if (code.isNotEmpty) {
        process.stdin.write(code);
        await process.stdin.flush();
      }
      await process.stdin.close();

      // Esperar a que TODO esté completo:
      // exitCode + cierre de streams
      final exitCode = await Future.wait([
        process.exitCode,
        stdoutDone,
        stderrDone,
      ]).then((results) => results[0] as int);

      stopwatch.stop();

      return RunResult(
        exitCode: exitCode,
        stdout: stdoutLines,
        stderr: stderrLines,
        duration: stopwatch.elapsed,
        wasCancelled: _cancelRequested,
      );
    } catch (e) {
      stopwatch.stop();
      final errorMsg =
          'Error al ejecutar $language: $e\n'
          '¿Tienes ${requiredBinary ?? language} instalado?';
      stderrLines.add(errorMsg);
      onOutput?.call(errorMsg, true);
      return RunResult(
        exitCode: -1,
        stdout: stdoutLines,
        stderr: stderrLines,
        duration: stopwatch.elapsed,
        wasCancelled: _cancelRequested,
      );
    } finally {
      _currentProcess = null;
    }
  }

  /// Ejecuta el código y captura la salida.
  Future<RunResult> run(
    String code, {
    OutputCallback? onOutput,
  });

  /// Nombre del binario necesario.
  String? get requiredBinary => null;

  /// Mensaje si el binario no está instalado.
  String? installGuide() => null;
}

/// Runner para Python (interpretado).
class PythonRunner extends CodeRunner {
  @override
  String get language => 'Python';
  @override
  String get extension => '.py';
  @override
  String? get requiredBinary => 'python3';

  @override
  String? installGuide() => 'Instala Python: sudo pacman -S python';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    return _executeProcess(
      code: code,
      onOutput: onOutput,
      processStarter: () =>
          Process.start(getBinaryPath('python3'), ['-'], runInShell: true),
    );
  }
}

/// Runner para C (compilado).
class CRunner extends CodeRunner {
  @override
  String get language => 'C';
  @override
  String get extension => '.c';
  @override
  String? get requiredBinary => 'gcc';

  @override
  String? installGuide() => 'Instala GCC: sudo pacman -S gcc';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    final tempDir = Directory('${Directory.systemTemp.path}/leoide');
    if (!await tempDir.exists()) await tempDir.create(recursive: true);

    final outFile = File('${tempDir.path}/program.out');

    onOutput?.call('🔨 Compilando con gcc...', false);

    // Fase 1: Compilación desde stdin
    final compileResult = await _executeProcess(
      code: code,
      onOutput: (line, isError) {
        onOutput?.call('   ⚠️  $line', isError);
      },
      processStarter: () => Process.start(getBinaryPath('gcc'), [
        '-x', 'c', '-',
        '-o', outFile.path,
        '-Wall',
      ], runInShell: true),
    );

    if (compileResult.exitCode != 0) {
      // Error de compilación — se propaga el resultado
      return compileResult;
    }

    onOutput?.call('✅ Compilación exitosa, ejecutando...', false);

    // Asegurar permisos de ejecución
    await Process.run('chmod', ['+x', outFile.path]);

    // Fase 2: Ejecución del binario compilado
    return _executeProcess(
      code: '', // sin stdin
      onOutput: onOutput,
      processStarter: () =>
          Process.start(outFile.path, [], runInShell: true),
    );
  }
}

/// Runner para C++ (compilado).
class CppRunner extends CodeRunner {
  @override
  String get language => 'C++';
  @override
  String get extension => '.cpp';
  @override
  String? get requiredBinary => 'g++';

  @override
  String? installGuide() => 'Instala G++: sudo pacman -S gcc';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    final tempDir = Directory('${Directory.systemTemp.path}/leoide');
    if (!await tempDir.exists()) await tempDir.create(recursive: true);

    final outFile = File('${tempDir.path}/program.out');

    onOutput?.call('🔨 Compilando con g++...', false);

    // Fase 1: Compilación desde stdin
    final compileResult = await _executeProcess(
      code: code,
      onOutput: (line, isError) {
        onOutput?.call('   ⚠️  $line', isError);
      },
      processStarter: () => Process.start(getBinaryPath('g++'), [
        '-x', 'c++', '-',
        '-o', outFile.path,
        '-Wall',
        '-std=c++17',
      ], runInShell: true),
    );

    if (compileResult.exitCode != 0) {
      return compileResult;
    }

    onOutput?.call('✅ Compilación exitosa, ejecutando...', false);

    await Process.run('chmod', ['+x', outFile.path]);

    // Fase 2: Ejecución del binario compilado
    return _executeProcess(
      code: '',
      onOutput: onOutput,
      processStarter: () =>
          Process.start(outFile.path, [], runInShell: true),
    );
  }
}

/// Runner para JavaScript (interpretado con Node.js).
class JavaScriptRunner extends CodeRunner {
  @override
  String get language => 'JavaScript';
  @override
  String get extension => '.js';
  @override
  String? get requiredBinary => 'node';

  @override
  String? installGuide() => 'Instala Node.js: sudo pacman -S nodejs';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    return _executeProcess(
      code: code,
      onOutput: onOutput,
      processStarter: () =>
          Process.start(getBinaryPath('node'), [], runInShell: true),
    );
  }
}

/// Runner para PHP (interpretado).
class PhpRunner extends CodeRunner {
  @override
  String get language => 'PHP';
  @override
  String get extension => '.php';
  @override
  String? get requiredBinary => 'php';

  @override
  String? installGuide() =>
      'Instala PHP CLI: sudo pacman -S php\n'
      'Luego: sudo pacman -S php-cgi';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    // PHP no está instalado, mostrar guía
    onOutput?.call('❌ PHP no está instalado en el sistema.', true);
    onOutput?.call('   Para instalar:', false);
    onOutput?.call('   sudo pacman -S php', false);
    onOutput?.call('', false);

    return const RunResult(
      exitCode: -1,
      stdout: [],
      stderr: ['PHP no instalado'],
      duration: Duration.zero,
    );
  }
}

/// Runner para Dart (interpretado/compilado vía VM).
class DartRunner extends CodeRunner {
  @override
  String get language => 'Dart';
  @override
  String get extension => '.dart';
  @override
  String? get requiredBinary => 'dart';

  @override
  String? installGuide() => 'Dart ya incluido con Flutter SDK';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    final tempDir = Directory('${Directory.systemTemp.path}/leoide');
    if (!await tempDir.exists()) await tempDir.create(recursive: true);

    final file = File('${tempDir.path}/script.dart');
    await file.writeAsString(code);

    onOutput?.call('🚀 Ejecutando con Dart VM...', false);

    return _executeProcess(
      code: '', // no stdin, el código está en el archivo
      onOutput: onOutput,
      processStarter: () =>
          Process.start(getBinaryPath('dart'), ['run', file.path], runInShell: true),
    );
  }
}

/// Runner para HTML (abre en navegador).
class HtmlRunner extends CodeRunner {
  @override
  String get language => 'HTML';
  @override
  String get extension => '.html';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    final tempDir = Directory('${Directory.systemTemp.path}/leoide');
    if (!await tempDir.exists()) await tempDir.create(recursive: true);

    final file = File('${tempDir.path}/index.html');
    await file.writeAsString(code);

    final stopwatch = Stopwatch()..start();

    onOutput?.call('🌐 Abriendo HTML en el navegador...', false);
    onOutput?.call('   Archivo: ${file.path}', false);

    try {
      await Process.start('xdg-open', [file.path], runInShell: true);
      onOutput?.call('✅ Navegador abierto.', false);
    } catch (e) {
      onOutput?.call('❌ No se pudo abrir el navegador: $e', true);
    }

    stopwatch.stop();
    return RunResult(
        exitCode: 0,
        stdout: ['HTML abierto en navegador'],
        stderr: [],
        duration: stopwatch.elapsed);
  }
}

/// Runner para CSS (no ejecutable directamente).
class CssRunner extends CodeRunner {
  @override
  String get language => 'CSS';
  @override
  String get extension => '.css';

  @override
  Future<RunResult> run(String code, {OutputCallback? onOutput}) async {
    onOutput?.call('ℹ️  CSS es un lenguaje de estilos, no ejecutable.', false);
    onOutput?.call('   Para visualizarlo, necesitas un archivo HTML', false);
    onOutput?.call('   que lo referencie con <link rel="stylesheet">', false);
    onOutput?.call('', false);
    onOutput?.call('   Ejemplo:', false);
    onOutput?.call('   <link rel="stylesheet" href="estilos.css">', false);

    return const RunResult(
      exitCode: 0,
      stdout: ['CSS no es ejecutable directamente'],
      stderr: [],
      duration: Duration.zero,
    );
  }
}

/// Fábrica de runners — selecciona el runner correcto por extensión.
CodeRunner? runnerForExtension(String ext) {
  switch (ext) {
    case '.py':
      return PythonRunner();
    case '.c':
      return CRunner();
    case '.cpp':
    case '.cc':
    case '.cxx':
      return CppRunner();
    case '.js':
    case '.mjs':
      return JavaScriptRunner();
    case '.php':
      return PhpRunner();
    case '.dart':
      return DartRunner();
    case '.html':
    case '.htm':
      return HtmlRunner();
    case '.css':
      return CssRunner();
    default:
      return null;
  }
}
