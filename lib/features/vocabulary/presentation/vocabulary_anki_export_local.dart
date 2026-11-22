/// 本地版：Anki 导出依赖订阅权益，已随订阅体系一并移除。
library;

import 'package:flutter/widgets.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';

void showVocabularyAnkiExportDialog(BuildContext context) {
  AppNotice.error(context, '本地版已移除 Anki 导出（依赖订阅权益）');
}
