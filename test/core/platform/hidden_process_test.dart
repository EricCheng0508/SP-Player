@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/platform/hidden_process.dart';

/// Polls [file] until it exists, so a slow child does not fail the test.
Future<String?> _waitForFile(File file) async {
  for (var i = 0; i < 100; i++) {
    if (file.existsSync()) return file.readAsStringSync();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return null;
}

void main() {
  test('starts a child whose executable path contains spaces', () async {
    final root = await Directory.systemTemp.createTemp('spawn_hidden');
    addTearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    // A directory with a space in it is the real-world case: the component
    // store lives under "D:\tool\SP Player\...". An unquoted argv[0] would
    // make CreateProcessW fail outright.
    final target = Directory('${root.path}\\sp player bin');
    target.createSync(recursive: true);
    final cmd = File(
      '${Platform.environment['SystemRoot']}\\System32\\cmd.exe',
    );
    final copied = await cmd.copy('${target.path}\\cmd.exe');

    final ok = await spawnHidden(copied.path, [
      '/c',
      'echo alive> out.txt',
    ], workingDirectory: target.path);
    expect(ok, isTrue);

    final written = await _waitForFile(File('${target.path}\\out.txt'));
    expect(written?.trim(), 'alive');
  });

  test('passes arguments with spaces through intact', () async {
    final root = await Directory.systemTemp.createTemp('spawn_args');
    addTearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    // A script file (rather than -Command) keeps PowerShell from re-parsing
    // the argument, so what lands in the file is exactly what argv carried.
    final out = File('${root.path}\\argv.txt');
    final script = File('${root.path}\\echo-arg.ps1');
    script.writeAsStringSync(
      'param([string]\$a)\n'
      "[IO.File]::WriteAllText('${out.path}', \$a)\n",
    );

    const payload = r'C:\Users\me\my folder\out file.txt';
    final ok = await spawnHidden('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
      payload,
    ]);
    expect(ok, isTrue);

    final written = await _waitForFile(out);
    expect(written, payload);
  });
}
