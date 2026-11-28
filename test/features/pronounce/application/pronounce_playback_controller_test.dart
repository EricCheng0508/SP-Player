import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:enjoy_player/features/pronounce/application/pronounce_audio_engine.dart';
import 'package:enjoy_player/features/pronounce/application/pronounce_playback_controller.dart';
import 'package:enjoy_player/features/pronounce/application/pronounce_service.dart';
import 'package:enjoy_player/features/pronounce/domain/pronounce_target.dart';

void main() {
  late FakePronounceAudioEngine engine;
  late ProviderContainer container;
  late Directory tempDir;
  late int getCount;

  setUp(() async {
    engine = FakePronounceAudioEngine();
    PronouncePlaybackController.debugEngineFactory = () => engine;
    tempDir = await Directory.systemTemp.createTemp('pronounce_test');
    getCount = 0;
  });

  tearDown(() async {
    PronouncePlaybackController.debugEngineFactory = null;
    container.dispose();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// 有道的音频下载替身：走 [PronounceService] 的真实磁盘缓存逻辑，
  /// 只把 HTTP 换成可控的假响应。
  PronounceService service({
    Duration delay = Duration.zero,
    int statusCode = 200,
  }) => PronounceService(
    cacheDir: () async => tempDir,
    httpGet: (uri) async {
      getCount++;
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (statusCode != 200) return http.Response('nope', statusCode);
      return http.Response.bytes(Uint8List.fromList([1, 2, 3, 4]), 200);
    },
  );

  ProviderContainer makeContainer({PronounceService? svc}) => ProviderContainer(
    overrides: [pronounceServiceProvider.overrideWithValue(svc ?? service())],
  );

  PronounceTarget target([String text = 'hello']) => PronounceTarget.tryCreate(
    text: text,
    localeTag: 'en-US',
    surfaceId: PronounceSurfaceId.lookup,
  )!;

  test('play → loading → playing; stop returns idle', () async {
    container = makeContainer(
      svc: service(delay: const Duration(milliseconds: 40)),
    );
    final ctrl = container.read(pronouncePlaybackControllerProvider.notifier);

    final playFuture = ctrl.play(target());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(
      container.read(pronouncePlaybackControllerProvider).isLoading,
      isTrue,
    );
    await playFuture;
    expect(
      container.read(pronouncePlaybackControllerProvider).isPlaying,
      isTrue,
    );
    // 缓存命中后交给播放引擎的是本地文件，不再是远程 URL。
    expect(engine.playedUrls, hasLength(1));
    expect(engine.playedUrls.single, isNot(startsWith('http')));

    await ctrl.stop();
    expect(container.read(pronouncePlaybackControllerProvider).isIdle, isTrue);
    expect(engine.stopCount, greaterThan(0));
  });

  test('second play of same target stops', () async {
    container = makeContainer();
    final ctrl = container.read(pronouncePlaybackControllerProvider.notifier);
    final t = target();
    await ctrl.play(t);
    expect(
      container.read(pronouncePlaybackControllerProvider).isPlaying,
      isTrue,
    );

    await ctrl.play(t);
    expect(container.read(pronouncePlaybackControllerProvider).isIdle, isTrue);
  });

  test('stale generation is ignored when stop races fetch', () async {
    container = makeContainer(
      svc: service(delay: const Duration(milliseconds: 80)),
    );
    final ctrl = container.read(pronouncePlaybackControllerProvider.notifier);

    final playFuture = ctrl.play(target());
    await ctrl.stop();
    await playFuture;

    expect(container.read(pronouncePlaybackControllerProvider).isIdle, isTrue);
    expect(engine.playedUrls, isEmpty);
  });

  test('same target is served from the in-memory URL cache', () async {
    container = makeContainer();
    final ctrl = container.read(pronouncePlaybackControllerProvider.notifier);
    final t = target();

    await ctrl.play(t);
    await ctrl.stop();
    await ctrl.play(t);

    expect(getCount, 1);
    expect(engine.playedUrls, hasLength(2));
  });

  test(
    'a fresh session hits the on-disk cache without downloading again',
    () async {
      final svc = service();

      final first = makeContainer(svc: svc);
      await first
          .read(pronouncePlaybackControllerProvider.notifier)
          .play(target());
      first.dispose();

      // 新容器 = 空的内存缓存，只能靠磁盘缓存命中。
      container = makeContainer(svc: svc);
      await container
          .read(pronouncePlaybackControllerProvider.notifier)
          .play(target());

      expect(getCount, 1);
      expect(engine.playedUrls, hasLength(2));
    },
  );

  test('non-200 download surfaces as a failure, nothing is played', () async {
    container = makeContainer(svc: service(statusCode: 500));
    final ctrl = container.read(pronouncePlaybackControllerProvider.notifier);

    await expectLater(ctrl.play(target()), throwsA(anything));
    expect(engine.playedUrls, isEmpty);
  });
}
