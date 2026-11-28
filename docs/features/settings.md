# Feature: Settings

## Summary

The Settings hub is reached at `/settings` and groups every preference surface in one editorial screen. There is **no account layer**: no account card, no sign-in/sign-out, no profile tab, no cloud sync — every preference is stored on-device ([ADR-0107](../decisions/0107-local-only-no-account-spine.md)). The screen is **searchable**; below `EnjoyThemeTokens.breakpointRail` (900px) it renders the **phone hub** — one grouped card of section rows with short trailing values, drill-in section pages, and the mono version footer (the `Settings` board's `st-narrow` layout) — and at/above the breakpoint a **two-pane** rail + detail layout on desktop. Typing in search on the hub swaps back to the flat single-column stack so matches render inline. It also hosts **sub-screens** — `/settings/keyboard` (keyboard shortcuts) and `/settings/ai-playground` (AI playground, non-release builds) — plus the **About / update** entry.

Section content lives in one file per section under `lib/features/settings/presentation/widgets/sections/`, shared by both the single-column and two-pane layouts (see [Code map](#code-map)). See `specs/004-settings-redesign/` for the redesign spec/plan/tasks that produced this structure.

## Routes

| Path | Purpose |
|------|---------|
| `/settings` | Hub screen |
| `/settings/appearance-language` | Appearance & Language section page (hub drill-in) |
| `/settings/ai-providers` | AI providers (engines) page (hub drill-in) |
| `/settings/recording` | Recording section page (hub drill-in) |
| `/settings/developer` | Developer section page (hub drill-in; non-release builds only) |
| `/settings/about` | About section page (hub drill-in) |
| `/settings/keyboard` | Keyboard shortcuts editor (sub-screen; desktop only) |
| `/settings/ai-playground` | AI playground (sub-screen; non-release builds only) |

Network and Local components have no drill-in route — their bodies render inline in the two-pane detail pane and the single-column stack.

## Search

`SettingsSearchField` writes to `settingsSearchQueryProvider` (a `@riverpod` string notifier). `filterSettingsEntries(query, entries)` (pure function, `lib/features/settings/domain/settings_search_entry.dart`) matches case-insensitively against each row's title and keywords in the static `SettingsSearchEntry` registry (one entry per section/row — Appearance & Language ×3, AI providers, Local components, Network ×2, Recording, Keyboard shortcuts ×2, Developer, About ×2 — and the "Usage analytics" row matches search tokens like "analytics"/"分析"/"privacy"/"隐私"/"telemetry"/"遥测"). Section/row search tokens come from the spec's locale-resolved `searchableText` accessors (defaulting to the section hint when omitted), so zh/zh_CN queries hit the same rows English ones do.

- A match inside a currently-collapsed section (every section starts collapsed) auto-expands that section so the match is visible.
- A query matching nothing shows a "no results" empty state with a clear affordance that restores the prior collapse state.
- In the two-pane layout, non-matching sections are hidden from the rail and the current selection auto-jumps to the first matching section if it no longer matches.

## Layout

`SettingsRow` centers its trailing value and chevron on the whole row (not the title line); below `stackBelowWidth` (320 px by default, scaled by the text scaler) the value wraps under the title.

`SettingsScreen` uses a `LayoutBuilder` keyed on `EnjoyThemeTokens.breakpointRail`:

- **Below the breakpoint** → `SettingsLayoutHub`: the board's phone layout — one grouped card of section rows (tinted icon tile, title, short trailing value, chevron) built from `visibleSettingsSections` so the platform/build gates still apply, and the centered mono version footer. Tapping a row pushes the section's page (`SettingsSectionPageScreen` under `/settings/<section>`; AI providers and Keyboard shortcuts keep their dedicated screens). With a search query active the hub swaps to `SettingsLayoutSingleColumn`, rendering every matching section inline — the search contract (matches visible in place, no-results state, clear affordance) is unchanged. Horizontal inset comes solely from `EnjoyPageMetrics` (`EnjoyPageKind.hub`).
- **At/above the breakpoint** → `SettingsLayoutTwoPane`: a rail of `SettingsSectionRailItem`s (selected-state highlight matching `AppSidebar`) plus a detail pane rendering the selected section's rows via the *same* `sections/*.dart` widgets. Selection is tracked by `settingsSelectedSectionProvider` (defaults to the first rail entry — Appearance & Language) and survives repeated resizing across the breakpoint.

Both layouts map over the presentation-layer section specs ([`lib/features/settings/presentation/settings_section_spec.dart`](../../lib/features/settings/presentation/settings_section_spec.dart)) — icon, localized title/hint/searchable-text accessors, visibility predicate, body builder, card/collapse shape, one `SettingsSectionSpec` per top-level section — instead of per-section `switch`/if-chains. Ordering derives from the domain registry: `visibleSettingsSections(l10n, query)` walks `kSettingsRegistry`'s section headers, resolves each through the spec list, and applies the platform/build gates (`isDesktop` for Keyboard shortcuts, `!kReleaseMode` for Developer — expressed once, on the spec) plus the search filter, so the single-column stack, the two-pane rail, and the no-results state always agree on the visible-section set (see [contracts/settings-section-registry.md](../../specs/004-settings-redesign/contracts/settings-section-registry.md), amended 2026-09).

Every settings row is a `SettingsRow` (icon, title, subtitle, value badge, optional chevron) — shared by both layouts so a value badge is never clipped in a way that hides the current value, even at narrow widths (a long value wraps below the title instead of disappearing). Capability-gated rows (e.g. native language when the learning language leaves only one native choice) render with `onTap: null` and keep their explanatory subtitle instead of silently omitting the control.

## Sections

- **Appearance & Language** (`sections/appearance_language_section.dart`) — an inline **System / Light / Dark** `EnjoySegmentedControl` on the Theme row (one tap, no sheet; the row stacks the control under its title below 460 px × text scale via `SettingsRow.stackBelowWidth`), then display, learning, and native language pickers (`language_choice_sheet.dart`). Each pick updates its row's value badge immediately with no need to leave the hub. Native language is capability-gated to the choices that remain after excluding the current learning language. All preferences persist locally in the single session database.
- **AI providers** (`sections/ai_providers_section.dart`) — the AI engines screen embedded inline (language model / translation and speech services; BYOK endpoints, preset cloud profiles, and managed local components), also reachable at `/settings/ai-providers`. See [`ai.md`](ai.md).
- **Local components** ([`lib/features/local_components/presentation/local_components_section.dart`](../../lib/features/local_components/presentation/local_components_section.dart)) — managed local components: install status, download / delete actions, and the storage root for the local ASR / LLM / TTS runtimes; also referenced by the setup wizard's "download later" guidance.
- **Network** (`sections/network_section.dart`) — proxy mode selector (**System** / **Manual** / **Direct**), the effective proxy (endpoint + source), and a **Test connection** button that re-resolves the proxy and probes YouTube, reporting each route's latency; when InnerTube caption profiles fail at the transport level, caption errors gain a `Hint:` naming the mode. Settings persist device-scope as `network.proxyMode` / `network.proxyUrl`. Default-collapsed. See [`network-proxy.md`](network-proxy.md).
- **Recording** (`sections/recording_section.dart`) — microphone picker dialog (auto + every input device returned by `AudioRecorder.listInputDevices()`; see [`echo-mode.md`](echo-mode.md) for the virtual-device skip list). An empty device list still renders an explanatory subtitle rather than a blank row.
- **Keyboard shortcuts** (`sections/keyboard_shortcuts_section.dart`) — link to `/settings/keyboard` (full editor); desktop-only.
- **Developer** (`sections/developer_section.dart`) — a link to the AI playground (`/settings/ai-playground`; see [`ai.md`](ai.md)); visible only in non-release builds; default-collapsed.
- **About / update** (`sections/about_section.dart`, wrapping `about_section_card.dart`) — gradient About card (logo, version pill), a **Check for updates** row (manual update check with the update-available dot; see [`update.md`](update.md)), a **Reset product tips** row (confirm dialog, resets onboarding tip progress; see [`onboarding.md`](onboarding.md)), the **Diagnostic logging** verbose switch with its privacy note, an **Export diagnostic report** row (see [`diagnostics.md`](diagnostics.md)), an open-source row linking to the GitHub repository, and the **Usage analytics** opt-out switch (`analytics_capture_toggle_row.dart`, see [`analytics.md`](analytics.md)). Default-collapsed.

## Sub-screens

### `/settings/keyboard`

Full keyboard shortcut editor. Backed by `HotkeysService` (see [`hotkeys.md`](hotkeys.md)); the screen shows current bindings, surfaces conflicts, and offers a confirmation dialog on save. Restyled to `SettingsRow`/`SettingsSectionCard` for visual consistency with the hub (no change to hotkey domain logic).

### `/settings/ai-playground`

Debug AI playground — active provider per modality plus exercise forms for ASR, chat, translation, dictionary, and assessment; see [`ai.md` § Debug UI](ai.md). Release builds redirect to `/settings`.

## Reach paths

- From the **sidebar footer Settings row** on desktop (Duet, [ADR-0093](../decisions/0093-duet-design-language.md)) — selected when the route is `/settings*`.
- From the **bottom navigation's Settings tab** on compact widths (see [`app-ui.md`](app-ui.md)); `/vocabulary` highlights the same tab.

## Accessibility

- `SettingsCollapsibleSection` respects OS reduced-motion: expand/collapse still animates via `AnimatedSize`/`AnimatedRotation`, but with a near-instant (1ms, not a literal zero — see below) duration, and the toggle is always a real tap target rather than depending on the animation to complete.
- Every interactive row (`SettingsRow`) and rail item (`SettingsSectionRailItem`) is keyboard-focusable; `SettingsSectionRailItem` shows an explicit focus ring border when focused and not selected.
- A literal `Duration.zero` on `AnimatedSize` throws a Flutter framework assertion ("`RenderAnimatedSize` was mutated in its own `performLayout`") because the animation controller's listener re-dirties layout mid-pass — use a 1ms duration instead when reduced motion is enabled.

## Code map

| Area | Path |
|------|------|
| Hub screen (search + layout switch) | [`lib/features/settings/presentation/settings_screen.dart`](../../lib/features/settings/presentation/settings_screen.dart) |
| Search field | [`lib/features/settings/presentation/widgets/settings_search_field.dart`](../../lib/features/settings/presentation/widgets/settings_search_field.dart) |
| Single-column layout (search results on the hub) | [`lib/features/settings/presentation/widgets/settings_layout_single_column.dart`](../../lib/features/settings/presentation/widgets/settings_layout_single_column.dart) |
| Phone hub layout | [`lib/features/settings/presentation/widgets/settings_layout_hub.dart`](../../lib/features/settings/presentation/widgets/settings_layout_hub.dart) |
| Drill-in section page | [`lib/features/settings/presentation/settings_section_page.dart`](../../lib/features/settings/presentation/settings_section_page.dart) |
| Two-pane layout | [`lib/features/settings/presentation/widgets/settings_layout_two_pane.dart`](../../lib/features/settings/presentation/widgets/settings_layout_two_pane.dart) |
| Rail item | [`lib/features/settings/presentation/widgets/settings_section_rail_item.dart`](../../lib/features/settings/presentation/widgets/settings_section_rail_item.dart) |
| Row primitive | [`lib/features/settings/presentation/widgets/settings_row.dart`](../../lib/features/settings/presentation/widgets/settings_row.dart) |
| Collapsible section | [`lib/features/settings/presentation/widgets/settings_collapsible_section.dart`](../../lib/features/settings/presentation/widgets/settings_collapsible_section.dart) |
| Section card | [`lib/features/settings/presentation/widgets/settings_section_card.dart`](../../lib/features/settings/presentation/widgets/settings_section_card.dart) |
| Section content | [`lib/features/settings/presentation/widgets/sections/`](../../lib/features/settings/presentation/widgets/sections/) |
| Local components section body | [`lib/features/local_components/presentation/local_components_section.dart`](../../lib/features/local_components/presentation/local_components_section.dart) |
| Search registry + filter | [`lib/features/settings/domain/settings_search_entry.dart`](../../lib/features/settings/domain/settings_search_entry.dart) |
| Section specs (icon/l10n/visibility/body per section) + shared visible-section helper | [`lib/features/settings/presentation/settings_section_spec.dart`](../../lib/features/settings/presentation/settings_section_spec.dart) |
| Search/selection/collapse providers | [`lib/features/settings/application/`](../../lib/features/settings/application/) |
| Language picker sheet | [`lib/features/settings/presentation/widgets/language_choice_sheet.dart`](../../lib/features/settings/presentation/widgets/language_choice_sheet.dart) |
| About card | [`lib/features/settings/presentation/widgets/about_section_card.dart`](../../lib/features/settings/presentation/widgets/about_section_card.dart) |
| Hotkeys sub-screen | [`lib/features/settings/presentation/hotkeys_settings_screen.dart`](../../lib/features/settings/presentation/hotkeys_settings_screen.dart) |
| Tests | [`test/features/settings/`](../../test/features/settings/) |

## Related

- AI capabilities: [`docs/features/ai.md`](ai.md)
- Hotkeys: [`docs/features/hotkeys.md`](hotkeys.md)
- App updates: [`docs/features/update.md`](update.md)
- Production diagnostics: [`docs/features/diagnostics.md`](diagnostics.md)
- Local-only, no account spine: [ADR-0107](../decisions/0107-local-only-no-account-spine.md)
- Redesign spec/plan/tasks: [`specs/004-settings-redesign/`](../../specs/004-settings-redesign/)
