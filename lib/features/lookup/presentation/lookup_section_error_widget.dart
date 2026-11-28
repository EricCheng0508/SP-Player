library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/lookup/domain/lookup_section_id.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Renders the shared error surface for a lookup sheet section
/// (translation, dictionary, contextual translation, explain): a
/// [LookupErrorRow] with the [lookupErrorUserMessage] copy for the error.
Widget lookupSectionErrorWidget({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required LookupSectionId section,
  required AuthRequiredSurface surface,
  required Object error,
  required VoidCallback onRetry,
  bool isRetrying = false,
}) {
  return LookupErrorRow(
    message: lookupErrorUserMessage(error, l10n),
    onRetry: onRetry,
    isRetrying: isRetrying,
  );
}
