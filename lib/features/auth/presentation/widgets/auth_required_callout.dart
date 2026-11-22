/// 本地版：查词/翻译面板不再要求登录。
///
/// 上游在这里提示「登录后才能用 AI」，本地版没有账号体系，所以改为
/// 提示用户去设置里填自己的模型端点。类名与枚举沿用上游，调用点无需改动。
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

enum AuthRequiredSurface {
  lookupTranslation,
  lookupDictionary,
  lookupContextual,
}

/// 提示用户先在设置里配置自己的模型端点。
class AuthRequiredCallout extends StatelessWidget {
  const AuthRequiredCallout({
    required this.surface,
    this.compact = true,
    super.key,
  });

  final AuthRequiredSurface surface;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 2 : t.space16,
        vertical: compact ? 6 : t.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(EnjoyIcons.sparkle, size: 15, color: t.ink3),
          SizedBox(width: t.space8),
          Expanded(
            child: Text(
              '需要先在「设置 → AI → 语言模型」里填写自己的端点，'
              '翻译和查词都走这个模型。',
              style: tt.bodySmall?.copyWith(color: t.ink3, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
