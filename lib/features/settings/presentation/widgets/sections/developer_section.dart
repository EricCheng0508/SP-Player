/// Developer row body — AI playground (debug builds only).
///
/// Extracted from `settings_screen.dart`'s Developer block. Non-release-
/// build gating (FR-005) is enforced by the caller, not this widget.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DeveloperSectionBody extends ConsumerWidget {
  const DeveloperSectionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          leadingIcon: EnjoyIcons.lab,
          title: l10n.settingsAiPlaygroundTileTitle,
          subtitle: l10n.settingsAiPlaygroundTileSubtitle,
          onTap: () => context.push('/settings/ai-playground'),
        ),
      ],
    );
  }
}
