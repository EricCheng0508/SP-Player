/// AI section body — the engine picker itself, embedded inline so opening
/// 设置 → AI lands directly on model selection (no extra navigation row).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/features/ai/presentation/settings/ai_providers_screen.dart';

class AiProvidersSectionBody extends StatelessWidget {
  const AiProvidersSectionBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiEnginesBody();
  }
}
