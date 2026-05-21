import 'dart:convert';
import 'dart:io';

/// Resultado de una ejecución.
class RunResult {
  final int exitCode;
  final List<String> stdout;
  final List<String> stderr;
  final Duration duration;

  const RunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });

  bool get success => exitCode == 0;
  List<String> get allOutput => [...stdout, ...stderr];
}

/// Callback para salida en tiempo real.
typedef OutputCallback = void Function(String line, bool isError);

/// Runner abstracto — ejecuta código de un lenguaje específico.
abstract class CodeRunner {
  String get language;
  String get extension;

  /// Referencia al proceso en ejecución (para cancelación).
  Process? _currentProcess;

  /// Cancela la ejecución en curso.
  void cancel() {
    _currentProcess?.kill(ProcessSignal.sigterm);
    _currentProcess = null;
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
    final stopwatch = Stopwatch()..start();
    final stdout = <String>[];
    final stderr = <String>[];

    try {
      final process = await Process.start('python3', ['-'], runInShell: true);
      _currentProcess = process;

      // Escribir el código en stdin y cerrar
      process.stdin.write(code);
      await process.stdin.flush();
      await process.stdin.close();

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stdout.add(line);
        onOutput?.call(line, false);
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call(line, true);
      });

      final exitCode = await process.exitCode;
      stopwatch.stop();

      return RunResult(
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      stderr.add('Error: $e');
      return RunResult(
          exitCode: -1,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    }
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

    final stopwatch = Stopwatch()..start();
    final stdout = <String>[];
    final stderr = <String>[];

    try {
      onOutput?.call('🔨 Compilando con gcc...', false);

      // Compilar desde stdin
      final compile = await Process.start('gcc', [
        '-x', 'c', '-', // Lee C desde stdin
        '-o', outFile.path,
        '-Wall',
      ], runInShell: true);
      _currentProcess = compile;

      compile.stdin.write(code);
      await compile.stdin.flush();
      await compile.stdin.close();

      compile.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call('   ⚠️  $line', true);
      });

      final compileExit = await compile.exitCode;

      if (compileExit != 0) {
        stopwatch.stop();
        stderr.add('❌ Compilación fallida (código $compileExit)');
        return RunResult(
            exitCode: compileExit,
            stdout: stdout,
            stderr: stderr,
            duration: stopwatch.elapsed);
      }

      onOutput?.call('✅ Compilación exitosa, ejecutando...', false);

      // Ejecutar
      await Process.run('chmod', ['+x', outFile.path]);
      final run = await Process.start(outFile.path, [], runInShell: true);
      _currentProcess = run;

      run.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stdout.add(line);
        onOutput?.call(line, false);
      });

      run.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call(line, true);
      });

      final runExit = await run.exitCode;
      stopwatch.stop();

      return RunResult(
          exitCode: runExit,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      stderr.add('Error del sistema: $e');
      return RunResult(
          exitCode: -1,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    }
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

    final stopwatch = Stopwatch()..start();
    final stdout = <String>[];
    final stderr = <String>[];

    try {
      onOutput?.call('🔨 Compilando con g++...', false);

      final compile = await Process.start('g++', [
        '-x', 'c++', '-', // Lee C++ desde stdin
        '-o', outFile.path,
        '-Wall',
        '-std=c++17',
      ], runInShell: true);
      _currentProcess = compile;

      compile.stdin.write(code);
      await compile.stdin.flush();
      await compile.stdin.close();

      compile.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call('   ⚠️  $line', true);
      });

      final compileExit = await compile.exitCode;

      if (compileExit != 0) {
        stopwatch.stop();
        stderr.add('❌ Compilación fallida');
        return RunResult(
            exitCode: compileExit,
            stdout: stdout,
            stderr: stderr,
            duration: stopwatch.elapsed);
      }

      onOutput?.call('✅ Compilación exitosa, ejecutando...', false);

      await Process.run('chmod', ['+x', outFile.path]);
      final run = await Process.start(outFile.path, [], runInShell: true);
      _currentProcess = run;

      run.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stdout.add(line);
        onOutput?.call(line, false);
      });

      run.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call(line, true);
      });

      final runExit = await run.exitCode;
      stopwatch.stop();

      return RunResult(
          exitCode: runExit,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      stderr.add('Error del sistema: $e');
      return RunResult(
          exitCode: -1,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    }
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
    final stopwatch = Stopwatch()..start();
    final stdout = <String>[];
    final stderr = <String>[];

    try {
      final process = await Process.start('node', [], runInShell: true);
      _currentProcess = process;

      process.stdin.write(code);
      await process.stdin.flush();
      await process.stdin.close();

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stdout.add(line);
        onOutput?.call(line, false);
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call(line, true);
      });

      final exitCode = await process.exitCode;
      stopwatch.stop();

      return RunResult(
          exitCode: exitCode,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      stderr.add('Error: $e');
      return RunResult(
          exitCode: -1,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    }
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

    return RunResult(
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

    final stopwatch = Stopwatch()..start();
    final stdout = <String>[];
    final stderr = <String>[];

    try {
      onOutput?.call('🚀 Ejecutando con Dart VM...', false);

      final process = await Process.start('dart', ['run', file.path],
          runInShell: true);
      _currentProcess = process;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stdout.add(line);
        onOutput?.call(line, false);
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.add(line);
        onOutput?.call(line, true);
      });

      final exitCode = await process.exitCode;
      stopwatch.stop();

      return RunResult(
          exitCode: exitCode,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      stderr.add('Error: $e');
      return RunResult(
          exitCode: -1,
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed);
    }
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

    return RunResult(
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
