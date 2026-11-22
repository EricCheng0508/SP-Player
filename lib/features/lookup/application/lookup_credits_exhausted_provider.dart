/// 本地版：查词面板没有积分体系，这里只保留「某分节是否已提示过额度问题」
/// 的占位状态，永远是空表 —— 不读接口、不打网络。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LookupSectionId { translation, dictionary, contextualTranslation }

class LookupCreditsExhausted extends Notifier<Map<LookupSectionId, String>> {
  @override
  Map<LookupSectionId, String> build() => const <LookupSectionId, String>{};

  void report(LookupSectionId section, String message) {}

  void clear(LookupSectionId section) {}

  bool markSummaryToken(LookupSectionId section, Object? resultToken) => false;
}

final lookupCreditsExhaustedProvider =
    NotifierProvider<LookupCreditsExhausted, Map<LookupSectionId, String>>(
      LookupCreditsExhausted.new,
    );
