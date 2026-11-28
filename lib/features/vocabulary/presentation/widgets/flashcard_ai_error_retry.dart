import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/flashcard_soft_error.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The AI-fetch surface shared by the flashcard's dictionary and contextual
/// tabs.
///
/// [error] is one of the `kVocabularyAiError*` sentinels: any failure shows
/// the generic AI-fetch message, and a null [error] shows neither. The retry
/// button always follows, so a failed fetch can be re-attempted in place.
class FlashcardAiErrorRetry extends StatelessWidget {
  const FlashcardAiErrorRetry({
    super.key,
    required this.error,
    required this.onRetry,
    required this.retryLabel,
  });

  final String? error;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          FlashcardSoftError(message: l10n.vocabularyAiFetchFailed),
          SizedBox(height: t.space8),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: EnjoyButton.secondary(
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ),
      ],
    );
  }
}
