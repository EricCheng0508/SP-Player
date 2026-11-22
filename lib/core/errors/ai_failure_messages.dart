/// 额度失败提示（本地版）。
///
/// 上游把「积分不足」统一收口在这个文件里，并给出跳转订阅页的 CTA。
/// 本地版没有积分、没有订阅页，所以这里只保留同名的 message/label 构造函数
/// （调用点无需改动），CTA 一律不显示 —— 也不可能出现额度不足的失败。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// 额度不足时给用户看的话术。本地版不会走到这里，兜底返回通用提示。
String creditsFailureMessage(CreditsFailure failure, AppLocalizations l10n) =>
    failure.message.isEmpty ? 'AI 调用失败，请检查模型端点配置' : failure.message;

/// CTA 文案。本地版没有订阅页，返回空串。
String creditsCtaLabel(AppLocalizations l10n) => '';

/// 兼容上游的按钮样式枚举。
enum CreditsCtaStyle { text, brand, ghost }

/// 本地版不提供任何「去升级」入口：渲染为空。
class CreditsCtaButton extends StatelessWidget {
  const CreditsCtaButton({super.key, this.style = CreditsCtaStyle.text});

  final CreditsCtaStyle style;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 本地版没有可跳转的目标，返回 null。
AppNoticeAction? creditsCtaAction(GoRouter router, AppLocalizations l10n) =>
    null;
