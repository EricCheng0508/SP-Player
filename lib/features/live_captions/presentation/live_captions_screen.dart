/// Live captions screen: history rail (left) + listening surface (right).
///
/// Mirrors the approved mockup (mockups/live-captions-ui.html): status pill,
/// source chips, translate toggle, bilingual caption cards with the in-flight
/// "listening" placeholder, and a compact engine/latency status bar.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/live_captions/application/live_captions_controller.dart';
import 'package:enjoy_player/features/live_captions/data/live_captions_store.dart';
import 'package:enjoy_player/features/live_captions/domain/live_caption_models.dart';

class LiveCaptionsScreen extends ConsumerStatefulWidget {
  const LiveCaptionsScreen({super.key});

  @override
  ConsumerState<LiveCaptionsScreen> createState() =>
      _LiveCaptionsScreenState();
}

class _LiveCaptionsScreenState extends ConsumerState<LiveCaptionsScreen> {
  LiveCaptionSession? _viewing; // null = current/live session
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Entering the page opens a fresh conversation (kept when a run is
      // already in progress so we never tear down live capture on re-entry).
      unawaited(
        ref.read(liveCaptionsControllerProvider.notifier).beginNewSession(),
      );
      unawaited(ref.read(liveCaptionsHistoryProvider.notifier).reload());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final state = ref.watch(liveCaptionsControllerProvider);
    final history =
        ref.watch(liveCaptionsHistoryProvider).asData?.value ?? const [];

    final shown = _viewing ?? state.session;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // History rail.
          SizedBox(
            width: 264,
            child: _HistoryRail(
              sessions: history,
              viewingId: _viewing?.id,
              currentId: state.session?.id,
              onSelect: (session) => setState(() => _viewing = session),
              onNew: () {
                setState(() => _viewing = null);
                unawaited(
                  ref
                      .read(liveCaptionsControllerProvider.notifier)
                      .beginNewSession(),
                );
              },
              onDelete: (session) async {
                await ref.read(liveCaptionsStoreProvider).delete(session.id);
                if (identical(_viewing, session)) _viewing = null;
                await ref.read(liveCaptionsHistoryProvider.notifier).reload();
              },
              onExport: (session) async {
                final path = await ref
                    .read(liveCaptionsStoreProvider)
                    .exportText(session);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('已导出到 $path')),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Main surface.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(state: state),
                  Expanded(
                    child: shown == null
                        ? const SizedBox.shrink()
                        : _CaptionStream(
                            session: shown,
                            live: identical(shown, state.session),
                            scroll: _scroll,
                            onRetryTranslation:
                                identical(shown, state.session)
                                    ? (line) => ref
                                        .read(
                                          liveCaptionsControllerProvider
                                              .notifier,
                                        )
                                        .retryTranslation(line)
                                    : null,
                          ),
                  ),
                  _StatusBar(state: state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History rail
// ---------------------------------------------------------------------------

final class _HistoryRail extends StatelessWidget {
  const _HistoryRail({
    required this.sessions,
    required this.viewingId,
    required this.currentId,
    required this.onSelect,
    required this.onNew,
    required this.onDelete,
    required this.onExport,
  });

  final List<LiveCaptionSession> sessions;
  final String? viewingId;
  final String? currentId;
  final void Function(LiveCaptionSession) onSelect;
  final void Function() onNew;
  final void Function(LiveCaptionSession) onDelete;
  final void Function(LiveCaptionSession) onExport;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                '历史会话',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${sessions.length}',
                style: enjoyMonoStyle(context, size: 12, color: t.ink3),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: FilledButton.tonalIcon(
            onPressed: onNew,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新会话'),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Text(
                    '还没有历史会话',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: t.ink3),
                  ),
                )
              : ListView.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final selected =
                        session.id == viewingId || session.id == currentId;
                    return _SessionCard(
                      session: session,
                      selected: selected,
                      inProgress: session.id == currentId,
                      onTap: () => onSelect(session),
                      onDelete: () => onDelete(session),
                      onExport: () => onExport(session),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

final class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.selected,
    required this.inProgress,
    required this.onTap,
    required this.onDelete,
    required this.onExport,
  });

  final LiveCaptionSession session;
  final bool selected;
  final bool inProgress;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final preview = session.lines.isEmpty
        ? '（暂无内容）'
        : session.lines.first.text;
    return Material(
      color: selected ? t.sunk : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? t.brandInk : t.line,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    session.title,
                    style: enjoyMonoStyle(
                      context,
                      size: 12.5,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (inProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: ShapeDecoration(
                        color: t.youSoft,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '进行中',
                        style: TextStyle(
                          fontSize: 10,
                          color: t.youInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  _CardMenu(
                    onDelete: onDelete,
                    onExport: onExport,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: t.ink2),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmtDuration(session.duration)} · ${session.lines.length} 句'
                '${session.translated ? ' · 已译' : ''}',
                style: enjoyMonoStyle(context, size: 11, color: t.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '$m 分钟' : '$m 分 ${s.toString().padLeft(2, '0')} 秒';
  }
}

final class _CardMenu extends StatelessWidget {
  const _CardMenu({required this.onDelete, required this.onExport});

  final VoidCallback onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 18,
      onSelected: (value) {
        if (value == 'delete') onDelete();
        if (value == 'export') onExport();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'export', child: Text('导出文本')),
        PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header / controls
// ---------------------------------------------------------------------------

final class _Header extends ConsumerStatefulWidget {
  const _Header({required this.state});

  final LiveCaptionsState state;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final state = widget.state;
    final listening = state.phase == LiveCaptionsPhase.listening ||
        state.phase == LiveCaptionsPhase.starting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Text(
            '实时字幕',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          if (listening)
            _StatusPill(
              listening: true,
              label: state.phase == LiveCaptionsPhase.starting
                  ? '启动中…'
                  : '监听中',
            ),
          const Spacer(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                state.error!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          OutlinedButton.icon(
            onPressed: listening
                ? () => ref.read(liveCaptionsControllerProvider.notifier).stop()
                : () =>
                    ref.read(liveCaptionsControllerProvider.notifier).start(),
            icon: Icon(
              listening ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: listening ? Colors.red.shade700 : t.brandInk,
            ),
            label: Text(listening ? '停止' : '开始监听'),
          ),
        ],
      ),
    );
  }
}

final class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.listening, required this.label});

  final bool listening;
  final String label;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: t.youSoft,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_breath),
            child: Icon(Icons.fiber_manual_record,
                size: 10, color: Colors.green.shade700),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.youInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls row: source chips + translate toggle (always visible)
// ---------------------------------------------------------------------------

final class _ControlsRow extends ConsumerWidget {
  const _ControlsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final state = ref.watch(liveCaptionsControllerProvider);
    final controller = ref.read(liveCaptionsControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _SourceChip(
            label: '系统声音（不含麦克风）',
            checked: state.systemEnabled,
            onTap: () => controller.setSystemEnabled(!state.systemEnabled),
          ),
          const SizedBox(width: 8),
          _SourceChip(
            label: '麦克风',
            checked: state.micEnabled,
            onTap: () => controller.setMicEnabled(!state.micEnabled),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: state.translate,
                onChanged: (v) => controller.setTranslate(v),
              ),
              const SizedBox(width: 4),
              Text('翻译', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 6),
              Text(
                '关闭后仅显示原文',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: t.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: checked ? t.brandInk.withValues(alpha: 0.10) : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: checked ? t.brandInk : t.line),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checked)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 14, color: t.brandInk),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                color: checked ? t.brandInk : t.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caption stream
// ---------------------------------------------------------------------------

final class _CaptionStream extends ConsumerWidget {
  const _CaptionStream({
    required this.session,
    required this.live,
    required this.scroll,
    required this.onRetryTranslation,
  });

  final LiveCaptionSession session;
  final bool live;
  final ScrollController scroll;
  final void Function(LiveCaptionLine)? onRetryTranslation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(liveCaptionsControllerProvider);
    final translate = controllerState.translate;
    final listening = controllerState.phase == LiveCaptionsPhase.listening ||
        controllerState.phase == LiveCaptionsPhase.starting;
    final lines = session.lines;

    return Column(
      children: [
        const _ControlsRow(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              Text(
                session.title,
                style: enjoyMonoStyle(context, size: 12, weight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                session.sources.isEmpty
                    ? '未选择监听来源'
                    : session.sources
                        .map((s) =>
                            s == LiveCaptionSource.system ? '系统声音' : '麦克风')
                        .join(' + '),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: lines.isEmpty
              ? _EmptyState(
                  listening: listening,
                  idle: controllerState.phase == LiveCaptionsPhase.idle,
                  onStart: () => ref
                      .read(liveCaptionsControllerProvider.notifier)
                      .start(),
                )
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: lines.length + (live && listening ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == lines.length) {
                      return const _ListeningPlaceholder();
                    }
                    return _CaptionCard(
                      line: lines[index],
                      showTranslation: translate,
                      onRetry: onRetryTranslation == null
                          ? null
                          : () => onRetryTranslation!(lines[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Empty session: guidance while idle, "waiting for speech" while listening.
final class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.listening,
    required this.idle,
    required this.onStart,
  });

  final bool listening;
  final bool idle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EnjoyIcons.cc, size: 44, color: t.ink3.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          if (listening)
            const Text('正在聆听，说几句话试试…')
          else ...[
            const Text('勾选监听来源，点「开始监听」'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('开始监听'),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '字幕会比说话晚 2~4 秒出现（本地识别的自然延迟）',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: t.ink3),
          ),
        ],
      ),
    );
  }
}

final class _ListeningPlaceholder extends StatefulWidget {
  const _ListeningPlaceholder();

  @override
  State<_ListeningPlaceholder> createState() => _ListeningPlaceholderState();
}

class _ListeningPlaceholderState extends State<_ListeningPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: t.line,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: FadeTransition(
                opacity: Tween(begin: 0.25, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _wave,
                    curve: Interval(i * 0.12, i * 0.12 + 0.4,
                        curve: Curves.easeInOut),
                  ),
                ),
                child: Container(
                  width: 3,
                  height: 14 + (i % 3) * 4,
                  decoration: ShapeDecoration(
                    color: t.brandInk,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '正在聆听…',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: t.ink3),
          ),
        ],
      ),
    );
  }
}

final class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.line,
    required this.showTranslation,
    required this.onRetry,
  });

  final LiveCaptionLine line;
  final bool showTranslation;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final offset = Duration(seconds: line.offsetSeconds.round());
    final mm = offset.inMinutes.toString().padLeft(2, '0');
    final ss = (offset.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.sunk.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '$mm:$ss',
              style: enjoyMonoStyle(context, size: 11.5, color: t.ink3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.35),
                ),
                if (showTranslation)
                  Builder(builder: (context) {
                    final tr = line.translation;
                    if (tr != null && tr.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: ShapeDecoration(
                                color: t.brandInk.withValues(alpha: 0.10),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                ),
                              ),
                              child: Text(
                                '译',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: t.brandInk,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: t.ink2,
                                      height: 1.35,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (line.failedTranslation) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: onRetry,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              '翻译失败 · 点击重试',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '翻译中…',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: t.ink3),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom status bar
// ---------------------------------------------------------------------------

final class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final LiveCaptionsState state;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final listening = state.phase == LiveCaptionsPhase.listening;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(color: t.ink3, fontSize: 11.5),
        child: Row(
          children: [
            const Text('识别：本地 Whisper'),
            const SizedBox(width: 14),
            Text('翻译：${state.translate ? '已配置 LLM' : '已关闭'}'),
            const SizedBox(width: 14),
            const Text('延迟约 2~4 秒'),
            const Spacer(),
            if (listening && state.session != null)
              Text('${state.session!.lines.length} 句'),
          ],
        ),
      ),
    );
  }
}
