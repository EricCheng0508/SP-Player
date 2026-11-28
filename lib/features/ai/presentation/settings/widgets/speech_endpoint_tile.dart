/// Clickable endpoint tile for the shared cloud speech service.
///
/// The tile shows the currently selected endpoint at a glance; tapping opens a
/// dialog that lists built-in endpoints and previously saved custom ones, with
/// an inline "new endpoint" form. No more hunting for a text field — and the
/// same list is reused by every section that needs the shared endpoint.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';

import 'dart:convert';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

class SpeechEndpoint {
  const SpeechEndpoint({required this.label, required this.baseUrl});

  final String label;
  final String baseUrl;

  Map<String, dynamic> toJson() => {'label': label, 'baseUrl': baseUrl};

  static SpeechEndpoint? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final label = raw['label'];
    final baseUrl = raw['baseUrl'];
    if (label is! String || baseUrl is! String || baseUrl.isEmpty) return null;
    return SpeechEndpoint(label: label, baseUrl: baseUrl);
  }
}

/// Built-in endpoints offered before any custom ones.
const List<SpeechEndpoint> kBuiltinSpeechEndpoints = [
  SpeechEndpoint(label: 'OpenAI 官方', baseUrl: 'https://api.openai.com/v1'),
  SpeechEndpoint(label: '本地 OpenAI 兼容服务', baseUrl: 'http://127.0.0.1:8080/v1'),
];

/// Persisted custom endpoints (device-scoped settings row).
final savedSpeechEndpointsProvider = FutureProvider<List<SpeechEndpoint>>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final raw = await db.settingsDao.readSetting(
    SettingsKeys.aiSavedSpeechEndpoints,
  );
  if (raw.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (SpeechEndpoint.fromJson(item) case final e?) e,
    ];
  } on FormatException {
    return const [];
  }
});

Future<void> saveSpeechEndpoints(
  WidgetRef ref,
  List<SpeechEndpoint> endpoints,
) async {
  final db = ref.read(appDatabaseProvider);
  await db.settingsDao.writeSetting(
    SettingsKeys.aiSavedSpeechEndpoints,
    jsonEncode([for (final e in endpoints) e.toJson()]),
  );
  ref.invalidate(savedSpeechEndpointsProvider);
}

/// Tile that opens the endpoint picker dialog.
class SpeechEndpointTile extends ConsumerWidget {
  const SpeechEndpointTile({
    super.key,
    required this.controller,
    required this.enabled,
  });

  /// Shared controller holding the selected base URL.
  final TextEditingController controller;

  /// False in Azure mode (region-based, no base URL).
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final value = controller.text.trim();
    final host = value.isEmpty
        ? '未选择'
        : value.replaceFirst(RegExp(r'^https?://'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('端点', style: tt.bodySmall?.copyWith(color: t.ink3)),
        const SizedBox(height: 6),
        EnjoyPressable(
          borderRadius: BorderRadius.circular(t.radiusTile),
          onTap: enabled ? () => _openPicker(context, ref) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: ShapeDecoration(
              color: enabled
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusTile),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  EnjoyIcons.route,
                  size: 17,
                  color: enabled ? cs.onSurfaceVariant : t.ink3,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(
                      color: value.isEmpty ? t.ink3 : t.ink,
                    ),
                  ),
                ),
                Icon(
                  EnjoyIcons.caretUpDown,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Azure Speech 用区域定位，无需端点地址',
              style: tt.bodySmall?.copyWith(color: t.ink3),
            ),
          ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final saved = ref.read(savedSpeechEndpointsProvider).value ?? const [];
    final manual = TextEditingController(text: controller.text.trim());
    var showManual = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          void pick(SpeechEndpoint endpoint) {
            controller.text = endpoint.baseUrl;
            Navigator.of(dialogCtx).pop();
          }

          Future<void> addAndPick() async {
            final url = manual.text.trim();
            if (url.isEmpty) return;
            final label = url.replaceFirst(RegExp(r'^https?://'), '');
            final next = [
              SpeechEndpoint(label: label, baseUrl: url),
              ...saved.where((e) => e.baseUrl != url),
            ];
            await saveSpeechEndpoints(ref, next);
            if (!dialogCtx.mounted) return;
            pick(SpeechEndpoint(label: label, baseUrl: url));
          }

          Widget option(SpeechEndpoint e) => EnjoyPressable(
            borderRadius: BorderRadius.circular(t.radiusTile),
            onTap: () => pick(e),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                children: [
                  Icon(EnjoyIcons.route, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.label, style: tt.bodyMedium),
                        Text(
                          e.baseUrl,
                          style: tt.bodySmall?.copyWith(color: t.ink3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (controller.text.trim() == e.baseUrl)
                    Icon(EnjoyIcons.check, size: 18, color: cs.primary),
                ],
              ),
            ),
          );

          return AlertDialog(
            title: const Text('选择端点'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (saved.isNotEmpty) ...[
                      Text(
                        '已保存',
                        style: tt.labelMedium?.copyWith(color: t.ink3),
                      ),
                      const SizedBox(height: 4),
                      for (final e in saved) option(e),
                      const SizedBox(height: 8),
                    ],
                    Text('常用', style: tt.labelMedium?.copyWith(color: t.ink3)),
                    const SizedBox(height: 4),
                    for (final e in kBuiltinSpeechEndpoints) option(e),
                    const SizedBox(height: 8),
                    const Divider(height: 16),
                    if (!showManual)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              setDialogState(() => showManual = true),
                          icon: const Icon(EnjoyIcons.add, size: 18),
                          label: const Text('新建端点'),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: manual,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'https://your-server/v1',
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: addAndPick,
                          child: const Text('保存并使用'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('取消'),
              ),
            ],
          );
        },
      ),
    );
    manual.dispose();
  }
}
