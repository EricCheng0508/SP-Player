/// Fixed dark palette for the live-captions floating panel.
///
/// The panel floats over video and stays dark in both themes — the same
/// always-dark-own-surface rationale as `app_notice.dart` (ADR-0089 §9).
/// Values live here, inside the theme, so screens address them by name.
library;

import 'dart:ui';

const liveCaptionsPanelSurface = Color(0xFF1C1C20);
const liveCaptionsPanelHeader = Color(0xFF232328);
const liveCaptionsPanelBubble = Color(0xFF33333A);
const liveCaptionsPanelBubbleMe = Color(0xFF2E5E46);
const liveCaptionsPanelTranslationMe = Color(0xFFBFE0CF);
const liveCaptionsPanelTranslation = Color(0xFFB9BDC7);
const liveCaptionsPanelTextFaint = Color(0xFFBBBBBB);
const liveCaptionsPanelTextSoft = Color(0xFF888888);
const liveCaptionsPanelTextMuted = Color(0xFFAAAAAA);
const liveCaptionsPanelTextDim2 = Color(0xFF777777);
const liveCaptionsPanelTextDim = Color(0xFF666666);
const liveCaptionsPanelLine = Color(0xFF2A2A30);
