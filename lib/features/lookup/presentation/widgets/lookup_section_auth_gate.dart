/// 本地版：查词/翻译面板不再有登录门禁，直接渲染正文。
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/features/lookup/presentation/widgets/auth_required_callout.dart';

/// 原本按登录态分流，本地版一律放行 —— 查词、翻译、词典全部走用户自备的
/// 模型端点，与 Enjoy 账号无关。
class LookupSectionAuthGate extends StatelessWidget {
  const LookupSectionAuthGate({
    required this.surface,
    required this.child,
    super.key,
  });

  /// 保留字段以兼容既有调用点（本地模式下不再使用）。
  final AuthRequiredSurface surface;

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
