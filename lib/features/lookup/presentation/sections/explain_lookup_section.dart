/// Sentence-explanation lookup section — manual trigger.
///
/// Unlike the other lookup sections this one does NOT auto-fire on sheet
/// open (a word lookup shouldn't spend an LLM call on a full sentence
/// breakdown). It shows a run button; the result renders as markdown and is
/// cached through the shared `AiResultCache` hierarchy (AiKind.explain),
/// keyed on `(sentence, language pair, context)` — the same fingerprint the
/// force-refresh path invalidates.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/lookup_markdown_style.dart';
import 'package:enjoy_player/features/ai/application/ai_result_cache.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/line_explanation.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_params.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart'
    show lookupExplainCacheKey;
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_credits_reporting.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_section_error_widget.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_ai_section_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_refresh_icon_button.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ExplainLookupSection extends ConsumerWidget {
  const ExplainLookupSection({required this.request, super.key});

  final LookupRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = LookupExplainParams(
      text: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      context: request.contextualContext,
    );

    return LookupSectionShell(
      title: l10n.lookupSectionExplain,
      initiallyExpanded: false,
      leading: const Icon(EnjoyIcons.sparkle),
      surface: AuthRequiredSurface.lookupContextual,
      bodyBuilder: (_) => _ExplainFetchBody(params: params, l10n: l10n),
    );
  }
}

/// Manual-trigger fetch body, modeled on the contextual-translation section:
/// a single [Future] tied to [ConsumerState] (not an autoDispose provider),
/// results stored in [AiResultCache<LineExplanation>].
class _ExplainFetchBody extends ConsumerStatefulWidget {
  const _ExplainFetchBody({required this.params, required this.l10n});

  final LookupExplainParams params;
  final AppLocalizations l10n;

  @override
  ConsumerState<_ExplainFetchBody> createState() => _ExplainFetchBodyState();
}

class _ExplainFetchBodyState extends ConsumerState<_ExplainFetchBody> {
  static const Duration _timeout = Duration(seconds: 120);

  Future<LineExplanation>? _future;

  /// Last successful result; kept visible while a refresh is in flight.
  LineExplanation? _staleSuccess;

  /// Last failure; drives the retry-in-flight row until the retry completes.
  Object? _lastError;

  bool _retryInFlight = false;

  @override
  void dispose() {
    _silenceDetachedFuture(_future);
    super.dispose();
  }

  void _silenceDetachedFuture(Future<LineExplanation>? previous) {
    if (previous == null) return;
    unawaited(
      previous.then<void>(
        (_) {},
        // Superseded futures (refresh replaced by a newer fetch) may finish
        // late; their results are simply discarded.
        onError: (Object e, StackTrace st) {},
      ),
    );
  }

  Future<LineExplanation> _load({required bool forceRefresh}) {
    final p = widget.params;
    final cache = ref.read(aiExplainCacheProvider);
    final key = lookupExplainCacheKey(p);
    return cache.lookup(
      kind: AiKind.explain,
      key: key,
      sourceLanguage: p.sourceLanguage,
      targetLanguage: p.targetLanguage,
      loader: () => ref
          .read(explainServiceProvider)
          .explain(
            sentence: p.text,
            sourceLanguage: p.sourceLanguage,
            targetLanguage: p.targetLanguage,
            context: p.context,
          )
          .timeout(
            _timeout,
            onTimeout: () => throw TimeoutException(
              'Explain timed out after ${_timeout.inSeconds}s',
            ),
          ),
      forceRefresh: forceRefresh,
    );
  }

  void _run({required bool forceRefresh}) {
    _silenceDetachedFuture(_future);
    _future = _load(forceRefresh: forceRefresh);
    if (mounted) setState(() {});
  }

  void _retryAfterError() {
    setState(() => _retryInFlight = true);
    _run(forceRefresh: true);
  }

  Widget _resultStack({
    required bool isRefreshing,
    required VoidCallback onRefresh,
    required Widget body,
  }) {
    final t = EnjoyThemeTokens.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(end: t.space40),
          child: body,
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: LookupRefreshIconButton(
            l10n: widget.l10n,
            isRetrying: isRefreshing,
            onRetry: onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _markdownBody(LineExplanation d) {
    final t = EnjoyThemeTokens.of(context);
    final mdStyle = buildLookupMarkdownStyleSheet(context, t);
    if (d.text.trim().isEmpty) {
      return Text(
        widget.l10n.lookupEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return MarkdownBody(data: d.text, selectable: true, styleSheet: mdStyle);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      // Manual trigger: the run button instead of the auto-fetch shimmer.
      return Center(
        child: EnjoyButton.tonal(
          onPressed: () => _run(forceRefresh: false),
          child: Text(widget.l10n.lookupExplainRun),
        ),
      );
    }
    return FutureBuilder<LineExplanation>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          if (_staleSuccess != null) {
            final d = _staleSuccess!;
            return _resultStack(
              isRefreshing: true,
              onRefresh: () => _run(forceRefresh: true),
              body: _markdownBody(d),
            );
          }
          if (_retryInFlight && _lastError != null) {
            return lookupSectionErrorWidget(
              context: context,
              ref: ref,
              l10n: widget.l10n,
              section: LookupSectionId.explain,
              surface: AuthRequiredSurface.lookupContextual,
              error: _lastError!,
              onRetry: _retryAfterError,
              isRetrying: true,
            );
          }
          return const LookupSectionShimmer();
        }
        if (snapshot.hasError) {
          final e = snapshot.error!;
          _staleSuccess = null;
          _retryInFlight = false;
          _lastError = e;
          return lookupSectionErrorWidget(
            context: context,
            ref: ref,
            l10n: widget.l10n,
            section: LookupSectionId.explain,
            surface: AuthRequiredSurface.lookupContextual,
            error: e,
            onRetry: _retryAfterError,
          );
        }
        final d = snapshot.data!;
        _staleSuccess = d;
        _retryInFlight = false;
        _lastError = null;
        scheduleLookupCreditsClear(
          context,
          ref,
          LookupSectionId.explain,
          resultToken: d,
        );
        return _resultStack(
          isRefreshing: false,
          onRefresh: () => _run(forceRefresh: true),
          body: _markdownBody(d),
        );
      },
    );
  }
}
