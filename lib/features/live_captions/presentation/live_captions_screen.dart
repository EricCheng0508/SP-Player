/// Live captions screen: history rail (left) + listening surface (right).
///
/// Mirrors the approved mockup (mockups/live-captions-ui.html): status pill,
/// source chips, translate toggle, bilingual caption cards with the in-flight
/// "listening" placeholder, and a compact engine/latency status bar.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
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
  final _scroll = ScrollController();
  bool _railCollapsed = false;

  LiveCaptionSession? _resolveShown(
    LiveCaptionsState state,
    List<LiveCaptionSession> history,
  ) {
    final id = ref.watch(liveCaptionsViewingIdProvider);
    if (id == null || identical(state.session?.id, id)) return state.session;
    for (final s in history) {
      if (s.id == id) return s;
    }
    return state.session;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Nothing is created on entry: the right pane shows an empty guide
      // until the user clicks 「新会话」.
      unawaited(ref.read(liveCaptionsHistoryProvider.notifier).reload());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确定删除这条会话及其全部字幕记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final state = ref.watch(liveCaptionsControllerProvider);
    final historyNotifier = ref.read(liveCaptionsHistoryProvider.notifier);
    final history =
        ref.watch(liveCaptionsHistoryProvider).asData?.value ?? const [];

    final shown = _resolveShown(state, history);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // History rail (mockup 方案 B): hidden entirely while the app
          // sidebar is collapsed — sessions live in the sidebar flyout.
          if (!ref.watch(sidebarCollapsedProvider)) ...[
          if (_railCollapsed) ...[
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  SizedBox(
                    height: 34,
                    child: IconButton(
                      tooltip: '展开历史会话',
                      onPressed: () => setState(() => _railCollapsed = false),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 34,
                    child: IconButton(
                      tooltip: '新会话',
                      onPressed: () {
                      ref
                          .read(liveCaptionsViewingIdProvider.notifier)
                          .state = null;
                      unawaited(
                        () async {
                          final notifier = ref
                              .read(liveCaptionsControllerProvider.notifier);
                          await notifier.beginNewSession();
                          await notifier.start();
                          await historyNotifier.reload();
                        }(),
                      );
                    },
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
          SizedBox(
            width: 264,
            child: _HistoryRail(
              sessions: history,
              onCollapse: () => setState(() => _railCollapsed = true),
              currentSession: state.session,
              listening: state.phase == LiveCaptionsPhase.listening ||
                  state.phase == LiveCaptionsPhase.starting,
              viewingId: ref.watch(liveCaptionsViewingIdProvider),
              onSelect: (session) => ref
                  .read(liveCaptionsViewingIdProvider.notifier)
                  .state = identical(session, state.session)
                  ? null
                  : session.id,
              onNew: () {
                ref
                    .read(liveCaptionsViewingIdProvider.notifier)
                    .state = null;
                unawaited(
                  () async {
                    final notifier = ref
                        .read(liveCaptionsControllerProvider.notifier);
                    await notifier.beginNewSession();
                    // A new session means "start listening now".
                    await notifier.start();
                    await historyNotifier.reload();
                  }(),
                );
              },
              onDelete: (session) async {
                final confirmed = await _confirmDelete(context);
                if (!confirmed) return;
                // Controller stops capture + drops the in-memory session
                // when the live one is deleted (no resurrect-by-save).
                await ref
                    .read(liveCaptionsControllerProvider.notifier)
                    .deleteSession(session);
                if (!mounted) return;
                if (ref.read(liveCaptionsViewingIdProvider) == session.id) {
                  ref.read(liveCaptionsViewingIdProvider.notifier).state =
                      null;
                }
                await historyNotifier.reload();
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
          ],
          ],

          // Main surface.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: shown == null
                  ? _EmptyGuide(onNew: () {
                      ref
                          .read(liveCaptionsViewingIdProvider.notifier)
                          .state = null;
                      unawaited(
                        () async {
                          final notifier = ref
                              .read(liveCaptionsControllerProvider.notifier);
                          await notifier.beginNewSession();
                          await notifier.start();
                          await historyNotifier.reload();
                        }(),
                      );
                    })
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(state: state),
                        Expanded(
                          child: _CaptionStream(
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
// Empty guide (no session yet — before the first 「新会话」 click)
// ---------------------------------------------------------------------------

final class _EmptyGuide extends StatelessWidget {
  const _EmptyGuide({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EnjoyIcons.cc, size: 44, color: t.ink3),
          const SizedBox(height: 14),
          Text(
            '还没有会话',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '点击「新会话」开始监听系统声音或麦克风，\n实时生成中英双语字幕。',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: t.ink3, height: 1.6),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新会话'),
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
    required this.currentSession,
    required this.listening,
    required this.viewingId,
    required this.onSelect,
    required this.onNew,
    required this.onDelete,
    required this.onExport,
    required this.onCollapse,
  });

  final List<LiveCaptionSession> sessions;

  /// The in-memory session for this page visit, pinned at the top of the rail
  /// so 「新会话」 always has a visible counterpart on the left.
  final LiveCaptionSession? currentSession;
  final bool listening;
  final String? viewingId;
  final void Function(LiveCaptionSession) onSelect;
  final VoidCallback onCollapse;
  final void Function() onNew;
  final void Function(LiveCaptionSession) onDelete;
  final void Function(LiveCaptionSession) onExport;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    // The current visit's session is pinned right under the button so the
    // left rail and the right pane always agree on "what is open now".
    final current = currentSession;
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
              IconButton(
                tooltip: '折叠历史会话',
                onPressed: onCollapse,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
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
        if (current != null) ...[
          _SessionCard(
            session: current,
            selected: viewingId == null,
            inProgress: listening,
            onTap: () => onSelect(current),
            onDelete: () => onDelete(current),
            onExport: () => onExport(current),
          ),
          const SizedBox(height: 8),
        ],
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
                    if (session.id == currentSession?.id) {
                      return const SizedBox.shrink(); // pinned above already
                    }
                    final selected = session.id == viewingId;
                    return _SessionCard(
                      session: session,
                      selected: selected,
                      inProgress: false,
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
                ? () {
                    unawaited(
                      ref
                          .read(liveCaptionsControllerProvider.notifier)
                          .stop()
                          .whenComplete(
                            ref.read(liveCaptionsHistoryProvider.notifier).reload,
                          ),
                    );
                  }
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
          if (isDesktop)
            IconButton(
              tooltip: '悬浮字幕（置顶小窗，Esc 退出）',
              onPressed: () => unawaited(enterFloatMode(ref)),
              icon: const Icon(Icons.picture_in_picture_alt_rounded,
                  size: 18),
              style: IconButton.styleFrom(
                foregroundColor: t.brandInk,
              ),
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
            label: '🔊 监听扬声器',
            checked: state.systemEnabled,
            onTap: () => controller.setSystemEnabled(!state.systemEnabled),
          ),
          const SizedBox(width: 8),
          _SourceChip(
            label: '🎤 监听麦克风',
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

/// Chat-style stream (mockup v5): system → left white bubbles, mic →
/// right green bubbles; listen-toggle events render as grey dividers.
/// Auto-follow with a 「回到最新」 pill once the user scrolls up.
final class _CaptionStream extends ConsumerStatefulWidget {
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
  ConsumerState<_CaptionStream> createState() => _CaptionStreamState();
}

class _CaptionStreamState extends ConsumerState<_CaptionStream> {
  bool _follow = true;
  double _lastMax = 0;

  ScrollController get _scroll => widget.scroll;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;
    if (atBottom != _follow && mounted) setState(() => _follow = atBottom);
    _lastMax = _scroll.position.maxScrollExtent;
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    unawaited(_scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ));
    if (mounted) setState(() => _follow = true);
  }

  List<_StreamItem> _buildItems(List<LiveCaptionLine> lines) =>
      buildLiveStreamItems(lines);

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(liveCaptionsControllerProvider);
    final translate = controllerState.translate;
    final listening = controllerState.phase == LiveCaptionsPhase.listening ||
        controllerState.phase == LiveCaptionsPhase.starting;
    final lines = widget.session.lines;
    final items = _buildItems(lines);

    // Auto-follow: snap to the new bottom when already at it.
    if (_follow && widget.live && listening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        if (_scroll.position.maxScrollExtent > _lastMax) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
          _lastMax = _scroll.position.maxScrollExtent;
        }
      });
    }

    return Stack(
      children: [
        Column(
          children: [
            const _ControlsRow(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  Text(
                    widget.session.title,
                    style: enjoyMonoStyle(context,
                        size: 12, weight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.session.sources.isEmpty
                        ? '未选择监听来源'
                        : widget.session.sources
                            .map((s) => s == LiveCaptionSource.system
                                ? '监听扬声器'
                                : '监听麦克风')
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
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      itemCount: items.length +
                          (widget.live && listening ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return const _ListeningPlaceholder();
                        }
                        final item = items[index];
                        if (item is _DividerItem) {
                          return _EventDivider(line: item.line);
                        }
                        if (item is _BubbleItem) {
                          return _ChatBubble(
                            item: item,
                            showTranslation: translate,
                            onRetryLine: widget.onRetryTranslation,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
        if (!_follow && widget.live && listening)
          Positioned(
            right: 18,
            bottom: 16,
            child: FilledButton.tonalIcon(
              onPressed: _jumpToBottom,
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: const Text('回到最新'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 3,
              ),
            ),
          ),
      ],
    );
  }
}

/// Consecutive same-source lines within 5 s merge into one bubble; event
/// rows become dividers. Shared by the in-page stream and the float window.
List<_StreamItem> buildLiveStreamItems(List<LiveCaptionLine> lines) {
  final items = <_StreamItem>[];
  _BubbleItem? open;
  for (final line in lines) {
    if (line.event != null) {
      open = null;
      items.add(_DividerItem(line));
      continue;
    }
    if (open != null &&
        open.source == line.source &&
        line.offsetSeconds - open.lines.last.offsetSeconds < 5) {
      open.lines.add(line);
    } else {
      open = _BubbleItem([line]);
      items.add(open);
    }
  }
  return items;
}

/// Chat stream items: merged bubbles + event dividers.
sealed class _StreamItem {}

class _BubbleItem extends _StreamItem {
  _BubbleItem(this.lines);

  final List<LiveCaptionLine> lines;

  LiveCaptionSource get source => lines.first.source;

  String get text => [for (final l in lines) l.text].join(' ');

  String? get translation => lines.any((l) => l.translation == null)
      ? null
      : [for (final l in lines) l.translation!].join(' ');

  bool get failed => lines.every((l) => l.failedTranslation);

  bool get starred => lines.any((l) => l.starred);

  LiveCaptionLine? get failedLine =>
      lines.where((l) => l.failedTranslation).firstOrNull;
}

class _DividerItem extends _StreamItem {
  _DividerItem(this.line);

  final LiveCaptionLine line;
}

final class _EventDivider extends StatelessWidget {
  const _EventDivider({required this.line});

  final LiveCaptionLine line;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: ShapeDecoration(
            color: t.sunk.withValues(alpha: 0.7),
            shape: StadiumBorder(side: BorderSide(color: t.line)),
          ),
          child: Text(
            line.event ?? line.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: t.ink3,
                  fontSize: 11.5,
                ),
          ),
        ),
      ),
    );
  }
}
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
            '字幕会比说话晚 1~3 秒出现（本地识别的自然延迟）',
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

/// One chat bubble (mockup v5): mic → right green, system → left white.
/// Tap text to copy; right-click / long-press opens 复制/收藏 actions.
final class _ChatBubble extends ConsumerWidget {
  const _ChatBubble({
    required this.item,
    required this.showTranslation,
    required this.onRetryLine,
  });

  final _BubbleItem item;
  final bool showTranslation;
  final void Function(LiveCaptionLine)? onRetryLine;

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
    );
  }

  void _toggleStar(BuildContext context, WidgetRef ref) {
    for (final line in item.lines) {
      line.starred = !item.starred;
    }
    // Trigger a rebuild; the session JSON persists stars on the next save.
    ref.read(liveCaptionsControllerProvider.notifier).touch();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.starred ? '已收藏本段' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openMenu(BuildContext context, WidgetRef ref, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 8, position.dy + 8),
      items: [
        const PopupMenuItem(value: 'copyEn', child: Text('复制原文')),
        if (showTranslation && item.translation != null)
          const PopupMenuItem(value: 'copyZh', child: Text('复制译文')),
        PopupMenuItem(
          value: 'star',
          child: Text(item.starred ? '取消收藏本段' : '★ 收藏本段'),
        ),
      ],
    ).then((value) {
      if (value == 'copyEn') _copy(context, item.text);
      if (value == 'copyZh' && item.translation != null) {
        _copy(context, item.translation!);
      }
      if (value == 'star') _toggleStar(context, ref);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final me = item.source == LiveCaptionSource.mic;
    final pending = item.translation == null && !item.failed;
    final failedLine = item.failedLine;

    final enText = SelectionArea(
      child: GestureDetector(
        onTap: () => _copy(context, item.text),
        child: Text(
          item.text,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
    );

    final Widget zhWidget;
    if (!showTranslation) {
      zhWidget = const SizedBox.shrink();
    } else if (pending) {
      zhWidget = Text(
        '翻译中…',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: t.ink3,
              fontStyle: FontStyle.italic,
            ),
      );
    } else if (item.failed) {
      zhWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '翻译失败',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                ),
          ),
          if (onRetryLine != null && failedLine != null)
            TextButton(
              onPressed: () => onRetryLine!(failedLine),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('重试', style: TextStyle(fontSize: 12)),
            ),
        ],
      );
    } else {
      zhWidget = GestureDetector(
        onTap: () => _copy(context, item.translation!),
        child: Text(
          item.translation!,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: t.ink2, fontSize: 12.5),
        ),
      );
    }

    final bubble = InkWell(
      borderRadius: BorderRadius.circular(14),
      onSecondaryTapUp: (details) =>
          _openMenu(context, ref, details.globalPosition),
      onLongPress: () => _openMenu(
        context,
        ref,
        context.findRenderObject() != null
            ? ((context.findRenderObject()! as RenderBox)
                .localToGlobal(Offset.zero))
            : Offset.zero,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: me
              ? t.youSoft.withValues(alpha: 0.85)
              : t.paper,
          borderRadius: BorderRadius.only(
            topLeft: me ? const Radius.circular(14) : const Radius.circular(4),
            topRight: me ? const Radius.circular(4) : const Radius.circular(14),
            bottomLeft: const Radius.circular(14),
            bottomRight: const Radius.circular(14),
          ),
          border: Border.all(
            color: me
                ? Colors.green.shade300.withValues(alpha: 0.5)
                : t.line,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.starred)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber.shade700),
                  ),
                Flexible(child: enText),
              ],
            ),
            if (showTranslation)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: zhWidget,
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: me ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: me ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: me
                    ? Colors.green.shade50
                    : cs(context).primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: me
                      ? Colors.green.shade300
                      : cs(context).outlineVariant,
                ),
              ),
              child: Text(me ? '🎤' : '🔊', style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }

  static ColorScheme cs(BuildContext context) =>
      Theme.of(context).colorScheme;
}

// ---------------------------------------------------------------------------
// Bottom status bar
// ---------------------------------------------------------------------------

final class _StatusBar extends ConsumerWidget {
  const _StatusBar({required this.state});

  final LiveCaptionsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const Text('延迟约 1~3 秒'),
            const Spacer(),
            _LevelMeter(
                label: '扬声器',
                level: ref
                    .read(liveCaptionsControllerProvider.notifier)
                    .systemLevel),
            const SizedBox(width: 10),
            _LevelMeter(
                label: '麦克风',
                level: ref
                    .read(liveCaptionsControllerProvider.notifier)
                    .micLevel),
            const SizedBox(width: 12),
            if (listening && state.session != null)
              Text('${state.session!.lines.length} 句'),
          ],
        ),
      ),
    );
  }
}


/// Tiny live input-level bar driven by a ValueNotifier<double> (RMS 0..1).
final class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.label, required this.level});

  final String label;
  final ValueNotifier<double> level;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 5),
        AnimatedBuilder(
          animation: level,
          builder: (context, _) {
            final v = level.value.clamp(0.0, 1.0);
            return Container(
              width: 56,
              height: 6,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: t.sunk,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: v > 0.05
                        ? Colors.green.shade600
                        : t.ink3.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// Floating captions window (形态三): the app window becomes a small dark
// frameless always-on-top card. Drag the header to move; drag the bottom-right
// grip to resize; Esc / ✕ restores the previous window geometry.
// ---------------------------------------------------------------------------

Future<void> enterFloatMode(WidgetRef ref) async {
  final bounds = await windowManager.getBounds();
  ref.read(floatWindowBoundsProvider.notifier).state = bounds;
  await windowManager.setAlwaysOnTop(true);
  await windowManager.setSkipTaskbar(true);
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setMinimumSize(const Size(320, 220));
  await windowManager.setSize(const Size(440, 330));
  ref.read(floatCaptionsModeProvider.notifier).state = true;
}

Future<void> exitFloatMode(WidgetRef ref) async {
  ref.read(floatCaptionsModeProvider.notifier).state = false;
  await windowManager.setAlwaysOnTop(false);
  await windowManager.setSkipTaskbar(false);
  await windowManager.setTitleBarStyle(TitleBarStyle.normal);
  final bounds = ref.read(floatWindowBoundsProvider.notifier).state;
  if (bounds != null) {
    await windowManager.setBounds(bounds);
  }
}

final class FloatCaptionsHost extends ConsumerStatefulWidget {
  const FloatCaptionsHost({super.key});

  @override
  ConsumerState<FloatCaptionsHost> createState() =>
      _FloatCaptionsHostState();
}

class _FloatCaptionsHostState extends ConsumerState<FloatCaptionsHost> {
  final _scroll = ScrollController();
  Size? _resizeStart;
  Offset? _resizeStartGlobal;
  bool _pinned = true;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _scroll.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      unawaited(exitFloatMode(ref));
      return true;
    }
    return false;
  }

  Future<void> _togglePin() async {
    _pinned = !_pinned;
    await windowManager.setAlwaysOnTop(_pinned);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveCaptionsControllerProvider);
    final listening = state.phase == LiveCaptionsPhase.listening ||
        state.phase == LiveCaptionsPhase.starting;
    final session = state.session;
    final items = session == null
        ? const <_StreamItem>[]
        : buildLiveStreamItems(session.lines);

    return Material(
      color: const Color(0xFF1C1C20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag header.
              DragToMoveArea(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFF232328),
                  child: Row(
                    children: [
                      FadeTransition(
                        opacity: AlwaysStoppedAnimation(
                            listening ? 1.0 : 0.5),
                        child: Icon(
                          Icons.fiber_manual_record,
                          size: 9,
                          color: listening
                              ? Colors.green.shade600
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '实时字幕 · ${_pinned ? '置顶' : '普通'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFBBBBBB),
                        ),
                      ),
                      const Spacer(),
                      _FloatIconBtn(
                        icon: Icons.push_pin_rounded,
                        tooltip: _pinned ? '取消置顶' : '置顶',
                        active: _pinned,
                        onTap: _togglePin,
                      ),
                      _FloatIconBtn(
                        icon: Icons.close_rounded,
                        tooltip: '退出悬浮 (Esc)',
                        onTap: () => unawaited(exitFloatMode(ref)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          listening ? '正在聆听…' : '会话未开始',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding:
                            const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        itemCount: items.length +
                            (listening ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Center(
                                child: Text(
                                  '…',
                                  style: TextStyle(color: Color(0xFF666666)),
                                ),
                              ),
                            );
                          }
                          final item = items[index];
                          if (item is _DividerItem) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A30),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    item.line.event ?? item.line.text,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (item is _BubbleItem) {
                            return _FloatBubble(item: item);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
              ),
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: const Color(0xFF232328),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Esc 退出 · 拖标题移动 · 右下角缩放',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF777777)),
                ),
              ),
            ],
          ),
          // Resize grip.
          Positioned(
            right: 0,
            bottom: 0,
            width: 20,
            height: 20,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeDownRight,
              child: GestureDetector(
                onPanStart: (details) async {
                  _resizeStart = await windowManager.getSize();
                  _resizeStartGlobal = details.globalPosition;
                },
                onPanUpdate: (details) async {
                  final start = _resizeStart;
                  final startGlobal = _resizeStartGlobal;
                  if (start == null || startGlobal == null) return;
                  // Absolute global-position based sizing: immune to the
                  // window reflow feedback loop that shakes accumulated
                  // local deltas.
                  final dx =
                      details.globalPosition.dx - startGlobal.dx;
                  final dy =
                      details.globalPosition.dy - startGlobal.dy;
                  await windowManager.setSize(Size(
                    (start.width + dx).clamp(320, 900).toDouble(),
                    (start.height + dy).clamp(220, 700).toDouble(),
                  ));
                },
                onPanEnd: (_) => _resizeStartGlobal = null,
                child: Icon(
                  Icons.open_in_full_rounded,
                  size: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark bubble for the float window (mock 形态三).
final class _FloatBubble extends StatelessWidget {
  const _FloatBubble({required this.item});

  final _BubbleItem item;

  @override
  Widget build(BuildContext context) {
    final me = item.source == LiveCaptionSource.mic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: me ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: me
                  ? const Color(0xFF2E5E46)
                  : const Color(0xFF33333A),
              shape: BoxShape.circle,
            ),
            child: Text(me ? '🎤' : '🔊',
                style: const TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: me
                    ? const Color(0xFF2E5E46).withValues(alpha: 0.55)
                    : const Color(0xFF33333A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (item.translation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.translation!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: me
                              ? const Color(0xFFBFE0CF)
                              : const Color(0xFFB9BDC7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon button for the float header.
final class _FloatIconBtn extends StatelessWidget {
  const _FloatIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? Colors.white : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}
