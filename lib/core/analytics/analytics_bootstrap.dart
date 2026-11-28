/// One-shot product analytics initialization (specs/046, research D8).
///
/// Fire-and-forget from `EnjoyApp`'s first init: vendor setup and super
/// properties. Nothing here is ever awaited on the startup path — `runApp`
/// and the first frame never wait for it. The keepAlive provider builds
/// exactly once, so re-reads are idempotent.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/analytics/analytics_config.dart';
import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/analytics/posthog_analytics.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/release/distribution_channel.dart';

part 'analytics_bootstrap.g.dart';

final Logger _log = logNamed('analytics');

@Riverpod(keepAlive: true)
Future<void> analyticsInit(Ref ref) async {
  final analytics = ref.read(analyticsProvider);
  if (analytics is! PosthogAnalytics) {
    _log.info('analytics: inert (unsupported platform or no token configured)');
    return;
  }

  final config = PostHogConfig(kPostHogApiKey)
    ..host = kPostHogHost
    ..debug = kDebugMode
    ..onFeatureFlags = () {
      if (kDebugMode) _log.info('analytics: feature flags loaded');
    };
  await analytics.setup(config);

  await _registerSuperProperties(ref, analytics);
}

Future<void> _registerSuperProperties(
  Ref ref,
  PosthogAnalytics analytics,
) async {
  try {
    final prefs = await ref.read(appPreferencesCtrlProvider.future);
    await analytics.registerSuperProperties({
      AnalyticsEvents.propDisplayLocale: prefs.effectiveDisplayLocale
          .toLanguageTag(),
      AnalyticsEvents.propLearningLanguage: prefs.effectiveLearningLanguage,
      AnalyticsEvents.propDistributionChannel:
          resolveDistributionChannel().name,
    });
  } on Object catch (error, stack) {
    _log.warning('analytics: super properties not registered', error, stack);
  }
}
