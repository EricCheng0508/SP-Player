import 'package:enjoy_player/features/ai/data/batching/batching_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/batch_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/ai/domain/prompts/translation_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

class _InnerFake implements TranslationCapability {
  final calls = <String>[];

  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    calls.add(text);
    return TranslationResult(
      translatedText: 'S:$text',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }
}

class _BatchFake implements BatchTranslationCapability {
  final calls = <List<String>>[];
  Object? errorToThrow;
  Set<int> skipIndexes = {};

  @override
  Future<List<String?>> translateLines({
    required List<String> lines,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    calls.add(lines);
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return [
      for (var i = 0; i < lines.length; i++)
        skipIndexes.contains(i) ? null : 'B:${lines[i]}',
    ];
  }
}

Future<void> _settle([Duration duration = const Duration(milliseconds: 60)]) {
  return Future<void>.delayed(duration);
}

void main() {
  late _InnerFake inner;
  late _BatchFake batch;
  late BatchingTranslationCapability capability;

  setUp(() {
    inner = _InnerFake();
    batch = _BatchFake();
    capability = BatchingTranslationCapability(inner, batch);
  });

  Future<TranslationResult> call(
    String text, {
    bool? forceRefresh,
  }) => capability.translate(
    text: text,
    sourceLanguage: 'en',
    targetLanguage: 'zh-CN',
    forceRefresh: forceRefresh,
  );

  test('coalesces concurrent calls into one batched LLM call', () async {
    final futures = [call('A'), call('B'), call('C')];
    await _settle();

    expect(batch.calls, [
      ['A', 'B', 'C'],
    ]);
    expect(inner.calls, isEmpty);
    final results = await Future.wait(futures);
    expect(results.map((r) => r.translatedText), ['B:A', 'B:B', 'B:C']);
  });

  test('batches by language pair — different pairs never share a call', () async {
    final a = capability.translate(
      text: 'A',
      sourceLanguage: 'en',
      targetLanguage: 'zh-CN',
    );
    final b = capability.translate(
      text: 'B',
      sourceLanguage: 'fr',
      targetLanguage: 'de',
    );
    await _settle();

    expect(batch.calls.length, 2);
    expect(batch.calls.map((c) => c.first), containsAll(['A', 'B']));
    await Future.wait([a, b]);
  });

  test('force-refresh bypasses the batch entirely', () async {
    final future = call('A', forceRefresh: true);
    await _settle();

    expect(inner.calls, ['A']);
    expect(batch.calls, isEmpty);
    final result = await future;
    expect(result.translatedText, 'S:A');
  });

  test('burst beyond the line cap spills into follow-up batches', () async {
    final futures = <Future<TranslationResult>>[];
    for (var i = 0; i < kAutoTranslateBatchMaxLines + 2; i++) {
      futures.add(call('T$i'));
    }
    await _settle();

    expect(batch.calls.length, 2);
    expect(batch.calls.first.length, kAutoTranslateBatchMaxLines);
    expect(batch.calls.last.length, 2);
    await Future.wait(futures);
  });

  test('a very long line flushes immediately instead of waiting the window',
      () async {
    final long = 'x' * kAutoTranslateBatchMaxChars;
    final future = call(long);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(batch.calls.length, 1);
    await future;
  });

  test('a line the model skipped is rescued by a single-line call', () async {
    batch.skipIndexes = {1};
    final futures = [call('A'), call('B'), call('C')];
    await _settle();

    expect(inner.calls, ['B']);
    final results = await Future.wait(futures);
    expect(results.map((r) => r.translatedText), ['B:A', 'S:B', 'B:C']);
  });

  test('a batch failure errors every coalesced line', () async {
    batch.errorToThrow = Exception('network down');
    final futures = [call('A'), call('B')];

    await expectLater(Future.wait(futures), throwsA(isA<Exception>()));
    expect(batch.calls.length, 1);
  });

  test('late arrivals during the window join the same batch', () async {
    final first = call('A');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = call('B');
    await _settle();

    expect(batch.calls, [
      ['A', 'B'],
    ]);
    await Future.wait([first, second]);
  });
}
