import 'dart:io';

import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a file of [length] bytes without writing its contents.
Future<void> _sparse(File f, int length) async {
  f.createSync(recursive: true);
  final raf = await f.open(mode: FileMode.append);
  await raf.truncate(length);
  await raf.close();
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sp-sweep-test');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  ComponentStore storeWith(Directory dir) => ComponentStore(
    rootOverride: '${dir.path}${Platform.pathSeparator}components',
  );

  Directory liveAsrDir() =>
      storeWith(root).installDir(specOf(ComponentKind.liveAsr));

  File liveAsrFile(String name) => File('${liveAsrDir().path}\\$name');

  Future<void> installNewEngine() async {
    final spec = specOf(ComponentKind.liveAsr);
    await liveAsrDir().create(recursive: true);
    for (final f in spec.files) {
      await _sparse(liveAsrFile(f.relativePath), f.minBytes + 1);
    }
  }

  Future<void> dropLegacyFiles() async {
    await liveAsrDir().create(recursive: true);
    for (final name in const [
      'encoder-epoch-99-avg-1.int8.onnx',
      'decoder-epoch-99-avg-1.int8.onnx',
      'joiner-epoch-99-avg-1.int8.onnx',
    ]) {
      await liveAsrFile(name).create(recursive: true);
    }
  }

  test('new engine installed: legacy zipformer files are deleted', () async {
    await installNewEngine();
    await dropLegacyFiles();

    await storeWith(root).sweepLegacyFiles();

    expect(
      liveAsrFile('encoder-epoch-99-avg-1.int8.onnx').existsSync(),
      isFalse,
    );
    expect(
      liveAsrFile('decoder-epoch-99-avg-1.int8.onnx').existsSync(),
      isFalse,
    );
    expect(
      liveAsrFile('joiner-epoch-99-avg-1.int8.onnx').existsSync(),
      isFalse,
    );
    for (final f in specOf(ComponentKind.liveAsr).files) {
      expect(
        liveAsrFile(f.relativePath).existsSync(),
        isTrue,
        reason: f.relativePath,
      );
    }
  });

  test(
    'new engine missing: legacy files are kept (old engine still works)',
    () async {
      await dropLegacyFiles();
      await _sparse(liveAsrFile('encoder.int8.onnx'), 1024);

      await storeWith(root).sweepLegacyFiles();

      expect(
        liveAsrFile('encoder-epoch-99-avg-1.int8.onnx').existsSync(),
        isTrue,
      );
      expect(
        liveAsrFile('decoder-epoch-99-avg-1.int8.onnx').existsSync(),
        isTrue,
      );
      expect(
        liveAsrFile('joiner-epoch-99-avg-1.int8.onnx').existsSync(),
        isTrue,
      );
    },
  );

  test('no live-asr dir at all: sweep is a silent no-op', () async {
    await storeWith(root).sweepLegacyFiles();
    expect(liveAsrDir().existsSync(), isFalse);
  });

  test('tokens.txt (shared by both generations) survives the sweep', () async {
    await installNewEngine();
    await dropLegacyFiles();

    await storeWith(root).sweepLegacyFiles();

    expect(liveAsrFile('tokens.txt').existsSync(), isTrue);
  });
}
