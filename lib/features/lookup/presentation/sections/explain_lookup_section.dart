/// Sentence-explanation lookup section — auto-runs on expand.
///
/// The fetch state lives on the section widget (not the shell body), so
/// collapsing and re-expanding keeps the previous result visible instead of
/// resetting to a run button. The first expand auto-fires the request — the
/// user tapped "讲解这句" deliberately, so a second confirmation click adds
/// nothing. Results are cached through the shared `AiResultCache` hierarchy
/// (AiKind.explain), keyed on `(sentence, language pair, context)` — the same
/// fingerprint the force-refresh path invalidates.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
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

class ExplainLookupSection extends ConsumerStatefulWidget {
  const ExplainLookupSection({required this.request, super.key});

  final LookupRequest request;

  @override
  ConsumerState<ExplainLookupSection> createState() =>
      _ExplainLookupSectionState();
}

class _ExplainLookupSectionState extends ConsumerState<ExplainLookupSection> {
  static const Duration _timeout = Duration(seconds: 120);

  Future<LineExplanation>? _future;

  /// Last successful result; kept visible while a refresh is in flight.
  LineExplanation? _staleSuccess;

  /// Last failure; drives the retry-in-flight row until the retry completes.
  Object? _lastError;

  bool _retryInFlight = false;

  @override
  void didUpdateWidget(ExplainLookupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.request;
    final now = widget.request;
    final changed = old.selectedText != now.selectedText ||
        old.sourceLanguage != now.sourceLanguage ||
        old.targetLanguage != now.targetLanguage ||
        old.contextualContext != now.contextualContext;
    if (changed) _reset();
  }

  void _reset() {
    _silenceDetachedFuture(_future);
    _future = null;
    _staleSuccess = null;
    _lastError = null;
    _retryInFlight = false;
  }

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
    final request = widget.request;
    final p = LookupExplainParams(
      text: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      context: request.contextualContext,
    );
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
            l10n: l10n,
            isRetrying: isRefreshing,
            onRetry: onRefresh,
          ),
        ),
      ],
    );
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Widget _buildBody(BuildContext context) {
    final future = _future;
    if (future == null) {
      // First expand: auto-fire so the explanation streams in without a
      // second click. Shimmer covers the wait.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _future == null) _run(forceRefresh: false);
      });
      return const LookupSectionShimmer();
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
              l10n: l10n,
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
            l10n: l10n,
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

  Widget _markdownBody(LineExplanation d) {
    final t = EnjoyThemeTokens.of(context);
    final mdStyle = buildLookupMarkdownStyleSheet(context, t);
    if (d.text.trim().isEmpty) {
      return Text(
        l10n.lookupEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return MarkdownBody(data: d.text, selectable: true, styleSheet: mdStyle);
  }

  @override
  Widget build(BuildContext context) {
    return LookupSectionShell(
      title: l10n.lookupSectionExplain,
      initiallyExpanded: false,
      leading: const Icon(EnjoyIcons.sparkle),
      surface: AuthRequiredSurface.lookupContextual,
      bodyBuilder: _buildBody,
    );
  }
}
