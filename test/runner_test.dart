import 'package:flutter_test/flutter_test.dart';
import 'package:leoide/editor/engine/runner.dart';

void main() {
  group('RunResult', () {
    test('success es true con exitCode 0 y sin cancelación', () {
      const result = RunResult(
        exitCode: 0,
        stdout: ['ok'],
        stderr: [],
        duration: Duration.zero,
      );
      expect(result.success, isTrue);
      expect(result.wasCancelled, isFalse);
    });

    test('success es false si fue cancelado aunque exitCode sea 0', () {
      const result = RunResult(
        exitCode: 0,
        stdout: [],
        stderr: [],
        duration: Duration.zero,
        wasCancelled: true,
      );
      expect(result.success, isFalse);
      expect(result.wasCancelled, isTrue);
    });

    test('success es false con exitCode != 0 sin cancelación', () {
      const result = RunResult(
        exitCode: 1,
        stdout: [],
        stderr: ['error'],
        duration: Duration.zero,
        wasCancelled: false,
      );
      expect(result.success, isFalse);
      expect(result.wasCancelled, isFalse);
    });

    test('wasCancelled default es false para backward compat', () {
      const result = RunResult(
        exitCode: 0,
        stdout: [],
        stderr: [],
        duration: Duration.zero,
      );
      expect(result.wasCancelled, isFalse);
    });
  });

  group('CodeRunner', () {
    // Test concreto: PythonRunner
    test('PythonRunner tiene configuración correcta', () {
      final runner = PythonRunner();
      expect(runner.language, 'Python');
      expect(runner.extension, '.py');
      expect(runner.requiredBinary, 'python3');
    });

    test('CRunner tiene configuración correcta', () {
      final runner = CRunner();
      expect(runner.language, 'C');
      expect(runner.extension, '.c');
      expect(runner.requiredBinary, 'gcc');
    });

    test('JavaScriptRunner tiene configuración correcta', () {
      final runner = JavaScriptRunner();
      expect(runner.language, 'JavaScript');
      expect(runner.extension, '.js');
      expect(runner.requiredBinary, 'node');
    });

    test('DartRunner tiene configuración correcta', () {
      final runner = DartRunner();
      expect(runner.language, 'Dart');
      expect(runner.extension, '.dart');
      expect(runner.requiredBinary, 'dart');
    });
  });

  group('runnerForExtension', () {
    test('retorna PythonRunner para .py', () {
      final runner = runnerForExtension('.py');
      expect(runner, isA<PythonRunner>());
    });

    test('retorna CRunner para .c', () {
      final runner = runnerForExtension('.c');
      expect(runner, isA<CRunner>());
    });

    test('retorna CppRunner para .cpp', () {
      final runner = runnerForExtension('.cpp');
      expect(runner, isA<CppRunner>());
    });

    test('retorna JavaScriptRunner para .js', () {
      final runner = runnerForExtension('.js');
      expect(runner, isA<JavaScriptRunner>());
    });

    test('retorna DartRunner para .dart', () {
      final runner = runnerForExtension('.dart');
      expect(runner, isA<DartRunner>());
    });

    test('retorna HtmlRunner para .html', () {
      final runner = runnerForExtension('.html');
      expect(runner, isA<HtmlRunner>());
    });

    test('retorna null para extensión desconocida', () {
      final runner = runnerForExtension('.rs');
      expect(runner, isNull);
    });
  });
}
