/// 本地版：查词面板不再有积分概念，上报函数全部空实现。
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';

void scheduleLookupCreditsReport(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section,
  String message, {
  Object? resultToken,
}) {}

void scheduleLookupCreditsClear(
  BuildContext context,
  WidgetRef ref,
  LookupSectionId section, {
  Object? resultToken,
}) {}
