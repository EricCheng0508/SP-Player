// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'SP Player';

  @override
  String get libraryTitle => '资料库';

  @override
  String get homeTitle => '首页';

  @override
  String get homeRecentMedia => '最近媒体';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homeEmptyTitle => '暂无最近媒体';

  @override
  String get homeContinuePracticing => '继续练习';

  @override
  String homeContinueOpenSemantics(String title) {
    return '继续练习，$title';
  }

  @override
  String get homeEmptyHint => '导入媒体或将文件拖放到此处开始。';

  @override
  String get libraryTabAudio => '音频';

  @override
  String get libraryTabVideo => '视频';

  @override
  String get libraryEmptyAudioTitle => '未找到任何音频';

  @override
  String get libraryEmptyAudioHint => '你的资料库中没有任何音频内容。';

  @override
  String get libraryEmptyVideoTitle => '未找到任何视频';

  @override
  String get libraryEmptyVideoHint => '你的资料库中没有任何视频内容。';

  @override
  String get librarySearchNoMatchesTitle => '没有匹配结果';

  @override
  String get librarySearchNoMatchesHint => '资料库中没有符合此搜索的内容。';

  @override
  String get librarySearchHint => '搜索媒体库';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get libraryDeleteFailed => '无法删除该项目，请重试。';

  @override
  String get transcriptAccessibilityTranscriptList => '字幕';

  @override
  String transcriptAccessibilityCue(String time, String snippet) {
    return '$time。$snippet';
  }

  @override
  String get transcriptAccessibilityCurrentLine => '当前播放行。';

  @override
  String get transcriptAccessibilityEchoRegion => '跟读练习区域。';

  @override
  String get transcriptAccessibilityEchoCurrentLine => '当前跟读行。';

  @override
  String transcriptLineRecordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条录音',
      one: '1 条录音',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorFriendlyTitle => '字幕暂不可用';

  @override
  String get transcriptErrorFriendlyHint => '请尝试选择其他字幕轨道或导入字幕文件。';

  @override
  String get transcriptFetchingSubtitles => '正在获取字幕…';

  @override
  String get transcriptSearchHint => '搜索字幕';

  @override
  String get transcriptSearchNoMatches => '没有匹配的句子';

  @override
  String get lookupSectionExplain => '讲解这句';

  @override
  String get libraryTabPlaylists => '播放列表';

  @override
  String get playlistCreateButton => '新建播放列表';

  @override
  String get playlistRename => '重命名';

  @override
  String get playlistDelete => '删除播放列表';

  @override
  String get playlistNameHint => '播放列表名称';

  @override
  String get playlistSave => '保存';

  @override
  String get playlistEmptyTitle => '还没有播放列表';

  @override
  String get playlistEmptyHint => '创建一个播放列表，把媒体分组按顺序播放。';

  @override
  String playlistItemCount(int count) {
    return '$count 个条目';
  }

  @override
  String get playlistAddMedia => '添加媒体';

  @override
  String get playlistPlayAll => '播放全部';

  @override
  String get playlistRemoveItem => '移出播放列表';

  @override
  String get playlistMoveUp => '上移';

  @override
  String get playlistMoveDown => '下移';

  @override
  String get playlistMissingMedia => '媒体已不在媒体库中';

  @override
  String get playlistPickerNoMedia => '先导入媒体，再在这里添加。';

  @override
  String get asrStatusExtracting => 'Extracting audio…';

  @override
  String get asrStatusUploading => 'Uploading audio…';

  @override
  String get asrLanguageTitle => 'Spoken language';

  @override
  String get asrLanguageAutoDetect => 'Auto-detect language';

  @override
  String get asrStatusRecognizing => 'Recognizing…';

  @override
  String get asrStatusPolling => 'Transcribing…';

  @override
  String get asrStatusSaving => 'Saving…';

  @override
  String get asrStatusSuccess => 'Transcript ready';

  @override
  String get asrStatusCancelled => 'Cancelled';

  @override
  String get asrStatusAligning => 'Aligning…';

  @override
  String get asrStageExtract => 'Extract audio';

  @override
  String get asrStageRecognize => 'Recognize';

  @override
  String get asrStageAlign => 'Align';

  @override
  String get asrStageSegment => 'Segment';

  @override
  String get asrBannerElapsed => 'Elapsed';

  @override
  String asrBannerEngine(String engine) {
    return 'Engine $engine';
  }

  @override
  String get asrErrorGeneric => 'Couldn\'t generate transcript';

  @override
  String get asrErrorFfmpegUnavailable =>
      'Audio extraction isn\'t available on this device';

  @override
  String get asrErrorNoAudioTrack => 'This file has no audio to transcribe';

  @override
  String get asrErrorExtractionFailed =>
      'Couldn\'t extract audio. Please try again.';

  @override
  String get asrErrorFileTooLarge => 'This file is too large to transcribe';

  @override
  String get asrErrorUnsupportedSource => 'This source isn\'t supported';

  @override
  String get asrErrorUnsupportedMedia =>
      'This audio format isn\'t supported for long transcription';

  @override
  String get asrErrorProviderTimeout =>
      'Transcription timed out. Please try again.';

  @override
  String get asrErrorProviderRetryable =>
      'Transcription failed. Please try again.';

  @override
  String get asrErrorByokMissing =>
      'Set up your AI provider to generate a transcript';

  @override
  String get asrErrorNetwork =>
      'Network error. Please check your connection and retry.';

  @override
  String get asrErrorNoSpeech => 'No speech detected in this audio';

  @override
  String get asrLongMediaConfirmTitle => 'This may take a while';

  @override
  String asrLongMediaConfirmBody(int minutes) {
    return 'Generating a transcript for $minutes minutes of audio may take several minutes. Recognition runs on your own machine, so nothing is billed. Continue?';
  }

  @override
  String get asrLongMediaConfirmContinue => 'Continue';

  @override
  String get asrLongMediaConfirmCancel => 'Cancel';

  @override
  String get actionImport => '导入';

  @override
  String get importFromFile => '从文件…';

  @override
  String get importFromYoutube => '从 YouTube 链接…';

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverBrowseAction => '浏览发现';

  @override
  String get discoverRecommendedHeading => '推荐频道';

  @override
  String get discoverSubscribeTitle => '订阅频道';

  @override
  String get discoverSubscribeHint => '粘贴 YouTube 频道链接或 @用户名。';

  @override
  String get discoverSubscribePlaceholder => 'https://www.youtube.com/@channel';

  @override
  String get discoverSubscribeAction => '订阅';

  @override
  String get discoverSubscribed => '已订阅频道';

  @override
  String get discoverSubscribedLabel => '已订阅';

  @override
  String get discoverSubscribeFailed => '无法订阅该频道。';

  @override
  String get discoverUnsubscribeAction => '取消订阅';

  @override
  String get discoverUnsubscribed => '已取消订阅';

  @override
  String get discoverAddToLibrary => '加入库';

  @override
  String get discoverAddedToLibrary => '已加入你的库';

  @override
  String get discoverAddFailed => '无法添加此视频。';

  @override
  String get discoverInLibrary => '已在库中';

  @override
  String get discoverFeedEmptyTitle => '暂无视频';

  @override
  String get discoverFeedEmptyHint => '订阅频道并刷新以加载最近上传。';

  @override
  String get discoverFeedErrorTitle => '无法加载动态';

  @override
  String get discoverFeedErrorHint => '请检查网络连接后重试。';

  @override
  String get discoverRetry => '重试';

  @override
  String get discoverRefreshPartialFailed => '部分频道动态刷新失败。';

  @override
  String discoverRefreshPartialFailedDetail(int count, String names) {
    return '无法刷新 $count 个频道：$names';
  }

  @override
  String discoverRefreshSingleFailed(Object name) {
    return '无法刷新 $name。';
  }

  @override
  String get discoverRecommendedLoadFailed => '无法加载推荐频道。';

  @override
  String get discoverSubscriptionsLoadFailed => '无法加载订阅。';

  @override
  String get discoverNoSubscriptionsHint => '订阅推荐频道或粘贴频道链接。';

  @override
  String get discoverManageChannels => '管理频道';

  @override
  String get discoverFilterAll => '全部';

  @override
  String get discoverYourChannelsHeading => '你的频道';

  @override
  String get discoverRecommendedAllSubscribed => '你已订阅全部推荐频道。';

  @override
  String get youtubeImportTitle => '导入 YouTube 视频';

  @override
  String get youtubeImportHint => '粘贴 YouTube 链接或视频 ID';

  @override
  String get youtubeImportInvalid => '无法识别有效的 YouTube 视频 ID。';

  @override
  String get youtubeImporting => '正在添加视频…';

  @override
  String get youtubeBadge => 'YouTube';

  @override
  String get youtubeLoginTooltip => 'YouTube 账号';

  @override
  String get youtubeOpenInBrowser => '在瀏覽器中開啟';

  @override
  String get youtubeLoginClose => '關閉';

  @override
  String get youtubeLoginScreenTitle => 'YouTube 登录';

  @override
  String get youtubeLogout => '退出登录（清除 Cookie）';

  @override
  String get youtubeUnavailableOnDevice => '此裝置無法播放 YouTube 影片。';

  @override
  String get youtubeUnavailableRuntimeMissing => '此裝置缺少 YouTube 播放執行環境。';

  @override
  String get youtubeUnavailableRuntimeInitFailed => 'YouTube 播放環境啟動失敗。';

  @override
  String get youtubeUnavailableCodecsMissing =>
      '此裝置缺少 YouTube 影片解碼器。請安裝 GStreamer 外掛（gst-plugins-good、gst-plugins-bad、gst-libav）後重新啟動應用程式。';

  @override
  String get youtubeUnavailableDisabledByBuild => '此組建已停用 YouTube 播放。';

  @override
  String get youtubeTapToPlayHint => '點一下影片即可播放';

  @override
  String get youtubeVideoStallRelaunch =>
      '此 GPU 無法渲染 YouTube 影片。重新啟動應用程式即可使用軟體渲染恢復畫面。';

  @override
  String get transportFullscreen => '全屏';

  @override
  String get transportExitFullscreen => '退出全屏';

  @override
  String get settingsTitle => '设置';

  @override
  String get importMedia => '导入媒体';

  @override
  String get importingMedia => '正在导入媒体…';

  @override
  String get importMediaFailed => '无法导入此文件。';

  @override
  String get importUnsupportedFileType => '不支持此文件类型。请选择音频或视频文件。';

  @override
  String get navMainLabel => '主导航';

  @override
  String get miniPlayerMediaVideo => '视频';

  @override
  String get miniPlayerMediaAudio => '音频';

  @override
  String get retry => '重试';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsAboutSubtitle => 'SP Player — 本地字幕与跟读练习。';

  @override
  String get settingsThemeDarkLocked => '跟随系统外观。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get previousLine => '上一句';

  @override
  String get nextLine => '下一句';

  @override
  String get replayLine => '重播本句';

  @override
  String get echoMode => '回声模式';

  @override
  String get playerListenModeTitle => '聆听';

  @override
  String get playerDockHideText => '隐藏文本';

  @override
  String playerDockLinePosition(int line, int total) {
    return '第 $line / $total 句';
  }

  @override
  String get playerDockLooping => '· 循环中';

  @override
  String get transcript => '字幕稿';

  @override
  String get playerTranscriptResizeHint => '拖动以调整字幕稿面板大小';

  @override
  String get importSubtitle => '导入字幕';

  @override
  String get noTranscript => '暂无字幕稿';

  @override
  String get transcriptEmptyOverline => '字幕';

  @override
  String get loading => '加载中…';

  @override
  String get error => '错误';

  @override
  String get playerOpenGenericError => '无法打开此项目。';

  @override
  String playbackRateTimes(String rate) {
    return '$rate 倍';
  }

  @override
  String get speed => '速度';

  @override
  String get volume => '音量';

  @override
  String get subtitles => '字幕';

  @override
  String get subtitlesPrimary => '主字幕';

  @override
  String get subtitlesTranslation => '翻译（可选）';

  @override
  String get subtitlesNone => '无';

  @override
  String get subtitlesNotSelected => '未选择';

  @override
  String get subtitlesDeleteTrack => '删除轨道';

  @override
  String get importSubtitleSuccess => '字幕已导入';

  @override
  String get noTranscriptHint => '可添加字幕文件、提取内嵌字幕，或用 AI 生成字幕稿。';

  @override
  String get noTranscriptHintRemote => '云端字幕会在可用时自动加载。可在 CC 菜单中刷新。';

  @override
  String get transcriptEmptyExtract => '提取';

  @override
  String get transcriptEmptyAlign => '对齐已有字幕 / 台本';

  @override
  String get transcriptAlignNotInstalled => '对齐组件未安装，请到「设置 → 本地组件」安装';

  @override
  String get transcriptAlignPipelinePending => '已检测到对齐组件，词级对齐将随下一个组件包发布';

  @override
  String get transcriptEmptyAddSubtitle => '添加字幕';

  @override
  String get transcriptEmptyGenerate => 'AI 字幕稿';

  @override
  String get subtitlesImportLanguageTitle => '字幕语言';

  @override
  String get subtitlesImportLanguageHint => 'BCP-47 代码（如 en、zh-TW）。未知请填 und。';

  @override
  String get subtitlesImportLanguageFieldLabel => '语言代码';

  @override
  String get subtitlesProviderOfficial => '官方';

  @override
  String get subtitlesProviderAuto => '自动';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => '用户';

  @override
  String get subtitlesAutoTranslate => '自动翻译';

  @override
  String subtitlesAutoTranslateLanguageChip(String language) {
    return '译为 $language';
  }

  @override
  String get subtitlesExtractNoTracks =>
      '此文件中无内嵌字幕轨道（仅有视频与音频）。若有单独的 .srt 或 .vtt，请使用导入文件。';

  @override
  String subtitlesExtractedCount(int count) {
    return '已提取 $count 条字幕轨道。';
  }

  @override
  String get subtitlesRefreshDone => '已从云端更新字幕稿。';

  @override
  String get transcriptDownloadDialogTitle => '下载字幕稿';

  @override
  String get transcriptDownloadEmpty => '还没有可下载的字幕稿。';

  @override
  String get transcriptDownloadSuccess => '字幕稿已下载。';

  @override
  String get transcriptDownloadError => '无法下载字幕稿。';

  @override
  String get subtitlesNoPlayableUri => '无法解析此项目的可播放文件。';

  @override
  String get expandEchoBackward => '向后扩展回声';

  @override
  String get expandEchoForward => '向前扩展回声';

  @override
  String get shrinkEchoBackward => '向后收缩回声';

  @override
  String get shrinkEchoForward => '向前收缩回声';

  @override
  String echoLoopCaptionLine(String range, String seconds) {
    return '循环 · 第 $range 句 · $seconds 秒';
  }

  @override
  String echoLoopCaptionLines(String range, String seconds) {
    return '循环 · 第 $range 句 · $seconds 秒';
  }

  @override
  String echoLoopCaptionRecording(int count) {
    return '录音 · 第 $count 遍';
  }

  @override
  String get shadowReadingHint => '跟读本段并练习口语。录制你的声音并与参考音高对比。';

  @override
  String get pitchContourTitle => '音高曲线';

  @override
  String get pitchContourError => '无法分析本段的音高。';

  @override
  String get pitchContourWaveform => '波形';

  @override
  String get pitchContourReference => '原声音高';

  @override
  String get pitchContourUser => '你的音高';

  @override
  String get pitchContourAnalyzing => '正在分析音高…';

  @override
  String get shadowRecordingEmpty => '本段尚无录音。';

  @override
  String get shadowRecordingTake => '录音';

  @override
  String get shadowTakesEmptyPrefix => '这段还没有录音，按';

  @override
  String get shadowTakesEmptySuffix => '读一遍。';

  @override
  String get shadowRecordingPlay => '播放';

  @override
  String get shadowRecordingChooseTake => '切换录音';

  @override
  String get shadowRecordingDelete => '删除';

  @override
  String get shadowRecordingDeleteConfirmTitle => '删除此条录音？';

  @override
  String shadowRecordingDeleteConfirmMessage(String takeLabel) {
    return '将永久删除 $takeLabel，无法撤销。';
  }

  @override
  String get shadowRecordingRecord => '录音';

  @override
  String get shadowRecordingStop => '停止';

  @override
  String get shadowRecordingMicDenied => '需要麦克风权限才能录音。';

  @override
  String shadowRecordingSaveFailed(String reason) {
    return '无法保存录音：$reason';
  }

  @override
  String get settingsSectionAi => 'AI';

  @override
  String get settingsSectionAiHint => '为各功能配置你自己的 API 密钥；识别与翻译默认使用本地组件。';

  @override
  String get settingsAiProvidersTileTitle => 'AI 提供商';

  @override
  String get settingsAiProvidersTitle => 'AI 提供商';

  @override
  String get settingsAiProvidersPrivacyNotice => 'API 密钥仅安全存储在本设备，不会上传到任何云端。';

  @override
  String get settingsAiProvidersEnjoyAi => '默认';

  @override
  String get settingsAiProvidersByok => '自备密钥';

  @override
  String get settingsAiProvidersModalityLlm => '语言模型';

  @override
  String get settingsAiProvidersModalityAsr => '语音识别（生成字幕）';

  @override
  String get settingsAiProvidersModalityTts => '文字转语音（Craft 合成）';

  @override
  String get settingsAiProvidersModalityAssessment => '发音评估';

  @override
  String get settingsAiProvidersLlmSpecLabel => '协议';

  @override
  String get settingsAiProvidersLlmSpecOpenAi => 'OpenAI 兼容';

  @override
  String get settingsAiProvidersLlmSpecAnthropic => 'Anthropic 兼容';

  @override
  String get settingsAiProvidersLlmSpecGoogle => 'Google 兼容';

  @override
  String get settingsAiProvidersPresetsLabel => '预设';

  @override
  String get settingsAiProvidersBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiProvidersBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get settingsAiProvidersApiKeyLabel => 'API 密钥';

  @override
  String get settingsAiProvidersApiKeyExistingHint => '留空则保留已保存的密钥';

  @override
  String get settingsAiProvidersShowApiKey => '显示 API 密钥';

  @override
  String get settingsAiProvidersHideApiKey => '隐藏 API 密钥';

  @override
  String get settingsAiProvidersModelLabel => '模型';

  @override
  String get settingsAiProvidersFetchModels => '获取模型列表';

  @override
  String get settingsAiProvidersFetchedModelsLabel => '已获取的模型';

  @override
  String get settingsAiProvidersFetchModelsFailed =>
      '无法获取模型列表，请检查 Base URL 和 API 密钥。';

  @override
  String get settingsAiProvidersFetchModelsEmpty => '此端点未返回任何模型。';

  @override
  String get settingsAiProvidersSave => '保存';

  @override
  String get settingsAiProvidersSaveSuccess => 'AI 提供商设置已保存。';

  @override
  String get settingsAiProvidersRemoveByok => '移除';

  @override
  String get settingsAiProvidersRemoveByokTitle => '移除已保存的密钥？';

  @override
  String get settingsAiProvidersRemoveByokBody => '将删除本设备上保存的 API 密钥。';

  @override
  String get settingsAiProvidersRemoveByokSuccess => '已移除保存的密钥。';

  @override
  String get settingsAiProvidersCancel => '取消';

  @override
  String get settingsAiProvidersComingSoon => '此功能的 BYOK 配置即将推出。';

  @override
  String get settingsAiProvidersSpeechSubscriptionKeyLabel => 'Azure 订阅密钥';

  @override
  String get settingsAiProvidersSpeechRegionLabel => 'Azure 区域';

  @override
  String get settingsAiProvidersSpeechRegionHint => 'eastus';

  @override
  String get settingsAiProvidersSpeechKindLabel => '供应商';

  @override
  String get settingsAiProvidersSpeechKindOpenAi => 'OpenAI Whisper';

  @override
  String get settingsAiProvidersSpeechKindAzure => 'Azure Speech';

  @override
  String get settingsAiProvidersSpeechKindHintOpenAi =>
      'OpenAI 兼容：用于语音转文字（生成字幕、听写、跟读复述）。';

  @override
  String get settingsAiProvidersSpeechKindHintAzure =>
      'Azure 语音：音素级发音诊断；也支持语音转文字。不配置则跟读打分自动走本地评估。';

  @override
  String get settingsAiProvidersSpeechWhisperModelLabel => 'Whisper 模型';

  @override
  String get settingsAiProvidersSpeechWhisperModelHint => 'whisper-1';

  @override
  String get settingsAiEngineLocal => '本地（默认）';

  @override
  String get settingsAiEngineCloud => '自定义云端';

  @override
  String get settingsAiProvidersSpeechTtsModelLabel => 'TTS 模型';

  @override
  String get settingsAiProvidersSpeechTtsModelHint => 'tts-1';

  @override
  String get settingsAiProvidersApiKeySavedMask => '••••••••••••';

  @override
  String get settingsAiProvidersApiKeyEdit => '编辑密钥';

  @override
  String byokNotConfiguredMessage(String modality) {
    return '已为 $modality 选择 BYOK，但本设备未保存 API 密钥。';
  }

  @override
  String get byokNotConfiguredOpenSettings => '请打开 设置 → AI 提供商 添加密钥。';

  @override
  String get byokValidationApiKeyRequired => '需要 API 密钥。';

  @override
  String get byokValidationBaseUrlRequired => '需要 Base URL。';

  @override
  String get byokValidationBaseUrlInvalid => 'Base URL 必须是公网 HTTPS 地址。';

  @override
  String get byokValidationModelRequired => '需要填写模型。';

  @override
  String get byokValidationRegionRequired => '需要 Azure 区域。';

  @override
  String get byokValidationApiSpecRequired => '协议配置不完整。';

  @override
  String get byokValidationAzureKindRequired => '发音评估 BYOK 需要使用 Azure Speech。';

  @override
  String get settingsSectionRecording => '录音';

  @override
  String get settingsSectionRecordingHint => '跟读录音所使用的麦克风。';

  @override
  String get settingsTranscriptEnrichmentTitle => '对齐词级时间轴';

  @override
  String get settingsTranscriptKaraokeTitle => '高亮当前词';

  @override
  String get settingsTranscriptIpaOverlayTitle => '显示音标（IPA）';

  @override
  String get transcriptKaraokeUnavailableRemoteHint => '卡拉 OK 高亮需要本地文件的逐词时间。';

  @override
  String get transcriptEnrichOwnedSubtitle => '使用本条目的音频，播放不受影响。';

  @override
  String get transcriptEnrichYoutubeSubtitle => '卡拉 OK 高亮仍不可用，不会下载视频。';

  @override
  String get transcriptEnrichCancel => '取消生成';

  @override
  String get transcriptEnrichRetry => '重新生成';

  @override
  String get transcriptEnrichFailed => '无法生成。点按重试。';

  @override
  String transcriptEnrichProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get settingsRecordingMicTitle => '麦克风';

  @override
  String settingsRecordingMicAuto(String label) {
    return '自动 · $label';
  }

  @override
  String get settingsRecordingMicAutoNoDevice => '自动 · 系统默认';

  @override
  String get settingsRecordingMicAutoShort => '自动';

  @override
  String get settingsRecordingMicEmpty => '未检测到麦克风';

  @override
  String get settingsRecordingMicAutoOption => '自动（跳过虚拟麦克风）';

  @override
  String get settingsRecordingMicDialogTitle => '选择麦克风';

  @override
  String get shadowRecordingSilentWarning => '未检测到麦克风信号。请打开「设置 → 录音」选择其他麦克风。';

  @override
  String get shadowRecordingPlaybackFailed => '无法播放此条录音。';

  @override
  String shadowRecordingOverTarget(String seconds) {
    return '超出目标 +$seconds 秒';
  }

  @override
  String shadowRecordingElapsedSemantics(String elapsed, String target) {
    return '已录制 $elapsed 秒，目标 $target 秒';
  }

  @override
  String shadowRecordingElapsedCountdown(String elapsed, String target) {
    return '$elapsed 秒 / $target 秒';
  }

  @override
  String shadowRecordingElapsedSeconds(String elapsed) {
    return '$elapsed 秒';
  }

  @override
  String get shadowRecordingFileNotFound => '未找到录音文件。';

  @override
  String get hotkeysTitle => '键盘快捷键';

  @override
  String get hotkeysHintFooter => '按 Shift+/（?）打开此列表。';

  @override
  String get hotkeysCustomizedBadge => '已自定义';

  @override
  String get hotkeysSectionKeyboard => '键盘快捷键';

  @override
  String get hotkeysResetAll => '重置全部快捷键';

  @override
  String get hotkeysResetAllConfirmTitle => '重置全部快捷键？';

  @override
  String get hotkeysResetAllConfirmMessage => '所有快捷键将恢复为默认绑定，自定义设置无法撤销。';

  @override
  String get hotkeysCaptureTitle => '按下新快捷键';

  @override
  String get hotkeysCaptureHint => '按下组合键。Esc 取消。';

  @override
  String get hotkeysConflictError => '该快捷键已被使用。';

  @override
  String get hotkeysScopeGlobal => '全局';

  @override
  String get hotkeysScopePlayer => '播放器';

  @override
  String get hotkeysScopeLibrary => '资料库';

  @override
  String get hotkeysScopeModal => '弹窗';

  @override
  String get hotkeysDescHelp => '显示键盘快捷键';

  @override
  String get hotkeysDescSearch => '打开搜索';

  @override
  String get hotkeysDescSettings => '打开设置';

  @override
  String get hotkeysDescCraft => '打开 Craft';

  @override
  String get hotkeysDescTogglePlay => '播放 / 暂停';

  @override
  String get hotkeysDescToggleExpand => '切换播放器展开/收起';

  @override
  String get hotkeysDescToggleFullscreen => '切换全屏';

  @override
  String get hotkeysDescSearchTranscript => '搜索字幕 (Ctrl+F)';

  @override
  String get hotkeysDescSeekBack => '快退 3 秒';

  @override
  String get hotkeysDescSeekForward => '快进 3 秒';

  @override
  String get hotkeysDescVolumeUp => '增大音量';

  @override
  String get hotkeysDescVolumeDown => '减小音量';

  @override
  String get hotkeysDescToggleMute => '静音切换';

  @override
  String get hotkeysDescPrevLine => '播放上一句';

  @override
  String get hotkeysDescNextLine => '播放下一句';

  @override
  String get hotkeysDescReplayLine => '重播当前句';

  @override
  String get hotkeysDescToggleEchoMode => '切换回声模式';

  @override
  String get hotkeysDescToggleBlurPractice => '听写（隐藏文本）';

  @override
  String get hotkeysDescToggleRecording => '开始/停止录音';

  @override
  String get hotkeysDescToggleAssessment => '显示/隐藏发音评测';

  @override
  String get hotkeysDescTogglePitchContour => '显示/隐藏音高曲线';

  @override
  String get hotkeysDescPlayRecording => '播放/暂停录音';

  @override
  String get hotkeysDescSlowDown => '减慢播放速度';

  @override
  String get hotkeysDescSpeedUp => '加快播放速度';

  @override
  String get hotkeysDescExpandEchoBackward => '把上一行加入循环';

  @override
  String get hotkeysDescExpandEchoForward => '把下一行加入循环';

  @override
  String get hotkeysDescShrinkEchoBackward => '去掉循环的第一行';

  @override
  String get hotkeysDescShrinkEchoForward => '去掉循环的最后一行';

  @override
  String get hotkeysDescLibrarySearch => '聚焦搜索框';

  @override
  String get hotkeysDescCloseModal => '关闭浮层、退出全屏或取消录音';

  @override
  String get assessmentTitle => '发音评测';

  @override
  String get assessmentDescription => '为你的朗读提供详细评分。';

  @override
  String get assessmentRun => '运行发音评测';

  @override
  String get assessmentView => '查看发音评测';

  @override
  String get assessmentReassess => '重新评测';

  @override
  String get assessmentScoring => '打分中…';

  @override
  String get assessmentScoreAction => '评分';

  @override
  String get assessmentOverallScore => '总分';

  @override
  String get assessmentAccuracy => '准确度';

  @override
  String get assessmentCompleteness => '完整度';

  @override
  String get assessmentFluency => '流利度';

  @override
  String get assessmentProsody => '韵律';

  @override
  String get assessmentPronunciationAnalysis => '发音分析';

  @override
  String get assessmentSyllables => '音节';

  @override
  String get assessmentPhonemes => '音素';

  @override
  String get assessmentNoRecording => '录音文件缺失或为空。';

  @override
  String get assessmentNoResultSummary => '此条录音没有可用的详细评分。';

  @override
  String assessmentRunFailed(String reason) {
    return '无法运行评测：$reason';
  }

  @override
  String get assessmentErrorTypeOmission => '遗漏';

  @override
  String get assessmentErrorTypeInsertion => '插入';

  @override
  String get assessmentErrorTypeMispronunciation => '发音错误';

  @override
  String get assessmentErrorTypeUnexpectedBreak => '意外停顿';

  @override
  String get assessmentErrorTypeMissingBreak => '缺少停顿';

  @override
  String get assessmentErrorTypeMonotone => '单调';

  @override
  String get assessmentErrorTypeCorrect => '正确';

  @override
  String get assessmentErrorExplOmission => '预期应有此词但未检测到。';

  @override
  String get assessmentErrorExplInsertion => '检测到参考中不存在的额外词语。';

  @override
  String get assessmentErrorExplMispronunciation => '此词发音可能不正确。';

  @override
  String get assessmentErrorExplUnexpectedBreak => '在此词前检测到意外停顿。';

  @override
  String get assessmentErrorExplMissingBreak => '在此词前未检测到应有的停顿。';

  @override
  String get assessmentErrorExplMonotone => '音高变化低于预期。';

  @override
  String get assessmentErrorExplCorrect => '此词未发现问题。';

  @override
  String get assessmentEmptyReference => '参考文本为空。';

  @override
  String get assessmentInvalidStored => '无法读取已保存的评测数据。';

  @override
  String get authCancel => '取消';

  @override
  String get subscriptionViewPlans => '查看方案';

  @override
  String get settingsSectionAppearanceLanguageHint => '主题，以及界面、学习与母语语言';

  @override
  String get hotkeysSectionKeyboardHint => '查看并自定义快捷键';

  @override
  String get settingsSectionDeveloperHint => '诊断与内部工具';

  @override
  String get settingsSectionAboutHint => '版本、许可与链接';

  @override
  String get cloudRefreshTooltip => '刷新此标签页';

  @override
  String get settingsApiBaseUrl => 'API 基础地址';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get homeTodaysGoal => '今日目标';

  @override
  String get homeMinutes => '分钟';

  @override
  String get homeGoalCompleted => '目标完成！太棒了！';

  @override
  String get homeGoalAlmostThere => '快完成了！继续加油！';

  @override
  String get homeGoalHalfway => '已经完成一半！你可以的！';

  @override
  String get homeGoalGoodStart => '不错的开始！坚持练习！';

  @override
  String get homeGoalJustStarted => '刚刚开始！每一分钟都很重要！';

  @override
  String get homeGoalStartNow => '现在开始练习吧！';

  @override
  String get mediaLocateTitle => '定位媒体文件';

  @override
  String get mediaLocateBody => '此项目是在其他设备上添加的。请在本机选择同一文件。我们会通过安全指纹校验是否与资料库匹配。';

  @override
  String get mediaLocateChooseFile => '选择文件';

  @override
  String get mediaLocateHashMismatch => '该文件与此项目不匹配。请确认选择了正确文件。';

  @override
  String mediaLocateExpectedSize(String sizeLabel) {
    return '预期大小：$sizeLabel';
  }

  @override
  String get mediaLocateSizeUnknown => '预期大小：未知';

  @override
  String get libraryDeleteMediaTitle => '从资料库删除？';

  @override
  String libraryDeleteMediaMessage(String title) {
    return '从本机移除「$title」。此操作无法撤销。';
  }

  @override
  String get libraryDeleteMediaTooltip => '从资料库删除';

  @override
  String get libraryMediaDeleted => '已从资料库移除。';

  @override
  String get cloudSyncBadgeSynced => '已同步至云端';

  @override
  String get cloudSyncBadgePending => '等待同步';

  @override
  String get cloudSyncBadgeLocalOnly => '仅本机';

  @override
  String get settingsSectionDeveloper => '开发者';

  @override
  String get settingsAiPlaygroundTileTitle => 'AI 试验台';

  @override
  String get settingsAiPlaygroundTileSubtitle => '调用 ASR、聊天、翻译与词典 API';

  @override
  String get aiPlaygroundTitle => 'AI 试验台';

  @override
  String get aiPlaygroundIntro =>
      '通过「设置 → AI 提供商」中的凭据测试各 AI 能力。翻译与词典跟随 LLM 提供商。';

  @override
  String get aiPlaygroundActiveProviders => '当前提供商';

  @override
  String aiPlaygroundProviderByokDetail(String detail) {
    return 'BYOK · $detail';
  }

  @override
  String get aiPlaygroundPickAudio => '选择音频文件';

  @override
  String get aiPlaygroundTranscribe => '转写';

  @override
  String get aiPlaygroundChatSystem => '系统（可选）';

  @override
  String get aiPlaygroundChatUser => '用户消息';

  @override
  String get aiPlaygroundSendChat => '发送聊天';

  @override
  String get aiPlaygroundTranslateSource => '源语言';

  @override
  String get aiPlaygroundTranslateTarget => '目标语言';

  @override
  String get aiPlaygroundTranslateText => '待翻译文本';

  @override
  String get aiPlaygroundTranslate => '翻译';

  @override
  String get aiPlaygroundDictWord => '单词';

  @override
  String get aiPlaygroundDictSource => '源语言';

  @override
  String get aiPlaygroundDictTarget => '目标语言';

  @override
  String get aiPlaygroundDictLookup => '词典查询';

  @override
  String get aiPlaygroundAssessmentReference => '参考文本（你所说的内容）';

  @override
  String get aiPlaygroundAssessmentLanguage => '语言（如 en、en-US）';

  @override
  String get aiPlaygroundAssess => '运行发音评测';

  @override
  String get aiPlaygroundAssessmentTtsNote =>
      'TTS 尚未接入；可在 AI 提供商中配置 TTS BYOK。评测使用上方所示提供商。';

  @override
  String get aiPlaygroundOutput => '输出';

  @override
  String get aiPlaygroundClearOutput => '清空输出';

  @override
  String get aiPlaygroundSectionAsr => '语音识别';

  @override
  String get aiPlaygroundSectionChat => '聊天';

  @override
  String get aiPlaygroundSectionTranslation => '翻译';

  @override
  String get aiPlaygroundSectionDictionary => '词典';

  @override
  String get aiPlaygroundSectionTtsAssessment => 'TTS / 评测';

  @override
  String get youtubePasteFromClipboard => '粘贴';

  @override
  String get settingsSectionAppearanceLanguage => '外观与语言';

  @override
  String get settingsAppearanceTheme => '主题';

  @override
  String get settingsAppearanceThemeSystem => '跟随系统';

  @override
  String get settingsAppearanceThemeLight => '浅色';

  @override
  String get settingsAppearanceThemeDark => '深色';

  @override
  String get settingsAppearanceDisplayLanguage => '显示语言';

  @override
  String get settingsAppearanceLearningLanguage => '学习语言';

  @override
  String get settingsAppearanceNativeLanguage => '母语';

  @override
  String get settingsLanguageSubtitleDeviceOnly => '保存在本机，登录账号后可同步。';

  @override
  String get settingsNativeLanguageGateSubtitle => '当前学习语言下只有一种母语可选。';

  @override
  String get settingsLanguageOptionEnUs => '英语（美国）';

  @override
  String get settingsLanguageOptionEnGb => '英语（英国）';

  @override
  String get settingsLanguageOptionJaJp => '日语';

  @override
  String get settingsLanguageOptionKoKr => '韩语';

  @override
  String get settingsLanguageOptionEsEs => '西班牙语（西班牙）';

  @override
  String get settingsLanguageOptionEsMx => '西班牙语（墨西哥）';

  @override
  String get settingsLanguageOptionFrFr => '法语（法国）';

  @override
  String get settingsLanguageOptionFrCa => '法语（加拿大）';

  @override
  String get settingsLanguageOptionZhCn => '中文（简体）';

  @override
  String get settingsLanguageOptionNbNo => '挪威语（书面语）';

  @override
  String get settingsLearningLanguageSubtitle => '用于发现页推荐和导入时的默认语言。';

  @override
  String get settingsLanguagePickerTitleLearning => '学习语言';

  @override
  String get mediaLanguageUnknown => '未知';

  @override
  String get mediaLanguagePickerTitle => '内容语言';

  @override
  String get mediaEditLanguage => '编辑语言';

  @override
  String get mediaLanguageUpdated => '语言已更新。';

  @override
  String get mediaLanguageUpdateFailed => '无法更新语言。';

  @override
  String get mediaEditDetails => '编辑详情';

  @override
  String get mediaDetailsTitleLabel => '标题';

  @override
  String get mediaDetailsSave => '保存';

  @override
  String get mediaDetailsUpdated => '详情已更新。';

  @override
  String get mediaDetailsUpdateFailed => '无法更新详情。';

  @override
  String get mediaDetailsMissing => '该项目已不在资料库中。';

  @override
  String get assessmentUnavailableLanguage => '该语言暂不支持发音评估。';

  @override
  String get discoverLanguageFilterAll => '全部语言';

  @override
  String get discoverLanguageFilterLabel => '语言';

  @override
  String get settingsLanguagePickerTitleDisplay => '显示语言';

  @override
  String get settingsLanguagePickerTitleNative => '母语';

  @override
  String get settingsKeyboardOpenCheatsheet => '打开快捷键速查';

  @override
  String get settingsKeyboardOpenCheatsheetSubtitle => '浏览并自定义所有快捷键';

  @override
  String get settingsKeyboardCustomizeTitle => '自定义快捷键';

  @override
  String get hotkeysHelpSearchHint => '搜索快捷键';

  @override
  String get hotkeysHelpEmpty => '无匹配的快捷键';

  @override
  String get hotkeysHelpCustomize => '自定义快捷键';

  @override
  String hotkeysSettingsSubtitle(String key) {
    return '点按一行即可修改。随时按 $key。';
  }

  @override
  String get hotkeysFilterHint => '筛选快捷键';

  @override
  String get hotkeysResetTooltip => '重置此快捷键';

  @override
  String get hotkeysEditTooltip => '更改快捷键';

  @override
  String get settingsAboutMadeWithCare => '为语言学习者用心打造。';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version';
  }

  @override
  String get settingsAboutOpenSourceTitle => '开源项目';

  @override
  String get settingsAboutOpenSourceSubtitle => '在 GitHub 查看源代码';

  @override
  String get settingsDiagnosticsLoggingTitle => '诊断日志';

  @override
  String get settingsDiagnosticsLoggingSubtitle => '为 YouTube、同步和登录问题记录更多细节';

  @override
  String get settingsDiagnosticsPrivacyNote =>
      '日志保存在本设备，导出前不会上传。令牌和 Cookie 会被脱敏。';

  @override
  String get settingsDiagnosticsExportTitle => '导出诊断报告';

  @override
  String get settingsDiagnosticsExportSubtitle => '保存近期日志压缩包以便反馈问题';

  @override
  String get settingsDiagnosticsExportSuccess => '诊断报告已保存。';

  @override
  String get settingsDiagnosticsExportError => '无法导出诊断报告。';

  @override
  String get settingsCheckForUpdatesTitle => '检查更新';

  @override
  String get settingsCheckForUpdatesSubtitle => '查看是否有新的直接下载版本';

  @override
  String get updateAvailableTitle => '有可用更新';

  @override
  String get updateAvailableBadgeSemantics => '有可用更新';

  @override
  String get updateMandatoryTitle => '需要更新';

  @override
  String updateVersionLine(String current, String latest) {
    return '已安装 $current → $latest';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍后';

  @override
  String get updateDismiss => '忽略';

  @override
  String get updateCancel => '取消';

  @override
  String get updateRetry => '重试';

  @override
  String get updatePreparing => '正在准备下载…';

  @override
  String updateDownloading(int percent) {
    return '正在下载更新… $percent%';
  }

  @override
  String get updateVerifying => '正在校验下载…';

  @override
  String get updateOpeningInstaller => '正在打开安装程序…';

  @override
  String get updateErrorDownload => '下载失败。请检查网络后重试。';

  @override
  String get updateErrorChecksum => '下载文件已损坏，请重试。';

  @override
  String get updateErrorPermission => '未授予安装权限。请在系统设置中允许从此应用安装，然后重试。';

  @override
  String get updateErrorAlreadyRunning => '已有更新正在下载。';

  @override
  String get updateErrorInstallation => '无法打开安装程序，请重试。';

  @override
  String get updateErrorGeneric => '更新失败，请重试。';

  @override
  String get updateUpToDate => '已是最新版本。';

  @override
  String get updateCheckOffline => '无法检查更新，请检查网络连接。';

  @override
  String get updateStoreChannelHint => '此版本来自 TestFlight 或 Play 商店，更新由商店处理。';

  @override
  String get lookupSheetTitle => '查词';

  @override
  String get lookupSectionTranslation => '翻译';

  @override
  String get lookupSectionContextualTranslation => '语境翻译';

  @override
  String get lookupSectionDictionary => '释义';

  @override
  String get lookupErrorRetry => '重试';

  @override
  String get lookupEmpty => '暂无结果。';

  @override
  String get lookupLemma => '词干';

  @override
  String get lookupClose => '关闭';

  @override
  String get lookupCopy => '复制';

  @override
  String get lookupCopySuccess => '已复制到剪贴板';

  @override
  String get lookupTapToExpand => '展开以加载';

  @override
  String get lookupSourceLanguage => '原文语言';

  @override
  String get lookupTargetLanguage => '目标语言';

  @override
  String get lookupSwapLanguages => '交换语言';

  @override
  String get lookupPickSourceTitle => '选择原文语言';

  @override
  String get lookupPickTargetTitle => '选择目标语言';

  @override
  String get lookupRefresh => '刷新';

  @override
  String get lookupSourceResetToLearning => '源语言已重置为学习语言默认值';

  @override
  String get vocabularyAddToVocabulary => '加入生词本';

  @override
  String get vocabularyAddContext => '添加语境';

  @override
  String get vocabularyAlreadyInVocabulary => '已在生词本';

  @override
  String get vocabularyAdding => '添加中…';

  @override
  String get vocabularyRemoving => '删除中…';

  @override
  String get vocabularyConfirmDeleteTitle => '从生词本移除？';

  @override
  String get vocabularyConfirmDeleteBody => '将删除该词及其全部语境。';

  @override
  String get vocabularyCancel => '取消';

  @override
  String get vocabularyDelete => '删除';

  @override
  String get vocabularyTitle => '生词本';

  @override
  String get vocabularyReview => '复习';

  @override
  String get vocabularyAllWords => '全部单词';

  @override
  String get vocabularyDue => '待复习';

  @override
  String get vocabularyStatusNew => '新词';

  @override
  String get vocabularyStatusLearning => '学习中';

  @override
  String get vocabularyStatusReviewing => '复习中';

  @override
  String get vocabularyStatusMastered => '已掌握';

  @override
  String get vocabularyNoWords => '还没有单词';

  @override
  String get vocabularyNoWordsDescription => '在字幕中选中文本并选择「加入生词本」即可开始。';

  @override
  String get vocabularyNoDueItems => '当前没有待复习';

  @override
  String get vocabularyNoDueItemsDescription => '你仍可自定义复习：全部、按状态、按语言或随机抽取。';

  @override
  String get vocabularyNoMatches => '没有匹配的单词';

  @override
  String get vocabularyNoMatchesDescription => '试试其他搜索词，或清除状态与语言筛选。';

  @override
  String get vocabularyCustomReview => '自定义复习';

  @override
  String get vocabularySelectReviewItems => '选择复习范围';

  @override
  String get vocabularyReviewDueItems => '待复习';

  @override
  String get vocabularyReviewDueHint => '今天或更早到期的单词';

  @override
  String get vocabularyReviewAll => '全部单词';

  @override
  String get vocabularyReviewAllHint => '复习生词本中的全部单词';

  @override
  String get vocabularyReviewByStatus => '按状态';

  @override
  String get vocabularyReviewByStatusHint => '聚焦新词、学习中、复习中或已掌握';

  @override
  String get vocabularyReviewByLanguage => '按语言';

  @override
  String get vocabularyReviewByLanguageHint => '按来源语言筛选本次复习';

  @override
  String get vocabularyReviewRandom => '随机';

  @override
  String get vocabularyReviewRandomHint => '随机抽取一组进行练习';

  @override
  String get vocabularyNumberOfWords => '单词数量';

  @override
  String vocabularyQueueCount(int count) {
    return '$count 个单词';
  }

  @override
  String get vocabularyStartReview => '开始复习';

  @override
  String get vocabularyEmptyQueue => '没有符合条件的单词。';

  @override
  String get vocabularyExitReview => '退出复习';

  @override
  String get vocabularyDontKnow => '不会';

  @override
  String get vocabularyKnow => '会';

  @override
  String get vocabularyKnowWell => '很熟';

  @override
  String get vocabularySkip => '跳过';

  @override
  String get vocabularyUndo => '撤销';

  @override
  String vocabularyProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get vocabularyReviewComplete => '复习完成';

  @override
  String get vocabularyReviewCompleteDescription => '做得好，评分已保存。';

  @override
  String get vocabularyDone => '完成';

  @override
  String get vocabularySearchPlaceholder => '搜索单词';

  @override
  String get vocabularyFilterStatus => '状态';

  @override
  String get vocabularyFilterLanguage => '语言';

  @override
  String get vocabularyFilterAll => '全部';

  @override
  String get vocabularyContext => '语境';

  @override
  String get vocabularyDictionary => '词典';

  @override
  String get vocabularyNoContextAvailable => '暂无语境';

  @override
  String get vocabularyDictionaryNotAvailable => '离线时无法显示词典';

  @override
  String get vocabularyOverdue => '已过期';

  @override
  String get vocabularyToday => '今天';

  @override
  String get vocabularyTomorrow => '明天';

  @override
  String vocabularyInDays(int days) {
    return '$days 天后';
  }

  @override
  String get vocabularyFlipHint => '点击翻转';

  @override
  String get vocabularyPronounce => '发音';

  @override
  String get vocabularyFlipHintShortcuts => '空格翻转 · 1 / 2 / 3 评分';

  @override
  String get vocabularyPlaySegment => '播放片段';

  @override
  String get vocabularyOpenInPlayer => '在播放器中打开';

  @override
  String get vocabularyOpenInPlayerDescription => '打开播放器将结束本次复习。已保存的评分不会丢失。';

  @override
  String get vocabularyEchoReading => '回声跟读';

  @override
  String get vocabularyPracticeDismiss => '关闭练习';

  @override
  String get vocabularyPracticePause => '暂停';

  @override
  String get vocabularyPreviousContext => '上一个语境';

  @override
  String get vocabularyNextContext => '下一个语境';

  @override
  String vocabularyContextOfTotal(int current, int total) {
    return '第 $current / $total 个';
  }

  @override
  String get vocabularyContextualTranslation => '语境翻译';

  @override
  String get vocabularyFetchDictionary => '查询词典';

  @override
  String get vocabularyFetchContextual => '翻译语境';

  @override
  String get vocabularyFetching => '加载中…';

  @override
  String get vocabularyAiFetchFailed => '加载失败，请联网后重试。';

  @override
  String get vocabularyMediaUnavailable => '此语境不支持媒体操作';

  @override
  String get vocabularyMediaPlayFailed => '无法播放该片段';

  @override
  String get vocabularyMediaOpenFailed => '无法打开该媒体';

  @override
  String get vocabularyConfirmContinue => '继续';

  @override
  String get vocabularyUnknownSource => '未知来源';

  @override
  String vocabularyLocatorLabel(String start, String duration) {
    return '$start秒 · $duration秒';
  }

  @override
  String get vocabularyExportToAnki => '导出到 Anki';

  @override
  String get vocabularyExport => '导出';

  @override
  String get practicePosterShareTooltip => '分享练习海报';

  @override
  String get practicePosterPreviewTitle => '分享你的练习';

  @override
  String get practicePosterTagline => '跟读练习';

  @override
  String get practicePosterStatTakes => '录音';

  @override
  String get practicePosterStatSentences => '句子';

  @override
  String get practicePosterStatSpoken => '开口';

  @override
  String get practicePosterQrHint => '扫码下载 SP Player\nplayer.enjoy.bot';

  @override
  String get practicePosterShareAction => '分享海报';

  @override
  String get practicePosterShareLabel => '分享';

  @override
  String get practicePosterShareSuccess => '海报已分享。';

  @override
  String get practicePosterSaveSuccess => '海报已保存。';

  @override
  String get practicePosterExportError => '无法分享练习海报。';

  @override
  String get practicePosterLoadError => '无法加载此视频的练习数据。';

  @override
  String get notFoundTitle => '页面未找到';

  @override
  String notFoundSubtitle(String uri) {
    return '找不到 $uri。';
  }

  @override
  String get notFoundBackHome => '返回首页';

  @override
  String get recoveryTitle => '本地数据需要处理';

  @override
  String get recoverySubtitle =>
      'SP Player 无法打开本地数据库。最常见的原因是更新不完整。数据仍然在磁盘上;继续操作前你可以先复制错误信息。';

  @override
  String get recoveryOpenLogs => '打开日志文件夹';

  @override
  String get recoveryOpenLogsError => '无法打开日志文件夹。';

  @override
  String get recoveryCopyError => '复制错误';

  @override
  String get recoveryCopiedToClipboard => '错误详情已复制到剪贴板。';

  @override
  String get recoveryResetLibrary => '重置本地资料库';

  @override
  String get recoveryResetLibrarySubtitle =>
      '清除本地数据库并重新开始。云端资料库不受影响。清除前会将当前状态备份到应用支持目录。';

  @override
  String get recoveryResetLibraryConfirmTitle => '重置本地资料库?';

  @override
  String get recoveryResetLibraryConfirmBody =>
      '这将永久删除你的本地资料库、录音、转写和同步队列。如果已登录,云端资料库会保留。清除前会先在应用支持目录写入一份备份。';

  @override
  String get recoveryResetLibraryConfirmAction => '全部清除';

  @override
  String get recoveryResetLibraryBackupError => '备份失败,本地数据库未被清除。错误已记录。';

  @override
  String get recoveryResetLibrarySuccess => '本地资料库已重置，正在重新加载数据……';

  @override
  String get recoveryResetLibraryError => '无法重置本地资料库。';

  @override
  String get widgetErrorTitle => '出了点问题';

  @override
  String get widgetErrorSubtitle => '此界面遇到意外错误。你可以复制下面的详情，然后尝试前往其他页面。';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsSearchNoResultsTitle => '没有匹配的设置';

  @override
  String get settingsSearchNoResultsHint => '换个关键词试试，或清除搜索以浏览全部设置。';

  @override
  String get settingsSearchClear => '清除搜索';

  @override
  String get settingsSectionNeedsAttention => '需要注意';

  @override
  String get transcriptBlurDisplayTitle => '隐藏字幕文本';

  @override
  String get importCraftFromText => 'Craft…';

  @override
  String get homeCraftAction => 'Craft';

  @override
  String get craftHistoryTooltip => '历史';

  @override
  String get craftHistoryTitle => 'Craft 历史';

  @override
  String get craftHistoryEmptyTitle => '还没有 Craft';

  @override
  String get craftHistoryEmptyHint => '在 Craft 里创建音频后会显示在这里。';

  @override
  String get craftHistoryEmptyAction => '开始创建';

  @override
  String get craftHistoryRemoveTooltip => '移除 Craft 记录';

  @override
  String get craftHistoryRemoveTitle => '移除 Craft 记录？';

  @override
  String craftHistoryRemoveMessage(String title) {
    return '移除「$title」的 Craft 记录。练习音频仍保留在资料库中。';
  }

  @override
  String get craftHistoryRemoveConfirm => '移除';

  @override
  String get craftHistoryRemoved => '已移除 Craft 记录';

  @override
  String get craftHistoryRemoveFailed => '无法移除此 Craft 记录。';

  @override
  String get craftEditUnavailable => '该 Craft 已不存在。';

  @override
  String get craftSourceLanguageLabel => '原文语言';

  @override
  String get craftTargetLanguageLabel => '学习语言';

  @override
  String get craftTextInputHint => '粘贴或输入文本…';

  @override
  String get craftPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get craftCraftingProgress => '正在合成音频…';

  @override
  String get craftSameLanguageHint => '这段文字已经是学习语言了。';

  @override
  String get craftOfflineBanner => '当前离线，合成需要联网。';

  @override
  String get craftSignInRequired => '请登录后使用合成';

  @override
  String get craftSignInCta => '登录';

  @override
  String get craftFailureTts => '无法将文本转为语音。请检查 TTS 提供商设置或重试。';

  @override
  String get craftFailureTranslate => '无法翻译文本。请重试或切换到直接朗读。';

  @override
  String get craftFailureSave => '音频已生成但保存失败。请释放空间后重试。';

  @override
  String get craftRetry => '重试';

  @override
  String get craftOpenAiSettings => '打开 AI 设置';

  @override
  String get libraryProviderCraftBadge => 'Craft';

  @override
  String get craftScreenTitle => 'Craft';

  @override
  String get craftOverline => '用你自己的话生成练习音频';

  @override
  String get craftTranslateTool => '翻译';

  @override
  String get craftSynthesizeTool => '合成';

  @override
  String get craftStyleLabel => '风格';

  @override
  String get craftStyleLiteral => '直译';

  @override
  String get craftStyleNatural => '自然';

  @override
  String get craftStyleCasual => '口语';

  @override
  String get craftStyleFormal => '正式';

  @override
  String get craftStyleSimplified => '简明';

  @override
  String get craftStyleDetailed => '详尽';

  @override
  String get craftStyleCustom => '自定义';

  @override
  String get craftCustomPromptHint => '输入自定义翻译提示…';

  @override
  String get craftSwapLanguages => '交换语言';

  @override
  String get craftTranslateButton => '翻译';

  @override
  String get craftReTranslateButton => '重新翻译';

  @override
  String get craftCopyTranslation => '复制';

  @override
  String get craftCopiedToClipboard => '已复制到剪贴板';

  @override
  String get craftTranslatedText => '翻译结果';

  @override
  String get craftUseTranslatedText => '用于合成';

  @override
  String get craftVoiceLabel => '语音';

  @override
  String get craftNoVoicesForLanguage => '该语言暂无可用语音。';

  @override
  String get craftSynthesizeButton => '合成';

  @override
  String get craftReSynthesizeButton => '重新合成';

  @override
  String get craftSaveToLibrary => '保存到资料库';

  @override
  String get craftPreviewLabel => '预览';

  @override
  String get craftSourceText => '原文';

  @override
  String get craftSynthText => '合成文本';

  @override
  String get craftModeExpress => '快速';

  @override
  String get craftModeAdvanced => '高级';

  @override
  String get craftStageCapture => '录制';

  @override
  String get craftStageRewrite => '改写';

  @override
  String get craftStageAudio => '音频';

  @override
  String get craftCaptureTitle => '说出你的想法';

  @override
  String get craftCaptureSubtitle => '点击录音，用你的母语自然地表达。';

  @override
  String get craftCaptureStop => '停止';

  @override
  String get craftCaptureCancel => '取消';

  @override
  String get craftCaptureTypeInstead => '改为输入文字';

  @override
  String get craftLoadingTranscribing => '正在听写…';

  @override
  String get craftLoadingRewriting => '正在改写…';

  @override
  String get craftLoadingSynthesizing => '正在生成音频…';

  @override
  String get craftRewriteYourWords => '你说的话';

  @override
  String get craftRewriteTargetLabel => '目标语言';

  @override
  String get craftRewriteRegenerate => '重新生成';

  @override
  String get craftRewriteReRecord => '重新录制';

  @override
  String get craftRewriteGenerateAudio => '生成音频';

  @override
  String get craftAudioPreview => '预览';

  @override
  String get craftAudioSaySomethingElse => '保存再说一条';

  @override
  String get craftAudioPracticeNow => '保存并练习';

  @override
  String get craftAudioUnsavedHint => '尚未保存。现在离开会丢弃这段音频，历史记录里也找不到。';

  @override
  String get craftAudioDiscardTitle => '丢弃这段音频？';

  @override
  String get craftAudioDiscardMessage =>
      '生成的音频只有保存后才会保留。现在离开会丢弃它，本次预览已消耗的额度不会退回。';

  @override
  String get craftAudioDiscardConfirm => '丢弃';

  @override
  String get craftSavedToLibrary => '已保存到资料库';

  @override
  String get craftSolidTranscriptSttHint => '如果练习行时间轴不准确，可在字幕面板用语音识别重新生成。';

  @override
  String get craftStyleAuto => '✨ 自动';

  @override
  String get craftFailureAsr => '没有听清楚，请重新录制。';

  @override
  String get craftFailureEmptyTranscript => '录音太短了，请再多说一些。';

  @override
  String get craftRecordingMicDenied => '麦克风权限被拒绝，请在设置中开启。';

  @override
  String get errorGenericLoadFailed => '加载失败，请重试。';

  @override
  String get subscriptionViewPlansAndPackages => '查看方案与积分包';

  @override
  String get byokProviderBillingMessage => '你的 AI 服务商拒绝了本次请求。请检查该服务商的账单或套餐。';

  @override
  String get pronouncePlay => '播放发音';

  @override
  String get pronounceStop => '停止发音';

  @override
  String get pronounceLoading => '正在加载发音…';

  @override
  String get pronounceUnavailableLanguage => '暂不支持此语言的发音';

  @override
  String get pronounceTextTooLong => '文本过长，无法发音';

  @override
  String get pronounceFailed => '无法播放发音';

  @override
  String get assessmentPlayMyRecording => '播放我的录音';

  @override
  String get assessmentStopMyRecording => '停止我的录音';

  @override
  String get assessmentRecordingUnavailable => '录音文件不可用';

  @override
  String get assessmentPlayMyClip => '播放该词的录音片段';

  @override
  String get assessmentStopMyClip => '停止该词的录音片段';

  @override
  String get assessmentClipUnavailable => '该词没有可用的录音片段';

  @override
  String get onboardingTipSkip => '跳过';

  @override
  String get onboardingTipHomeImportTitle => '导入媒体';

  @override
  String get onboardingTipHomeImportBody => '导入本地文件或 YouTube 视频，开始跟读练习。';

  @override
  String get onboardingTipHomeCraftTitle => 'Craft';

  @override
  String get onboardingTipHomeCraftBody => '还没有视频时，可以用文字生成练习音频。';

  @override
  String get onboardingTipEmptyTranscriptLocalTitle => '添加字幕';

  @override
  String get onboardingTipEmptyTranscriptLocalBody => '从文件提取字幕，或导入字幕文件，即可按句练习。';

  @override
  String get onboardingTipEmptyTranscriptYoutubeTitle => '获取字幕';

  @override
  String get onboardingTipEmptyTranscriptYoutubeBody =>
      '从云端拉取此 YouTube 视频的字幕，解锁练习功能。';

  @override
  String get onboardingTipEchoTitle => 'Echo 跟读';

  @override
  String get onboardingTipEchoBody => '打开 Echo，即可逐句跟读并对照原音练习。';

  @override
  String get onboardingTipRecordTitle => '录下你的声音';

  @override
  String get onboardingTipRecordBody => '在句子上录音，再与原音对比。';

  @override
  String get onboardingTipAssessTitle => '发音评估';

  @override
  String get onboardingTipAssessBody => '录音后可查看该条发音反馈。';

  @override
  String get settingsResetProductTipsTitle => '重置产品提示';

  @override
  String get settingsResetProductTipsSubtitle => '重新显示首页与播放器的新手提示。';

  @override
  String get settingsResetProductTipsConfirmTitle => '重置产品提示？';

  @override
  String get settingsResetProductTipsConfirmBody =>
      'Craft、导入、字幕与练习相关提示会再次出现。媒体库与账号不受影响。';

  @override
  String get settingsResetProductTipsConfirmAction => '重置提示';

  @override
  String get settingsResetProductTipsDone => '已重置产品提示';

  @override
  String get settingsAnalyticsCaptureTitle => '使用数据分析';

  @override
  String get settingsAnalyticsCaptureSubtitle =>
      '分享匿名使用数据，帮助改进 Enjoy。绝不包含你的媒体、字幕或笔记。';

  @override
  String get transcriptEmptyFetchYoutube => '获取字幕';

  @override
  String homeGoalOfMinutes(int minutes) {
    return '共 $minutes 分钟';
  }

  @override
  String homeGoalProgressRemaining(int done, int goal, int left) {
    return '$done / $goal 分钟 · 还差 $left 分钟';
  }

  @override
  String homeGoalProgressDone(int done, int goal) {
    return '$done / $goal 分钟';
  }

  @override
  String get homeContinueAction => '继续';

  @override
  String get homeOpenLibrary => '打开媒体库';

  @override
  String homeContinueLine(int line, int total) {
    return '第 $line/$total 行';
  }

  @override
  String get homeContinueEchoOn => '跟读中';

  @override
  String get mediaRelativeToday => '今天';

  @override
  String get mediaRelativeYesterday => '昨天';

  @override
  String libraryTileAdded(String date) {
    return '添加于 $date';
  }

  @override
  String get vocabularyOverline => '我的单词本';

  @override
  String vocabularyReviewDueAction(int count) {
    return '复习 $count 个到期单词';
  }

  @override
  String get vocabularyDueToday => '今天到期';

  @override
  String vocabularyDueEstimate(int minutes) {
    return '今天及之前到期的单词 · 约 $minutes 分钟';
  }

  @override
  String get vocabularyByStatus => '按状态';

  @override
  String vocabularyDueWaiting(int count) {
    return '$count 个单词等你复习';
  }

  @override
  String get vocabularyDueReviewBody => '今天及之前到期的单词。空格翻卡，1、2、3 评分。';

  @override
  String vocabularyFilterValue(String label, String value) {
    return '$label：$value';
  }

  @override
  String get vocabularyFewer => '减少';

  @override
  String get vocabularyMore => '增加';

  @override
  String get libraryOverlineLocal => '本设备';

  @override
  String get libraryOverlineCloud => '保存在你的 Enjoy 账户';

  @override
  String librarySearchResults(int count, String query) {
    return '“$query” 有 $count 个结果';
  }

  @override
  String get discoverOverline => '你订阅的 YouTube 频道';

  @override
  String get discoverRecentUploads => '最新上传';

  @override
  String discoverUpdatedAgo(String age) {
    return '更新于 $age';
  }

  @override
  String discoverHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String discoverDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String discoverMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String get discoverJustNow => '刚刚';

  @override
  String get discoverAddToLibraryAction => '加入媒体库';

  @override
  String get discoverStripSubscribe => '订阅';

  @override
  String get playerEchoShort => '回声';

  @override
  String playerLineOfTotal(Object line, Object total) {
    return '第 $line/$total 行';
  }

  @override
  String get assessmentMarginOverline => '发音评估';

  @override
  String get assessmentLevelExcellent => '优秀';

  @override
  String get assessmentLevelGood => '良好';

  @override
  String get assessmentLevelFair => '一般';

  @override
  String get assessmentLevelPoor => '待提高';

  @override
  String get playerMore => '更多';

  @override
  String get playerMoreDescEditTranscript => '在编辑器中修改当前字幕稿的文字与时间';

  @override
  String get playerMoreDescAddSubtitleFile => '从电脑选择 .srt / .vtt 等字幕文件，导入为新字幕轨';

  @override
  String get playerMoreDescEmbeddedSubtitles =>
      '提取视频文件（MKV/MP4 等）内部自带的字幕轨，无需语音识别';

  @override
  String get playerMoreDescAiTranscript =>
      '用本地语音识别生成或重新生成字幕；老视频重新转写后可享受最新的对轴校准';

  @override
  String get playerMoreDescWordTimings => '为每个词添加精确时间与音标，用于卡拉OK式逐词高亮和跟读练习';

  @override
  String get playerMoreDescRefreshFromCloud =>
      '重新从云端拉取字幕稿（YouTube 官方字幕，或登录后云同步的字幕）';

  @override
  String get playerMoreDescDownloadTranscript => '把当前字幕稿导出为 .srt 字幕文件保存到电脑';

  @override
  String get playerMoreDescEditDetails => '修改这个视频的标题、封面等信息';

  @override
  String get playerMoreDescExportLoopClip => '把当前 Echo 循环片段单独导出为视频片段（有循环激活时可用）';

  @override
  String get playerMoreTranscriptSection => '字幕文本';

  @override
  String get playerMoreAddSubtitleFile => '添加字幕文件…';

  @override
  String get playerMoreUseEmbeddedSubtitles => '使用内嵌字幕…';

  @override
  String get playerMoreCreateAiTranscript => '生成 AI 字幕…';

  @override
  String get playerMoreTranscribeAgain => '重新转写…';

  @override
  String get playerMoreAddWordTimings => '添加逐词时间与音标';

  @override
  String get playerMoreAddIpa => '添加音标（IPA）';

  @override
  String get playerMoreRefreshFromCloud => '从云端刷新';

  @override
  String get playerMoreEditTranscript => '编辑字幕';

  @override
  String get transcriptEditorTitle => '编辑字幕';

  @override
  String get transcriptEditorSave => '保存';

  @override
  String get transcriptEditorSaved => '字幕已更新';

  @override
  String get transcriptEditorSaveFailed => '字幕保存失败，请重试。';

  @override
  String get transcriptEditorInvalidTiming => '开始时间和时长必须是秒数，例如 1.25。';

  @override
  String get transcriptEditorEmpty => '这条媒体没有可编辑的字幕。';

  @override
  String get transcriptEditorNoCues => '这条字幕没有可编辑的台词。';

  @override
  String get transcriptEditorDiscardTitle => '放弃未保存的修改？';

  @override
  String get transcriptEditorDiscardMessage => '你对这条字幕的修改尚未保存。';

  @override
  String get transcriptEditorDiscardConfirm => '放弃';

  @override
  String transcriptEditorLineLabel(int index) {
    return '第 $index 行';
  }

  @override
  String get transcriptEditorFieldStart => '开始（秒）';

  @override
  String get transcriptEditorFieldDuration => '时长（秒）';

  @override
  String get playerMoreDownloadTranscript => '下载字幕稿…';

  @override
  String get playerMoreTranslateAll => '翻译全片';

  @override
  String get fullTranslateBannerCta => '翻译全片';

  @override
  String get fullTranslateBannerContinue => '继续翻译';

  @override
  String fullTranslateBannerRunningTitle(int translated, int total) {
    return '翻译中 $translated / $total 句';
  }

  @override
  String fullTranslateBannerCachedProgress(int translated, int total) {
    return '已缓存 $translated / $total 句';
  }

  @override
  String fullTranslateBannerReachedMinute(int minutes) {
    return '已翻译到视频第 $minutes 分钟';
  }

  @override
  String fullTranslateBannerPausedFailure(int failed) {
    return '有 $failed 句翻译失败，可点「继续翻译」重试';
  }

  @override
  String get fullTranslateBannerPausedStopped => '已停止，可点「继续翻译」接着翻';

  @override
  String get fullTranslateBannerErrorGeneric => '无法开始翻译，请检查字幕与语言设置';

  @override
  String get fullTranslateBannerErrorConfig => '请先在「设置 → AI」配置云端语言模型';

  @override
  String fullTranslateExportIncomplete(int remaining) {
    return '还有 $remaining 句未翻译，请先执行「翻译全片」';
  }

  @override
  String get playerMoreMediaSection => '媒体';

  @override
  String get playerMoreEditDetails => '编辑详情';

  @override
  String get playerMoreExportLoopClip => '将循环导出为片段…';

  @override
  String get playerMoreExportLoopClipSuccess => '循环片段已导出';

  @override
  String get playerMoreExportLoopClipFailed => '无法导出循环片段';

  @override
  String get playerMoreExportLoopClipFfmpegMissing => '此设备上没有可用的 FFmpeg';

  @override
  String get playerMoreKeyboardShortcuts => '键盘快捷键';

  @override
  String get subtitlesPanelTitle => '字幕与显示';

  @override
  String get subtitlesSectionSubtitles => '字幕';

  @override
  String get subtitlesSectionDisplay => '显示';

  @override
  String get transcriptTypefaceLabel => '字幕字体';

  @override
  String get transcriptTypefaceBook => '书本';

  @override
  String get transcriptTypefaceClean => '简洁';

  @override
  String get subtitlesHighlightSpokenWord => '高亮正在朗读的词';

  @override
  String get subtitlesHighlightSpokenWordHint => '朗读到哪个词，就在哪个词下画线。';

  @override
  String get subtitlesIpaUnderWords => '在词下显示音标';

  @override
  String get subtitlesCaptionOverlay => '视频下方字幕';

  @override
  String get subtitlesCaptionOverlayHint => '在视频画面下方显示当前句，背景透明。';

  @override
  String get subtitlesCaptionModeOff => '关闭';

  @override
  String get subtitlesCaptionModeOriginal => '原文';

  @override
  String get subtitlesCaptionModeTranslation => '译文';

  @override
  String get subtitlesCaptionModeBoth => '双语';

  @override
  String get subtitlesIpaUnderWordsHint => '点按单词即可试听。';

  @override
  String get subtitlesNeedsWordTimingsMore => '请先添加逐词时间与音标（··· 更多）。';

  @override
  String get subtitlesNeedsWordTimingsBelow => '请先添加逐词时间与音标（见下方）。';

  @override
  String get subtitlesManageFromMore => '在 ··· 更多 中添加或替换字幕。';

  @override
  String get transcriptEnrichRunningOwned => '正在生成逐词时间与发音';

  @override
  String get transcriptEnrichRunningYoutube => '正在生成发音';

  @override
  String get playerDictateShort => '听写';

  @override
  String get playerDictateHintHover => '听写 · 先听，再把鼠标移到一行上偷看';

  @override
  String get playerDictateHintHold => '长按可显示';

  @override
  String playerDockPractisedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已练习 $count 句',
      zero: '还没有练习过的句子',
    );
    return '$_temp0';
  }

  @override
  String playerDockLoopingLine(int line) {
    return '正在循环第 $line 句';
  }

  @override
  String playerDockLoopingLines(int start, int end) {
    return '正在循环第 $start–$end 句';
  }

  @override
  String playerDockLoopHint(String seconds) {
    return '$seconds 秒 · + 加一句，− 去一句';
  }

  @override
  String playerDockRecordingProgress(String elapsed, String total) {
    return '录音中 · $elapsed 秒 / $total 秒';
  }

  @override
  String playerDockDictatingLine(int line) {
    return '正在听写第 $line 句';
  }

  @override
  String get playerDockDictateHover => '把鼠标移到一行上偷看';

  @override
  String get playerDockDictateHold => '长按可显示';

  @override
  String get playerRepeatOff => '重复：关';

  @override
  String get playerRepeatItem => '重复播放整个内容';

  @override
  String get playerRepeatLoop => '重复播放回声片段';

  @override
  String playerMarginCloseTooltip(String close) {
    return '$close · Esc';
  }

  @override
  String takeNumbered(int number) {
    return '第 $number 遍';
  }

  @override
  String takesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 遍',
    );
    return '$_temp0';
  }

  @override
  String get takeNotScoredClick => '还没有评分 · 点击评分';

  @override
  String get takeNotScoredTap => '还没有评分 · 轻点评分';

  @override
  String get takesMarginTitleClick => '你的录音 · 点击播放';

  @override
  String get takesMarginTitleTap => '你的录音 · 轻点播放';

  @override
  String get takesPitchOnLoop => '在循环上显示音高曲线';

  @override
  String lookupInThisAudio(String time) {
    return '本音频 · $time';
  }

  @override
  String lookupInThisVideo(String time) {
    return '本视频 · $time';
  }

  @override
  String takeAssessmentTitle(int number) {
    return '第 $number 遍 · 评估';
  }

  @override
  String get settingsSectionNetwork => '网络';

  @override
  String get settingsSectionNetworkHint => '代理与 VPN 路由';

  @override
  String get settingsNetworkProxyModeTitle => '代理模式';

  @override
  String get settingsNetworkProxyModeSystem => '系统';

  @override
  String get settingsNetworkProxyModeManual => '手动';

  @override
  String get settingsNetworkProxyModeDirect => '直连';

  @override
  String get settingsNetworkProxyModeHint =>
      '“系统”跟随操作系统代理（Clash、sing-box 等）；“手动”使用下方地址；“直连”不使用任何代理。';

  @override
  String get settingsNetworkProxyUrlLabel => '代理地址';

  @override
  String get settingsNetworkProxyUrlHint => '127.0.0.1:7890 或 http://主机:端口';

  @override
  String get settingsNetworkProxyUrlInvalid =>
      '请输入 host:port 形式的 HTTP 代理，暂不支持 SOCKS 代理。';

  @override
  String get settingsNetworkProxySave => '保存代理';

  @override
  String get settingsNetworkProxySaved => '代理设置已保存。';

  @override
  String get settingsNetworkEffectiveTitle => '当前生效的代理';

  @override
  String get settingsNetworkEffectiveDirect => '直连（无代理）';

  @override
  String settingsNetworkEffectiveProxy(String endpoint, String source) {
    return '$endpoint（$source）';
  }

  @override
  String get settingsNetworkTestButton => '测试连接';

  @override
  String get settingsNetworkTestRunning => '正在测试…';

  @override
  String get settingsNetworkTestYoutube => 'YouTube';

  @override
  String settingsNetworkTestOk(String label, int ms, String route) {
    return '$label：可访问，耗时 $ms 毫秒，路由 $route';
  }

  @override
  String settingsNetworkTestFail(String label, String route, String error) {
    return '$label：失败，路由 $route（$error）';
  }

  @override
  String get playerDictationVoiceMode => '语音复述';

  @override
  String get playerDictationTextMode => '文字输入';

  @override
  String get playerDictationVoiceHint => '仔细聆听并用语音复述。准备好后点录音。';

  @override
  String get playerDictationVoiceHintHotkey => '仔细聆听并用语音复述。准备好后点录音或按 R。';

  @override
  String get playerDictationTextPlaceholder => '输入你听到的内容…';

  @override
  String playerDictationWordCountProgress(int typed, int total) {
    return '已输入 $typed / 约 $total 词';
  }

  @override
  String get playerDictationCheckAnswer => '核对答案';

  @override
  String get playerDictationCheckingVoice => '正在识别语音…';

  @override
  String get playerDictationTryAgain => '再试一次';

  @override
  String get playerDictationNextLine => '下一句';

  @override
  String get playerDictationRetryTranscription => '重试识别';

  @override
  String get playerDictationLegendCorrect => '正确';

  @override
  String get playerDictationLegendMissed => '遗漏';

  @override
  String get playerDictationLegendExtra => '多余';

  @override
  String playerDictationStatsCorrect(int count) {
    return '$count 个正确';
  }

  @override
  String playerDictationStatsMissed(int count) {
    return '$count 个遗漏';
  }

  @override
  String playerDictationStatsExtra(int count) {
    return '$count 个多余';
  }

  @override
  String playerDictationPreviousAttempts(int count) {
    return '历史听写记录（$count）';
  }

  @override
  String playerDictationAttemptAccuracy(int accuracy) {
    return '$accuracy% 正确率';
  }

  @override
  String get playerDictationRecordAgain => '重新录音';

  @override
  String get playerDictationRecordRetelling => '录音复述';

  @override
  String get playerDictationRecordRetellingHotkey => '录音复述 (R)';

  @override
  String get playerDictationHeaderListen => '听写 — 聆听并复述';

  @override
  String get playerDictationHeaderChecked => '听写 — 已核对';

  @override
  String get settingsSectionLocalComponents => '本地组件';

  @override
  String get settingsSectionLocalComponentsHint => '管理离线识别 / 翻译的模型组件（下载、删除）。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'SP Player';

  @override
  String get libraryTitle => '资料库';

  @override
  String get homeTitle => '首页';

  @override
  String get homeRecentMedia => '最近媒体';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homeEmptyTitle => '暂无最近媒体';

  @override
  String get homeContinuePracticing => '继续练习';

  @override
  String homeContinueOpenSemantics(String title) {
    return '继续练习，$title';
  }

  @override
  String get homeEmptyHint => '导入媒体或将文件拖放到此处开始。';

  @override
  String get libraryTabAudio => '音频';

  @override
  String get libraryTabVideo => '视频';

  @override
  String get libraryEmptyAudioTitle => '未找到任何音频';

  @override
  String get libraryEmptyAudioHint => '资料库中暂无音频。';

  @override
  String get libraryEmptyVideoTitle => '未找到任何视频';

  @override
  String get libraryEmptyVideoHint => '资料库中暂无视频。';

  @override
  String get librarySearchNoMatchesTitle => '没有匹配结果';

  @override
  String get librarySearchNoMatchesHint => '没有符合条件的内容。';

  @override
  String get librarySearchHint => '搜索媒体库';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get libraryDeleteFailed => '无法删除该项目，请重试。';

  @override
  String get transcriptAccessibilityTranscriptList => '字幕';

  @override
  String transcriptAccessibilityCue(String time, String snippet) {
    return '$time。$snippet';
  }

  @override
  String get transcriptAccessibilityCurrentLine => '当前播放行。';

  @override
  String get transcriptAccessibilityEchoRegion => '跟读练习区域。';

  @override
  String get transcriptAccessibilityEchoCurrentLine => '当前跟读行。';

  @override
  String transcriptLineRecordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条录音',
      one: '1 条录音',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorFriendlyTitle => '字幕暂不可用';

  @override
  String get transcriptErrorFriendlyHint => '请选择其他字幕轨道或导入字幕文件。';

  @override
  String get transcriptFetchingSubtitles => '正在获取字幕…';

  @override
  String get transcriptSearchHint => '搜索字幕';

  @override
  String get transcriptSearchNoMatches => '没有匹配的句子';

  @override
  String get lookupSectionExplain => '讲解这句';

  @override
  String get libraryTabPlaylists => '播放列表';

  @override
  String get playlistCreateButton => '新建播放列表';

  @override
  String get playlistRename => '重命名';

  @override
  String get playlistDelete => '删除播放列表';

  @override
  String get playlistNameHint => '播放列表名称';

  @override
  String get playlistSave => '保存';

  @override
  String get playlistEmptyTitle => '还没有播放列表';

  @override
  String get playlistEmptyHint => '创建一个播放列表，把媒体分组按顺序播放。';

  @override
  String playlistItemCount(int count) {
    return '$count 个条目';
  }

  @override
  String get playlistAddMedia => '添加媒体';

  @override
  String get playlistPlayAll => '播放全部';

  @override
  String get playlistRemoveItem => '移出播放列表';

  @override
  String get playlistMoveUp => '上移';

  @override
  String get playlistMoveDown => '下移';

  @override
  String get playlistMissingMedia => '媒体已不在媒体库中';

  @override
  String get playlistPickerNoMedia => '先导入媒体，再在这里添加。';

  @override
  String get asrStatusExtracting => '正在提取音频…';

  @override
  String get asrStatusUploading => '正在上传音频…';

  @override
  String get asrLanguageTitle => '语音语言';

  @override
  String get asrLanguageAutoDetect => '自动检测语言';

  @override
  String get asrStatusRecognizing => '正在识别…';

  @override
  String get asrStatusPolling => '正在转写…';

  @override
  String get asrStatusSaving => '正在保存…';

  @override
  String get asrStatusSuccess => '字幕已就绪';

  @override
  String get asrStatusCancelled => '已取消';

  @override
  String get asrStatusAligning => '正在对齐…';

  @override
  String get asrStageExtract => '提取音频';

  @override
  String get asrStageRecognize => '识别';

  @override
  String get asrStageAlign => '对齐';

  @override
  String get asrStageSegment => '断句';

  @override
  String get asrBannerElapsed => '已用时';

  @override
  String asrBannerEngine(String engine) {
    return '引擎 $engine';
  }

  @override
  String get asrErrorGeneric => '生成字幕失败';

  @override
  String get asrErrorFfmpegUnavailable => '当前设备无法提取音频';

  @override
  String get asrErrorNoAudioTrack => '此文件没有可识别的音频';

  @override
  String get asrErrorExtractionFailed => '音频提取失败，请重试。';

  @override
  String get asrErrorFileTooLarge => '文件过大，无法生成字幕';

  @override
  String get asrErrorUnsupportedSource => '不支持此类来源';

  @override
  String get asrErrorUnsupportedMedia => '此音频格式不支持长音频转写';

  @override
  String get asrErrorProviderTimeout => '转写超时，请重试。';

  @override
  String get asrErrorProviderRetryable => '转写失败，请重试。';

  @override
  String get asrErrorByokMissing => '请先配置 AI 服务以生成字幕';

  @override
  String get asrErrorNetwork => '网络错误，请检查连接后重试。';

  @override
  String get asrErrorNoSpeech => '未检测到语音';

  @override
  String get asrLongMediaConfirmTitle => '这可能需要一些时间';

  @override
  String asrLongMediaConfirmBody(int minutes) {
    return '为 $minutes 分钟的音频生成字幕可能需要数分钟（本机模型识别，不产生任何费用）。是否继续？';
  }

  @override
  String get asrLongMediaConfirmContinue => '继续';

  @override
  String get asrLongMediaConfirmCancel => '取消';

  @override
  String get actionImport => '导入';

  @override
  String get importFromFile => '从文件…';

  @override
  String get importFromYoutube => '从 YouTube 链接…';

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverBrowseAction => '浏览发现';

  @override
  String get discoverRecommendedHeading => '推荐频道';

  @override
  String get discoverSubscribeTitle => '订阅频道';

  @override
  String get discoverSubscribeHint => '粘贴 YouTube 频道链接或 @用户名';

  @override
  String get discoverSubscribePlaceholder => 'https://www.youtube.com/@channel';

  @override
  String get discoverSubscribeAction => '订阅';

  @override
  String get discoverSubscribed => '已订阅频道';

  @override
  String get discoverSubscribedLabel => '已订阅';

  @override
  String get discoverSubscribeFailed => '无法订阅该频道。';

  @override
  String get discoverUnsubscribeAction => '取消订阅';

  @override
  String get discoverUnsubscribed => '已取消订阅';

  @override
  String get discoverAddToLibrary => '加入库';

  @override
  String get discoverAddedToLibrary => '已加入你的库';

  @override
  String get discoverAddFailed => '无法添加此视频。';

  @override
  String get discoverInLibrary => '已在库中';

  @override
  String get discoverFeedEmptyTitle => '暂无视频';

  @override
  String get discoverFeedEmptyHint => '订阅频道并刷新以加载最新上传。';

  @override
  String get discoverFeedErrorTitle => '无法加载动态';

  @override
  String get discoverFeedErrorHint => '请检查网络连接后重试。';

  @override
  String get discoverRetry => '重试';

  @override
  String get discoverRefreshPartialFailed => '部分频道动态刷新失败。';

  @override
  String discoverRefreshPartialFailedDetail(int count, String names) {
    return '无法刷新 $count 个频道：$names';
  }

  @override
  String discoverRefreshSingleFailed(Object name) {
    return '无法刷新 $name。';
  }

  @override
  String get discoverRecommendedLoadFailed => '无法加载推荐频道。';

  @override
  String get discoverSubscriptionsLoadFailed => '无法加载订阅。';

  @override
  String get discoverNoSubscriptionsHint => '订阅推荐频道，或粘贴频道链接。';

  @override
  String get discoverManageChannels => '管理频道';

  @override
  String get discoverFilterAll => '全部';

  @override
  String get discoverYourChannelsHeading => '你的频道';

  @override
  String get discoverRecommendedAllSubscribed => '你已订阅全部推荐频道。';

  @override
  String get youtubeImportTitle => '导入 YouTube 视频';

  @override
  String get youtubeImportHint => '粘贴 YouTube 链接或视频 ID';

  @override
  String get youtubeImportInvalid => '无法识别有效的 YouTube 视频 ID。';

  @override
  String get youtubeImporting => '正在添加视频…';

  @override
  String get youtubeBadge => 'YouTube';

  @override
  String get youtubeLoginTooltip => 'YouTube 账号';

  @override
  String get youtubeOpenInBrowser => '在浏览器中打开';

  @override
  String get youtubeLoginClose => '关闭';

  @override
  String get youtubeLoginScreenTitle => 'YouTube 登录';

  @override
  String get youtubeLogout => '退出登录（清除 Cookie）';

  @override
  String get youtubeUnavailableOnDevice => '此设备无法播放 YouTube 视频。';

  @override
  String get youtubeUnavailableRuntimeMissing => '此设备缺少 YouTube 播放运行时。';

  @override
  String get youtubeUnavailableRuntimeInitFailed => 'YouTube 播放环境启动失败。';

  @override
  String get youtubeUnavailableCodecsMissing =>
      '此设备缺少 YouTube 视频解码器。请安装 GStreamer 插件（gst-plugins-good、gst-plugins-bad、gst-libav）后重启应用。';

  @override
  String get youtubeUnavailableDisabledByBuild => '此构建已停用 YouTube 播放。';

  @override
  String get youtubeTapToPlayHint => '点一下视频即可播放';

  @override
  String get youtubeVideoStallRelaunch =>
      '此 GPU 无法渲染 YouTube 视频。重启应用即可使用软件渲染恢复画面。';

  @override
  String get transportFullscreen => '全屏';

  @override
  String get transportExitFullscreen => '退出全屏';

  @override
  String get settingsTitle => '设置';

  @override
  String get importMedia => '导入媒体';

  @override
  String get importingMedia => '正在导入媒体…';

  @override
  String get importMediaFailed => '无法导入此文件。';

  @override
  String get importUnsupportedFileType => '不支持的文件类型，请选择音频或视频文件。';

  @override
  String get navMainLabel => '主导航';

  @override
  String get miniPlayerMediaVideo => '视频';

  @override
  String get miniPlayerMediaAudio => '音频';

  @override
  String get retry => '重试';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsAboutSubtitle => 'SP Player — 本地字幕与跟读练习';

  @override
  String get settingsThemeDarkLocked => '跟随系统外观';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get previousLine => '上一句';

  @override
  String get nextLine => '下一句';

  @override
  String get replayLine => '重播本句';

  @override
  String get echoMode => '回声模式';

  @override
  String get playerListenModeTitle => '聆听';

  @override
  String get playerDockHideText => '隐藏文本';

  @override
  String playerDockLinePosition(int line, int total) {
    return '第 $line / $total 句';
  }

  @override
  String get playerDockLooping => '· 循环中';

  @override
  String get transcript => '字幕稿';

  @override
  String get playerTranscriptResizeHint => '拖动以调整字幕稿面板大小';

  @override
  String get importSubtitle => '导入字幕';

  @override
  String get noTranscript => '暂无字幕稿';

  @override
  String get transcriptEmptyOverline => '字幕';

  @override
  String get loading => '加载中…';

  @override
  String get error => '错误';

  @override
  String get playerOpenGenericError => '无法打开此项目。';

  @override
  String playbackRateTimes(String rate) {
    return '$rate 倍';
  }

  @override
  String get speed => '速度';

  @override
  String get volume => '音量';

  @override
  String get subtitles => '字幕';

  @override
  String get subtitlesPrimary => '主字幕';

  @override
  String get subtitlesTranslation => '翻译（可选）';

  @override
  String get subtitlesNone => '无';

  @override
  String get subtitlesNotSelected => '未选择';

  @override
  String get subtitlesDeleteTrack => '删除轨道';

  @override
  String get importSubtitleSuccess => '字幕已导入';

  @override
  String get noTranscriptHint => '可添加字幕文件、提取内嵌字幕，或用 AI 生成。';

  @override
  String get noTranscriptHintRemote => '云端字幕可用时会自动加载。可在 CC 菜单中刷新。';

  @override
  String get transcriptEmptyExtract => '提取';

  @override
  String get transcriptEmptyAlign => '对齐已有字幕 / 台本';

  @override
  String get transcriptAlignNotInstalled => '对齐组件未安装，请到「设置 → 本地组件」安装';

  @override
  String get transcriptAlignPipelinePending => '已检测到对齐组件，词级对齐将随下一个组件包发布';

  @override
  String get transcriptEmptyAddSubtitle => '添加字幕';

  @override
  String get transcriptEmptyGenerate => 'AI 字幕稿';

  @override
  String get subtitlesImportLanguageTitle => '字幕语言';

  @override
  String get subtitlesImportLanguageHint => 'BCP-47 代码（如 en、zh-TW）。未知请填 und。';

  @override
  String get subtitlesImportLanguageFieldLabel => '语言代码';

  @override
  String get subtitlesProviderOfficial => '官方';

  @override
  String get subtitlesProviderAuto => '自动';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => '用户';

  @override
  String get subtitlesAutoTranslate => '自动翻译';

  @override
  String subtitlesAutoTranslateLanguageChip(String language) {
    return '译为 $language';
  }

  @override
  String get subtitlesExtractNoTracks =>
      '此文件无内嵌字幕轨道（仅含视频和音频）。若有单独的 .srt 或 .vtt 文件，请使用导入。';

  @override
  String subtitlesExtractedCount(int count) {
    return '已提取 $count 条字幕轨道。';
  }

  @override
  String get subtitlesRefreshDone => '已从云端更新字幕稿。';

  @override
  String get transcriptDownloadDialogTitle => '下载字幕稿';

  @override
  String get transcriptDownloadEmpty => '还没有可下载的字幕稿。';

  @override
  String get transcriptDownloadSuccess => '字幕稿已下载。';

  @override
  String get transcriptDownloadError => '无法下载字幕稿。';

  @override
  String get subtitlesNoPlayableUri => '无法解析此项目的可播放文件。';

  @override
  String get expandEchoBackward => '向后扩展回声';

  @override
  String get expandEchoForward => '向前扩展回声';

  @override
  String get shrinkEchoBackward => '向后收缩回声';

  @override
  String get shrinkEchoForward => '向前收缩回声';

  @override
  String echoLoopCaptionLine(String range, String seconds) {
    return '循环 · 第 $range 句 · $seconds 秒';
  }

  @override
  String echoLoopCaptionLines(String range, String seconds) {
    return '循环 · 第 $range 句 · $seconds 秒';
  }

  @override
  String echoLoopCaptionRecording(int count) {
    return '录音 · 第 $count 遍';
  }

  @override
  String get shadowReadingHint => '跟读本段练习口语，录制你的声音并与参考音高对比。';

  @override
  String get pitchContourTitle => '音高曲线';

  @override
  String get pitchContourError => '无法分析本段的音高。';

  @override
  String get pitchContourWaveform => '波形';

  @override
  String get pitchContourReference => '原声音高';

  @override
  String get pitchContourUser => '你的音高';

  @override
  String get pitchContourAnalyzing => '正在分析音高…';

  @override
  String get shadowRecordingEmpty => '本段尚无录音。';

  @override
  String get shadowRecordingTake => '录音';

  @override
  String get shadowTakesEmptyPrefix => '这段还没有录音，按';

  @override
  String get shadowTakesEmptySuffix => '读一遍。';

  @override
  String get shadowRecordingPlay => '播放';

  @override
  String get shadowRecordingChooseTake => '切换录音';

  @override
  String get shadowRecordingDelete => '删除';

  @override
  String get shadowRecordingDeleteConfirmTitle => '删除此条录音？';

  @override
  String shadowRecordingDeleteConfirmMessage(String takeLabel) {
    return '将永久删除 $takeLabel，无法撤销。';
  }

  @override
  String get shadowRecordingRecord => '录音';

  @override
  String get shadowRecordingStop => '停止';

  @override
  String get shadowRecordingMicDenied => '需要麦克风权限才能录音。';

  @override
  String shadowRecordingSaveFailed(String reason) {
    return '无法保存录音：$reason';
  }

  @override
  String get settingsSectionAi => 'AI';

  @override
  String get settingsSectionAiHint => '为各功能配置你自己的 API 密钥；识别与翻译默认使用本地组件。';

  @override
  String get settingsAiProvidersTileTitle => 'AI 提供商';

  @override
  String get settingsAiProvidersSpeechKindHintOpenAi =>
      'OpenAI 兼容：用于语音转文字（生成字幕、听写、跟读复述）。';

  @override
  String get settingsAiProvidersSpeechKindHintAzure =>
      'Azure 语音：音素级发音诊断；也支持语音转文字。不配置则跟读打分自动走本地评估。';

  @override
  String byokNotConfiguredMessage(String modality) {
    return '「$modality」选择了自带密钥（BYOK），但本机尚未保存 API Key。';
  }

  @override
  String get byokNotConfiguredOpenSettings => '请先在 设置 → AI 服务商 中添加你的 API Key。';

  @override
  String get settingsSectionRecording => '录音';

  @override
  String get settingsSectionRecordingHint => '跟读录音所使用的麦克风';

  @override
  String get settingsTranscriptEnrichmentTitle => '对齐词级时间轴';

  @override
  String get settingsTranscriptKaraokeTitle => '高亮当前词';

  @override
  String get settingsTranscriptIpaOverlayTitle => '显示音标（IPA）';

  @override
  String get transcriptKaraokeUnavailableRemoteHint => '卡拉 OK 高亮需要本地文件的逐词时间。';

  @override
  String get transcriptEnrichOwnedSubtitle => '使用本条目的音频，播放不受影响。';

  @override
  String get transcriptEnrichYoutubeSubtitle => '卡拉 OK 高亮仍不可用，不会下载视频。';

  @override
  String get transcriptEnrichCancel => '取消生成';

  @override
  String get transcriptEnrichRetry => '重新生成';

  @override
  String get transcriptEnrichFailed => '无法生成。点按重试。';

  @override
  String transcriptEnrichProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get settingsRecordingMicTitle => '麦克风';

  @override
  String settingsRecordingMicAuto(String label) {
    return '自动 · $label';
  }

  @override
  String get settingsRecordingMicAutoNoDevice => '自动 · 系统默认';

  @override
  String get settingsRecordingMicAutoShort => '自动';

  @override
  String get settingsRecordingMicEmpty => '未检测到麦克风';

  @override
  String get settingsRecordingMicAutoOption => '自动（跳过虚拟麦克风）';

  @override
  String get settingsRecordingMicDialogTitle => '选择麦克风';

  @override
  String get shadowRecordingSilentWarning => '未检测到麦克风信号。请打开「设置 → 录音」选择其他麦克风。';

  @override
  String get shadowRecordingPlaybackFailed => '无法播放此条录音。';

  @override
  String shadowRecordingOverTarget(String seconds) {
    return '超出目标 +$seconds 秒';
  }

  @override
  String shadowRecordingElapsedSemantics(String elapsed, String target) {
    return '已录制 $elapsed 秒，目标 $target 秒';
  }

  @override
  String shadowRecordingElapsedCountdown(String elapsed, String target) {
    return '$elapsed 秒 / $target 秒';
  }

  @override
  String shadowRecordingElapsedSeconds(String elapsed) {
    return '$elapsed 秒';
  }

  @override
  String get shadowRecordingFileNotFound => '未找到录音文件。';

  @override
  String get hotkeysTitle => '键盘快捷键';

  @override
  String get hotkeysHintFooter => '按 Shift+/（?）打开此列表。';

  @override
  String get hotkeysCustomizedBadge => '已自定义';

  @override
  String get hotkeysSectionKeyboard => '键盘快捷键';

  @override
  String get hotkeysResetAll => '重置全部快捷键';

  @override
  String get hotkeysResetAllConfirmTitle => '重置全部快捷键？';

  @override
  String get hotkeysResetAllConfirmMessage => '所有快捷键将恢复为默认绑定，自定义设置无法撤销。';

  @override
  String get hotkeysCaptureTitle => '按下新快捷键';

  @override
  String get hotkeysCaptureHint => '按下组合键。Esc 取消。';

  @override
  String get hotkeysConflictError => '该快捷键已被使用。';

  @override
  String get hotkeysScopeGlobal => '全局';

  @override
  String get hotkeysScopePlayer => '播放器';

  @override
  String get hotkeysScopeLibrary => '资料库';

  @override
  String get hotkeysScopeModal => '弹窗';

  @override
  String get hotkeysDescHelp => '显示键盘快捷键';

  @override
  String get hotkeysDescSearch => '打开搜索';

  @override
  String get hotkeysDescSettings => '打开设置';

  @override
  String get hotkeysDescCraft => '打开 Craft';

  @override
  String get hotkeysDescTogglePlay => '播放 / 暂停';

  @override
  String get hotkeysDescToggleExpand => '切换播放器展开/收起';

  @override
  String get hotkeysDescToggleFullscreen => '切换全屏';

  @override
  String get hotkeysDescSearchTranscript => '搜索字幕 (Ctrl+F)';

  @override
  String get hotkeysDescSeekBack => '快退 3 秒';

  @override
  String get hotkeysDescSeekForward => '快进 3 秒';

  @override
  String get hotkeysDescVolumeUp => '增大音量';

  @override
  String get hotkeysDescVolumeDown => '减小音量';

  @override
  String get hotkeysDescToggleMute => '静音切换';

  @override
  String get hotkeysDescPrevLine => '播放上一句';

  @override
  String get hotkeysDescNextLine => '播放下一句';

  @override
  String get hotkeysDescReplayLine => '重播当前句';

  @override
  String get hotkeysDescToggleEchoMode => '切换回声模式';

  @override
  String get hotkeysDescToggleBlurPractice => '听写（隐藏文本）';

  @override
  String get hotkeysDescToggleRecording => '开始/停止录音';

  @override
  String get hotkeysDescToggleAssessment => '显示/隐藏发音评测';

  @override
  String get hotkeysDescTogglePitchContour => '显示/隐藏音高曲线';

  @override
  String get hotkeysDescPlayRecording => '播放/暂停录音';

  @override
  String get hotkeysDescSlowDown => '减慢播放速度';

  @override
  String get hotkeysDescSpeedUp => '加快播放速度';

  @override
  String get hotkeysDescExpandEchoBackward => '把上一行加入循环';

  @override
  String get hotkeysDescExpandEchoForward => '把下一行加入循环';

  @override
  String get hotkeysDescShrinkEchoBackward => '去掉循环的第一行';

  @override
  String get hotkeysDescShrinkEchoForward => '去掉循环的最后一行';

  @override
  String get hotkeysDescLibrarySearch => '聚焦搜索框';

  @override
  String get hotkeysDescCloseModal => '关闭浮层、退出全屏或取消录音';

  @override
  String get assessmentTitle => '发音评测';

  @override
  String get assessmentDescription => '为你的朗读提供详细评分。';

  @override
  String get assessmentRun => '运行发音评测';

  @override
  String get assessmentView => '查看发音评测';

  @override
  String get assessmentReassess => '重新评测';

  @override
  String get assessmentScoring => '打分中…';

  @override
  String get assessmentScoreAction => '评分';

  @override
  String get assessmentOverallScore => '总分';

  @override
  String get assessmentAccuracy => '准确度';

  @override
  String get assessmentCompleteness => '完整度';

  @override
  String get assessmentFluency => '流利度';

  @override
  String get assessmentProsody => '韵律';

  @override
  String get assessmentPronunciationAnalysis => '发音分析';

  @override
  String get assessmentSyllables => '音节';

  @override
  String get assessmentPhonemes => '音素';

  @override
  String get assessmentNoRecording => '录音文件缺失或为空。';

  @override
  String get assessmentNoResultSummary => '此条录音没有可用的详细评分。';

  @override
  String assessmentRunFailed(String reason) {
    return '无法运行评测：$reason';
  }

  @override
  String get assessmentErrorTypeOmission => '遗漏';

  @override
  String get assessmentErrorTypeInsertion => '插入';

  @override
  String get assessmentErrorTypeMispronunciation => '发音错误';

  @override
  String get assessmentErrorTypeUnexpectedBreak => '意外停顿';

  @override
  String get assessmentErrorTypeMissingBreak => '缺少停顿';

  @override
  String get assessmentErrorTypeMonotone => '单调';

  @override
  String get assessmentErrorTypeCorrect => '正确';

  @override
  String get assessmentErrorExplOmission => '预期应有此词但未检测到。';

  @override
  String get assessmentErrorExplInsertion => '检测到参考中不存在的额外词语。';

  @override
  String get assessmentErrorExplMispronunciation => '此词发音可能不正确。';

  @override
  String get assessmentErrorExplUnexpectedBreak => '在此词前检测到意外停顿。';

  @override
  String get assessmentErrorExplMissingBreak => '在此词前未检测到应有的停顿。';

  @override
  String get assessmentErrorExplMonotone => '音高变化低于预期。';

  @override
  String get assessmentErrorExplCorrect => '此词未发现问题。';

  @override
  String get assessmentEmptyReference => '参考文本为空。';

  @override
  String get assessmentInvalidStored => '无法读取已保存的评测数据。';

  @override
  String get authCancel => '取消';

  @override
  String get settingsSectionAppearanceLanguageHint => '主题，以及界面、学习与母语语言';

  @override
  String get hotkeysSectionKeyboardHint => '查看并自定义快捷键';

  @override
  String get settingsSectionDeveloperHint => '诊断与内部工具';

  @override
  String get settingsSectionAboutHint => '版本、许可与链接';

  @override
  String get cloudRefreshTooltip => '刷新此标签页';

  @override
  String get settingsApiBaseUrl => 'API 基础地址';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get homeTodaysGoal => '今日目标';

  @override
  String get homeMinutes => '分钟';

  @override
  String get homeGoalCompleted => '目标完成！太棒了！';

  @override
  String get homeGoalAlmostThere => '快完成了！继续加油！';

  @override
  String get homeGoalHalfway => '已经完成一半！你可以的！';

  @override
  String get homeGoalGoodStart => '不错的开始！坚持练习！';

  @override
  String get homeGoalJustStarted => '刚刚开始！每一分钟都很重要！';

  @override
  String get homeGoalStartNow => '现在开始练习吧！';

  @override
  String get mediaLocateTitle => '定位媒体文件';

  @override
  String get mediaLocateBody => '此项目在其他设备上添加。请在本机选择同一文件，我们会通过安全指纹校验是否与资料库匹配。';

  @override
  String get mediaLocateChooseFile => '选择文件';

  @override
  String get mediaLocateHashMismatch => '该文件与此项目不匹配。请确认选择了正确文件。';

  @override
  String mediaLocateExpectedSize(String sizeLabel) {
    return '预期大小：$sizeLabel';
  }

  @override
  String get mediaLocateSizeUnknown => '预期大小：未知';

  @override
  String get libraryDeleteMediaTitle => '从资料库删除？';

  @override
  String libraryDeleteMediaMessage(String title) {
    return '将从本机移除「$title」，此操作不可撤销。';
  }

  @override
  String get libraryDeleteMediaTooltip => '从资料库删除';

  @override
  String get libraryMediaDeleted => '已从资料库移除。';

  @override
  String get cloudSyncBadgeSynced => '已同步至云端';

  @override
  String get cloudSyncBadgePending => '等待同步';

  @override
  String get cloudSyncBadgeLocalOnly => '仅本机';

  @override
  String get settingsSectionDeveloper => '开发者';

  @override
  String get settingsAiPlaygroundTileTitle => 'AI 试验台';

  @override
  String get settingsAiPlaygroundTileSubtitle => '调用 ASR、聊天、翻译与词典 API';

  @override
  String get aiPlaygroundTitle => 'AI 试验台';

  @override
  String get aiPlaygroundIntro =>
      '使用已保存的基础地址与访问令牌调用 Enjoy API。Flutter 上尚未接入 TTS；登录后发音评测通过原生插件使用 Azure Speech。';

  @override
  String get aiPlaygroundPickAudio => '选择音频文件';

  @override
  String get aiPlaygroundTranscribe => '转写';

  @override
  String get aiPlaygroundChatSystem => '系统（可选）';

  @override
  String get aiPlaygroundChatUser => '用户消息';

  @override
  String get aiPlaygroundSendChat => '发送聊天';

  @override
  String get aiPlaygroundTranslateSource => '源语言';

  @override
  String get aiPlaygroundTranslateTarget => '目标语言';

  @override
  String get aiPlaygroundTranslateText => '待翻译文本';

  @override
  String get aiPlaygroundTranslate => '翻译';

  @override
  String get aiPlaygroundDictWord => '单词';

  @override
  String get aiPlaygroundDictSource => '源语言';

  @override
  String get aiPlaygroundDictTarget => '目标语言';

  @override
  String get aiPlaygroundDictLookup => '词典查询';

  @override
  String get aiPlaygroundAssessmentReference => '参考文本（你所说的内容）';

  @override
  String get aiPlaygroundAssessmentLanguage => '语言（如 en、en-US）';

  @override
  String get aiPlaygroundAssess => '运行发音评测';

  @override
  String get aiPlaygroundAssessmentTtsNote =>
      '本版本暂不提供 TTS（Azure Speech 集成进行中）。';

  @override
  String get aiPlaygroundOutput => '输出';

  @override
  String get aiPlaygroundClearOutput => '清空输出';

  @override
  String get aiPlaygroundSectionAsr => '语音识别';

  @override
  String get aiPlaygroundSectionChat => '聊天';

  @override
  String get aiPlaygroundSectionTranslation => '翻译';

  @override
  String get aiPlaygroundSectionDictionary => '词典';

  @override
  String get aiPlaygroundSectionTtsAssessment => 'TTS / 评测';

  @override
  String get youtubePasteFromClipboard => '粘贴';

  @override
  String get settingsSectionAppearanceLanguage => '外观与语言';

  @override
  String get settingsAppearanceTheme => '主题';

  @override
  String get settingsAppearanceThemeSystem => '跟随系统';

  @override
  String get settingsAppearanceThemeLight => '浅色';

  @override
  String get settingsAppearanceThemeDark => '深色';

  @override
  String get settingsAppearanceDisplayLanguage => '显示语言';

  @override
  String get settingsAppearanceLearningLanguage => '学习语言';

  @override
  String get settingsAppearanceNativeLanguage => '母语';

  @override
  String get settingsLanguageSubtitleDeviceOnly => '保存在本机，登录账号后可同步。';

  @override
  String get settingsNativeLanguageGateSubtitle => '当前学习语言下只有一种母语可选。';

  @override
  String get settingsLanguageOptionEnUs => '英语（美国）';

  @override
  String get settingsLanguageOptionEnGb => '英语（英国）';

  @override
  String get settingsLanguageOptionJaJp => '日语';

  @override
  String get settingsLanguageOptionKoKr => '韩语';

  @override
  String get settingsLanguageOptionEsEs => '西班牙语（西班牙）';

  @override
  String get settingsLanguageOptionEsMx => '西班牙语（墨西哥）';

  @override
  String get settingsLanguageOptionFrFr => '法语（法国）';

  @override
  String get settingsLanguageOptionFrCa => '法语（加拿大）';

  @override
  String get settingsLanguageOptionZhCn => '中文（简体）';

  @override
  String get settingsLanguageOptionNbNo => '挪威语（书面语）';

  @override
  String get settingsLearningLanguageSubtitle => '用于发现页推荐及导入时的默认语言。';

  @override
  String get settingsLanguagePickerTitleLearning => '学习语言';

  @override
  String get mediaLanguageUnknown => '未知';

  @override
  String get mediaLanguagePickerTitle => '内容语言';

  @override
  String get mediaEditLanguage => '编辑语言';

  @override
  String get mediaLanguageUpdated => '语言已更新。';

  @override
  String get mediaLanguageUpdateFailed => '无法更新语言。';

  @override
  String get mediaEditDetails => '编辑详情';

  @override
  String get mediaDetailsTitleLabel => '标题';

  @override
  String get mediaDetailsSave => '保存';

  @override
  String get mediaDetailsUpdated => '详情已更新。';

  @override
  String get mediaDetailsUpdateFailed => '无法更新详情。';

  @override
  String get mediaDetailsMissing => '该项目已不在资料库中。';

  @override
  String get assessmentUnavailableLanguage => '该语言暂不支持发音评估。';

  @override
  String get discoverLanguageFilterAll => '全部语言';

  @override
  String get discoverLanguageFilterLabel => '语言';

  @override
  String get settingsLanguagePickerTitleDisplay => '显示语言';

  @override
  String get settingsLanguagePickerTitleNative => '母语';

  @override
  String get settingsKeyboardOpenCheatsheet => '打开快捷键速查';

  @override
  String get settingsKeyboardOpenCheatsheetSubtitle => '浏览并自定义所有快捷键';

  @override
  String get settingsKeyboardCustomizeTitle => '自定义快捷键';

  @override
  String get hotkeysHelpSearchHint => '搜索快捷键';

  @override
  String get hotkeysHelpEmpty => '无匹配的快捷键';

  @override
  String get hotkeysHelpCustomize => '自定义快捷键';

  @override
  String hotkeysSettingsSubtitle(String key) {
    return '点按一行即可修改。随时按 $key。';
  }

  @override
  String get hotkeysFilterHint => '筛选快捷键';

  @override
  String get hotkeysResetTooltip => '重置此快捷键';

  @override
  String get hotkeysEditTooltip => '更改快捷键';

  @override
  String get settingsAboutMadeWithCare => '为语言学习者用心打造。';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version';
  }

  @override
  String get settingsAboutOpenSourceTitle => '开源项目';

  @override
  String get settingsAboutOpenSourceSubtitle => '在 GitHub 查看源代码';

  @override
  String get settingsDiagnosticsLoggingTitle => '诊断日志';

  @override
  String get settingsDiagnosticsLoggingSubtitle => '为 YouTube、同步和登录问题记录更多细节';

  @override
  String get settingsDiagnosticsPrivacyNote =>
      '日志保存在本设备，导出前不会上传。令牌和 Cookie 会被脱敏。';

  @override
  String get settingsDiagnosticsExportTitle => '导出诊断报告';

  @override
  String get settingsDiagnosticsExportSubtitle => '保存近期日志压缩包以便反馈问题';

  @override
  String get settingsDiagnosticsExportSuccess => '诊断报告已保存。';

  @override
  String get settingsDiagnosticsExportError => '无法导出诊断报告。';

  @override
  String get settingsCheckForUpdatesTitle => '检查更新';

  @override
  String get settingsCheckForUpdatesSubtitle => '查看是否有新的直接下载版本';

  @override
  String get updateAvailableTitle => '有可用更新';

  @override
  String get updateAvailableBadgeSemantics => '有可用更新';

  @override
  String get updateMandatoryTitle => '需要更新';

  @override
  String updateVersionLine(String current, String latest) {
    return '已安装 $current → $latest';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍后';

  @override
  String get updateDismiss => '忽略';

  @override
  String get updateCancel => '取消';

  @override
  String get updateRetry => '重试';

  @override
  String get updatePreparing => '正在准备下载…';

  @override
  String updateDownloading(int percent) {
    return '正在下载更新… $percent%';
  }

  @override
  String get updateVerifying => '正在校验下载…';

  @override
  String get updateOpeningInstaller => '正在打开安装程序…';

  @override
  String get updateErrorDownload => '下载失败。请检查网络后重试。';

  @override
  String get updateErrorChecksum => '下载文件已损坏，请重试。';

  @override
  String get updateErrorPermission => '未授予安装权限。请在系统设置中允许从此应用安装，然后重试。';

  @override
  String get updateErrorAlreadyRunning => '已有更新正在下载。';

  @override
  String get updateErrorInstallation => '无法打开安装程序，请重试。';

  @override
  String get updateErrorGeneric => '更新失败，请重试。';

  @override
  String get updateUpToDate => '已是最新版本。';

  @override
  String get updateCheckOffline => '无法检查更新，请检查网络连接。';

  @override
  String get updateStoreChannelHint => '此版本来自 TestFlight 或 Play 商店，更新由商店处理。';

  @override
  String get lookupSheetTitle => '查词';

  @override
  String get lookupSectionTranslation => '翻译';

  @override
  String get lookupSectionContextualTranslation => '语境翻译';

  @override
  String get lookupSectionDictionary => '释义';

  @override
  String get lookupErrorRetry => '重试';

  @override
  String get lookupEmpty => '暂无结果。';

  @override
  String get lookupLemma => '词干';

  @override
  String get lookupClose => '关闭';

  @override
  String get lookupCopy => '复制';

  @override
  String get lookupCopySuccess => '已复制到剪贴板';

  @override
  String get lookupTapToExpand => '展开以加载';

  @override
  String get lookupSourceLanguage => '原文语言';

  @override
  String get lookupTargetLanguage => '目标语言';

  @override
  String get lookupSwapLanguages => '交换语言';

  @override
  String get lookupPickSourceTitle => '选择原文语言';

  @override
  String get lookupPickTargetTitle => '选择目标语言';

  @override
  String get lookupRefresh => '刷新';

  @override
  String get lookupSourceResetToLearning => '源语言已重置为学习语言默认值';

  @override
  String get vocabularyAddToVocabulary => '加入生词本';

  @override
  String get vocabularyAddContext => '添加语境';

  @override
  String get vocabularyAlreadyInVocabulary => '已在生词本';

  @override
  String get vocabularyAdding => '添加中…';

  @override
  String get vocabularyRemoving => '删除中…';

  @override
  String get vocabularyConfirmDeleteTitle => '从生词本移除？';

  @override
  String get vocabularyConfirmDeleteBody => '将删除该词及其全部语境。';

  @override
  String get vocabularyCancel => '取消';

  @override
  String get vocabularyDelete => '删除';

  @override
  String get vocabularyTitle => '生词本';

  @override
  String get vocabularyReview => '复习';

  @override
  String get vocabularyAllWords => '全部单词';

  @override
  String get vocabularyDue => '待复习';

  @override
  String get vocabularyStatusNew => '新词';

  @override
  String get vocabularyStatusLearning => '学习中';

  @override
  String get vocabularyStatusReviewing => '复习中';

  @override
  String get vocabularyStatusMastered => '已掌握';

  @override
  String get vocabularyNoWords => '还没有单词';

  @override
  String get vocabularyNoWordsDescription => '在字幕中选中文本，选择「加入生词本」即可开始。';

  @override
  String get vocabularyNoDueItems => '当前没有待复习';

  @override
  String get vocabularyNoDueItemsDescription => '你仍可自定义复习：全部、按状态、按语言或随机抽取。';

  @override
  String get vocabularyNoMatches => '没有匹配的单词';

  @override
  String get vocabularyNoMatchesDescription => '试试其他关键词，或清除状态与语言筛选。';

  @override
  String get vocabularyCustomReview => '自定义复习';

  @override
  String get vocabularySelectReviewItems => '选择复习范围';

  @override
  String get vocabularyReviewDueItems => '待复习';

  @override
  String get vocabularyReviewDueHint => '今天或更早到期的单词';

  @override
  String get vocabularyReviewAll => '全部单词';

  @override
  String get vocabularyReviewAllHint => '复习生词本中的全部单词';

  @override
  String get vocabularyReviewByStatus => '按状态';

  @override
  String get vocabularyReviewByStatusHint => '聚焦新词、学习中、复习中或已掌握';

  @override
  String get vocabularyReviewByLanguage => '按语言';

  @override
  String get vocabularyReviewByLanguageHint => '按来源语言筛选本次复习';

  @override
  String get vocabularyReviewRandom => '随机';

  @override
  String get vocabularyReviewRandomHint => '随机抽取一组进行练习';

  @override
  String get vocabularyNumberOfWords => '单词数量';

  @override
  String vocabularyQueueCount(int count) {
    return '$count 个单词';
  }

  @override
  String get vocabularyStartReview => '开始复习';

  @override
  String get vocabularyEmptyQueue => '没有符合条件的单词。';

  @override
  String get vocabularyExitReview => '退出复习';

  @override
  String get vocabularyDontKnow => '不会';

  @override
  String get vocabularyKnow => '会';

  @override
  String get vocabularyKnowWell => '很熟';

  @override
  String get vocabularySkip => '跳过';

  @override
  String get vocabularyUndo => '撤销';

  @override
  String vocabularyProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get vocabularyReviewComplete => '复习完成';

  @override
  String get vocabularyReviewCompleteDescription => '做得好，评分已保存。';

  @override
  String get vocabularyDone => '完成';

  @override
  String get vocabularySearchPlaceholder => '搜索单词';

  @override
  String get vocabularyFilterStatus => '状态';

  @override
  String get vocabularyFilterLanguage => '语言';

  @override
  String get vocabularyFilterAll => '全部';

  @override
  String get vocabularyContext => '语境';

  @override
  String get vocabularyDictionary => '词典';

  @override
  String get vocabularyNoContextAvailable => '暂无语境';

  @override
  String get vocabularyDictionaryNotAvailable => '离线时无法显示词典';

  @override
  String get vocabularyOverdue => '已过期';

  @override
  String get vocabularyToday => '今天';

  @override
  String get vocabularyTomorrow => '明天';

  @override
  String vocabularyInDays(int days) {
    return '$days 天后';
  }

  @override
  String get vocabularyFlipHint => '点击翻转';

  @override
  String get vocabularyPronounce => '发音';

  @override
  String get vocabularyFlipHintShortcuts => '空格翻转 · 1 / 2 / 3 评分';

  @override
  String get vocabularyPlaySegment => '播放片段';

  @override
  String get vocabularyOpenInPlayer => '在播放器中打开';

  @override
  String get vocabularyOpenInPlayerDescription => '打开播放器将结束本次复习，已保存的评分不会丢失。';

  @override
  String get vocabularyEchoReading => '回声跟读';

  @override
  String get vocabularyPracticeDismiss => '关闭练习';

  @override
  String get vocabularyPracticePause => '暂停';

  @override
  String get vocabularyPreviousContext => '上一个语境';

  @override
  String get vocabularyNextContext => '下一个语境';

  @override
  String vocabularyContextOfTotal(int current, int total) {
    return '第 $current / $total 个';
  }

  @override
  String get vocabularyContextualTranslation => '语境翻译';

  @override
  String get vocabularyFetchDictionary => '查询词典';

  @override
  String get vocabularyFetchContextual => '翻译语境';

  @override
  String get vocabularyFetching => '加载中…';

  @override
  String get vocabularyAiFetchFailed => '加载失败，请联网后重试。';

  @override
  String get vocabularyMediaUnavailable => '此语境不支持媒体操作';

  @override
  String get vocabularyMediaPlayFailed => '无法播放该片段';

  @override
  String get vocabularyMediaOpenFailed => '无法打开该媒体';

  @override
  String get vocabularyConfirmContinue => '继续';

  @override
  String get vocabularyUnknownSource => '未知来源';

  @override
  String vocabularyLocatorLabel(String start, String duration) {
    return '$start秒 · $duration秒';
  }

  @override
  String get vocabularyExportToAnki => '导出到 Anki';

  @override
  String get vocabularyExport => '导出';

  @override
  String get practicePosterShareTooltip => '分享练习海报';

  @override
  String get practicePosterPreviewTitle => '分享你的练习';

  @override
  String get practicePosterTagline => '跟读练习';

  @override
  String get practicePosterStatTakes => '录音';

  @override
  String get practicePosterStatSentences => '句子';

  @override
  String get practicePosterStatSpoken => '开口';

  @override
  String get practicePosterQrHint => '扫码下载 SP Player\nplayer.enjoy.bot';

  @override
  String get practicePosterShareAction => '分享海报';

  @override
  String get practicePosterShareLabel => '分享';

  @override
  String get practicePosterShareSuccess => '海报已分享。';

  @override
  String get practicePosterSaveSuccess => '海报已保存。';

  @override
  String get practicePosterExportError => '无法分享练习海报。';

  @override
  String get practicePosterLoadError => '无法加载此视频的练习数据。';

  @override
  String get notFoundTitle => '页面未找到';

  @override
  String notFoundSubtitle(String uri) {
    return '找不到 $uri。';
  }

  @override
  String get notFoundBackHome => '返回首页';

  @override
  String get recoveryTitle => '本地数据需要处理';

  @override
  String get recoverySubtitle =>
      'SP Player 无法打开本地数据库，最常见的原因是更新不完整。数据仍在磁盘上；继续操作前可先复制错误信息。';

  @override
  String get recoveryOpenLogs => '打开日志文件夹';

  @override
  String get recoveryOpenLogsError => '无法打开日志文件夹。';

  @override
  String get recoveryCopyError => '复制错误';

  @override
  String get recoveryCopiedToClipboard => '错误详情已复制到剪贴板。';

  @override
  String get recoveryResetLibrary => '重置本地资料库';

  @override
  String get recoveryResetLibrarySubtitle =>
      '清除本地数据库并重新开始。云端资料库不受影响。清除前会将当前状态备份到应用支持目录。';

  @override
  String get recoveryResetLibraryConfirmTitle => '重置本地资料库?';

  @override
  String get recoveryResetLibraryConfirmBody =>
      '这将永久删除你的本地资料库、录音、转写和同步队列。若已登录，云端资料库会保留。清除前会先在应用支持目录写入一份备份。';

  @override
  String get recoveryResetLibraryConfirmAction => '全部清除';

  @override
  String get recoveryResetLibraryBackupError => '备份失败，本地数据库未被清除。错误已记录。';

  @override
  String get recoveryResetLibrarySuccess => '本地资料库已重置，正在重新加载数据……';

  @override
  String get recoveryResetLibraryError => '无法重置本地资料库。';

  @override
  String get widgetErrorTitle => '出了点问题';

  @override
  String get widgetErrorSubtitle => '此界面遇到意外错误。你可以复制下面的详情，然后尝试前往其他页面。';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsSearchNoResultsTitle => '没有匹配的设置';

  @override
  String get settingsSearchNoResultsHint => '换个关键词试试，或清除搜索以浏览全部设置。';

  @override
  String get settingsSearchClear => '清除搜索';

  @override
  String get settingsSectionNeedsAttention => '需要注意';

  @override
  String get transcriptBlurDisplayTitle => '隐藏字幕文本';

  @override
  String get importCraftFromText => 'Craft…';

  @override
  String get homeCraftAction => 'Craft';

  @override
  String get craftHistoryTooltip => '历史';

  @override
  String get craftHistoryTitle => 'Craft 历史';

  @override
  String get craftHistoryEmptyTitle => '还没有 Craft';

  @override
  String get craftHistoryEmptyHint => '在 Craft 里创建音频后会显示在这里。';

  @override
  String get craftHistoryEmptyAction => '开始创建';

  @override
  String get craftHistoryRemoveTooltip => '移除 Craft 记录';

  @override
  String get craftHistoryRemoveTitle => '移除 Craft 记录？';

  @override
  String craftHistoryRemoveMessage(String title) {
    return '移除「$title」的 Craft 记录。练习音频仍保留在资料库中。';
  }

  @override
  String get craftHistoryRemoveConfirm => '移除';

  @override
  String get craftHistoryRemoved => '已移除 Craft 记录';

  @override
  String get craftHistoryRemoveFailed => '无法移除此 Craft 记录。';

  @override
  String get craftEditUnavailable => '该 Craft 已不存在。';

  @override
  String get craftSourceLanguageLabel => '原文语言';

  @override
  String get craftTargetLanguageLabel => '学习语言';

  @override
  String get craftTextInputHint => '粘贴或输入文本…';

  @override
  String get craftPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get craftCraftingProgress => '正在合成音频…';

  @override
  String get craftSameLanguageHint => '这段文字已经是学习语言了。';

  @override
  String get craftOfflineBanner => '当前离线，合成需要联网';

  @override
  String get craftSignInRequired => '请登录后使用合成';

  @override
  String get craftSignInCta => '登录';

  @override
  String get craftFailureTts => '无法将文本转为语音。请检查 TTS 提供商设置或重试。';

  @override
  String get craftFailureTranslate => '无法翻译文本。请重试或切换到直接朗读。';

  @override
  String get craftFailureSave => '音频已生成但保存失败。请释放空间后重试。';

  @override
  String get craftRetry => '重试';

  @override
  String get craftOpenAiSettings => '打开 AI 设置';

  @override
  String get libraryProviderCraftBadge => 'Craft';

  @override
  String get craftScreenTitle => 'Craft';

  @override
  String get craftOverline => '用你自己的话生成练习音频';

  @override
  String get craftTranslateTool => '翻译';

  @override
  String get craftSynthesizeTool => '合成';

  @override
  String get craftStyleLabel => '风格';

  @override
  String get craftStyleLiteral => '直译';

  @override
  String get craftStyleNatural => '自然';

  @override
  String get craftStyleCasual => '口语';

  @override
  String get craftStyleFormal => '正式';

  @override
  String get craftStyleSimplified => '简明';

  @override
  String get craftStyleDetailed => '详尽';

  @override
  String get craftStyleCustom => '自定义';

  @override
  String get craftCustomPromptHint => '输入自定义翻译提示…';

  @override
  String get craftSwapLanguages => '交换语言';

  @override
  String get craftTranslateButton => '翻译';

  @override
  String get craftReTranslateButton => '重新翻译';

  @override
  String get craftCopyTranslation => '复制';

  @override
  String get craftCopiedToClipboard => '已复制到剪贴板';

  @override
  String get craftTranslatedText => '翻译结果';

  @override
  String get craftUseTranslatedText => '用于合成';

  @override
  String get craftVoiceLabel => '语音';

  @override
  String get craftNoVoicesForLanguage => '该语言暂无可用语音。';

  @override
  String get craftSynthesizeButton => '合成';

  @override
  String get craftReSynthesizeButton => '重新合成';

  @override
  String get craftSaveToLibrary => '保存到资料库';

  @override
  String get craftPreviewLabel => '预览';

  @override
  String get craftSourceText => '原文';

  @override
  String get craftSynthText => '合成文本';

  @override
  String get craftSolidTranscriptSttHint => '如果练习行时间轴不准确，可在字幕面板用语音识别重新生成。';

  @override
  String get errorGenericLoadFailed => '加载失败，请重试。';

  @override
  String get subscriptionViewPlansAndPackages => '查看方案与积分包';

  @override
  String get byokProviderBillingMessage => '你的 AI 服务商拒绝了本次请求。请检查该服务商的账单或套餐。';

  @override
  String get pronouncePlay => '播放发音';

  @override
  String get pronounceStop => '停止发音';

  @override
  String get pronounceLoading => '正在加载发音…';

  @override
  String get pronounceUnavailableLanguage => '暂不支持此语言的发音';

  @override
  String get pronounceTextTooLong => '文本过长，无法发音';

  @override
  String get pronounceFailed => '无法播放发音';

  @override
  String get assessmentPlayMyRecording => '播放我的录音';

  @override
  String get assessmentStopMyRecording => '停止我的录音';

  @override
  String get assessmentRecordingUnavailable => '录音文件不可用';

  @override
  String get assessmentPlayMyClip => '播放该词的录音片段';

  @override
  String get assessmentStopMyClip => '停止该词的录音片段';

  @override
  String get assessmentClipUnavailable => '该词没有可用的录音片段';

  @override
  String get onboardingTipSkip => '跳过';

  @override
  String get onboardingTipHomeImportTitle => '导入媒体';

  @override
  String get onboardingTipHomeImportBody => '导入本地文件或 YouTube 视频，开始跟读练习。';

  @override
  String get onboardingTipHomeCraftTitle => 'Craft';

  @override
  String get onboardingTipHomeCraftBody => '还没有视频时，可以用文字生成练习音频。';

  @override
  String get onboardingTipEmptyTranscriptLocalTitle => '添加字幕';

  @override
  String get onboardingTipEmptyTranscriptLocalBody => '从文件提取字幕，或导入字幕文件，即可按句练习。';

  @override
  String get onboardingTipEmptyTranscriptYoutubeTitle => '获取字幕';

  @override
  String get onboardingTipEmptyTranscriptYoutubeBody =>
      '从云端拉取此 YouTube 视频的字幕，解锁练习功能。';

  @override
  String get onboardingTipEchoTitle => 'Echo 跟读';

  @override
  String get onboardingTipEchoBody => '打开 Echo，即可逐句跟读并对照原音练习。';

  @override
  String get onboardingTipRecordTitle => '录下你的声音';

  @override
  String get onboardingTipRecordBody => '在句子上录音，再与原音对比。';

  @override
  String get onboardingTipAssessTitle => '发音评估';

  @override
  String get onboardingTipAssessBody => '录音后可查看该条发音反馈。';

  @override
  String get settingsResetProductTipsTitle => '重置产品提示';

  @override
  String get settingsResetProductTipsSubtitle => '重新显示首页与播放器的新手提示。';

  @override
  String get settingsResetProductTipsConfirmTitle => '重置产品提示？';

  @override
  String get settingsResetProductTipsConfirmBody =>
      'Craft、导入、字幕与练习相关提示会再次出现。媒体库与账号不受影响。';

  @override
  String get settingsResetProductTipsConfirmAction => '重置提示';

  @override
  String get settingsResetProductTipsDone => '已重置产品提示';

  @override
  String get settingsAnalyticsCaptureTitle => '使用数据分析';

  @override
  String get settingsAnalyticsCaptureSubtitle =>
      '分享匿名使用数据，帮助改进 Enjoy。绝不包含你的媒体、字幕或笔记。';

  @override
  String get transcriptEmptyFetchYoutube => '获取字幕';

  @override
  String homeGoalOfMinutes(int minutes) {
    return '共 $minutes 分钟';
  }

  @override
  String homeGoalProgressRemaining(int done, int goal, int left) {
    return '$done / $goal 分钟 · 还差 $left 分钟';
  }

  @override
  String homeGoalProgressDone(int done, int goal) {
    return '$done / $goal 分钟';
  }

  @override
  String get homeContinueAction => '继续';

  @override
  String get homeOpenLibrary => '打开媒体库';

  @override
  String homeContinueLine(int line, int total) {
    return '第 $line/$total 行';
  }

  @override
  String get homeContinueEchoOn => '跟读中';

  @override
  String get mediaRelativeToday => '今天';

  @override
  String get mediaRelativeYesterday => '昨天';

  @override
  String libraryTileAdded(String date) {
    return '添加于 $date';
  }

  @override
  String get vocabularyOverline => '我的单词本';

  @override
  String vocabularyReviewDueAction(int count) {
    return '复习 $count 个到期单词';
  }

  @override
  String get vocabularyDueToday => '今天到期';

  @override
  String vocabularyDueEstimate(int minutes) {
    return '今天及之前到期的单词 · 约 $minutes 分钟';
  }

  @override
  String get vocabularyByStatus => '按状态';

  @override
  String vocabularyDueWaiting(int count) {
    return '$count 个单词等你复习';
  }

  @override
  String get vocabularyDueReviewBody => '今天及之前到期的单词。空格翻卡，1、2、3 评分。';

  @override
  String vocabularyFilterValue(String label, String value) {
    return '$label：$value';
  }

  @override
  String get vocabularyFewer => '减少';

  @override
  String get vocabularyMore => '增加';

  @override
  String get libraryOverlineLocal => '本设备';

  @override
  String get libraryOverlineCloud => '保存在你的 Enjoy 账户';

  @override
  String librarySearchResults(int count, String query) {
    return '“$query” 有 $count 个结果';
  }

  @override
  String get discoverOverline => '你订阅的 YouTube 频道';

  @override
  String get discoverRecentUploads => '最新上传';

  @override
  String discoverUpdatedAgo(String age) {
    return '更新于 $age';
  }

  @override
  String discoverHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String discoverDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String discoverMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String get discoverJustNow => '刚刚';

  @override
  String get discoverAddToLibraryAction => '加入媒体库';

  @override
  String get discoverStripSubscribe => '订阅';

  @override
  String get playerEchoShort => '回声';

  @override
  String playerLineOfTotal(Object line, Object total) {
    return '第 $line/$total 行';
  }

  @override
  String get assessmentMarginOverline => '发音评估';

  @override
  String get assessmentLevelExcellent => '优秀';

  @override
  String get assessmentLevelGood => '良好';

  @override
  String get assessmentLevelFair => '一般';

  @override
  String get assessmentLevelPoor => '待提高';

  @override
  String get playerMore => '更多';

  @override
  String get playerMoreDescEditTranscript => '在编辑器中修改当前字幕稿的文字与时间';

  @override
  String get playerMoreDescAddSubtitleFile => '从电脑选择 .srt / .vtt 等字幕文件，导入为新字幕轨';

  @override
  String get playerMoreDescEmbeddedSubtitles =>
      '提取视频文件（MKV/MP4 等）内部自带的字幕轨，无需语音识别';

  @override
  String get playerMoreDescAiTranscript =>
      '用本地语音识别生成或重新生成字幕；老视频重新转写后可享受最新的对轴校准';

  @override
  String get playerMoreDescWordTimings => '为每个词添加精确时间与音标，用于卡拉OK式逐词高亮和跟读练习';

  @override
  String get playerMoreDescRefreshFromCloud =>
      '重新从云端拉取字幕稿（YouTube 官方字幕，或登录后云同步的字幕）';

  @override
  String get playerMoreDescDownloadTranscript => '把当前字幕稿导出为 .srt 字幕文件保存到电脑';

  @override
  String get playerMoreDescEditDetails => '修改这个视频的标题、封面等信息';

  @override
  String get playerMoreDescExportLoopClip => '把当前 Echo 循环片段单独导出为视频片段（有循环激活时可用）';

  @override
  String get playerMoreTranscriptSection => '字幕文本';

  @override
  String get playerMoreAddSubtitleFile => '添加字幕文件…';

  @override
  String get playerMoreUseEmbeddedSubtitles => '使用内嵌字幕…';

  @override
  String get playerMoreCreateAiTranscript => '生成 AI 字幕…';

  @override
  String get playerMoreTranscribeAgain => '重新转写…';

  @override
  String get playerMoreAddWordTimings => '添加逐词时间与音标';

  @override
  String get playerMoreAddIpa => '添加音标（IPA）';

  @override
  String get playerMoreRefreshFromCloud => '从云端刷新';

  @override
  String get playerMoreEditTranscript => '编辑字幕';

  @override
  String get transcriptEditorTitle => '编辑字幕';

  @override
  String get transcriptEditorSave => '保存';

  @override
  String get transcriptEditorSaved => '字幕已更新';

  @override
  String get transcriptEditorSaveFailed => '字幕保存失败，请重试。';

  @override
  String get transcriptEditorInvalidTiming => '开始时间和时长必须是秒数，例如 1.25。';

  @override
  String get transcriptEditorEmpty => '这条媒体没有可编辑的字幕。';

  @override
  String get transcriptEditorNoCues => '这条字幕没有可编辑的台词。';

  @override
  String get transcriptEditorDiscardTitle => '放弃未保存的修改？';

  @override
  String get transcriptEditorDiscardMessage => '你对这条字幕的修改尚未保存。';

  @override
  String get transcriptEditorDiscardConfirm => '放弃';

  @override
  String transcriptEditorLineLabel(int index) {
    return '第 $index 行';
  }

  @override
  String get transcriptEditorFieldStart => '开始（秒）';

  @override
  String get transcriptEditorFieldDuration => '时长（秒）';

  @override
  String get playerMoreDownloadTranscript => '下载字幕稿…';

  @override
  String get playerMoreTranslateAll => '翻译全片';

  @override
  String get fullTranslateBannerCta => '翻译全片';

  @override
  String get fullTranslateBannerContinue => '继续翻译';

  @override
  String fullTranslateBannerRunningTitle(int translated, int total) {
    return '翻译中 $translated / $total 句';
  }

  @override
  String fullTranslateBannerCachedProgress(int translated, int total) {
    return '已缓存 $translated / $total 句';
  }

  @override
  String fullTranslateBannerReachedMinute(int minutes) {
    return '已翻译到视频第 $minutes 分钟';
  }

  @override
  String fullTranslateBannerPausedFailure(int failed) {
    return '有 $failed 句翻译失败，可点「继续翻译」重试';
  }

  @override
  String get fullTranslateBannerPausedStopped => '已停止，可点「继续翻译」接着翻';

  @override
  String get fullTranslateBannerErrorGeneric => '无法开始翻译，请检查字幕与语言设置';

  @override
  String get fullTranslateBannerErrorConfig => '请先在「设置 → AI」配置云端语言模型';

  @override
  String fullTranslateExportIncomplete(int remaining) {
    return '还有 $remaining 句未翻译，请先执行「翻译全片」';
  }

  @override
  String get playerMoreMediaSection => '媒体';

  @override
  String get playerMoreEditDetails => '编辑详情';

  @override
  String get playerMoreExportLoopClip => '将循环导出为片段…';

  @override
  String get playerMoreExportLoopClipSuccess => '循环片段已导出';

  @override
  String get playerMoreExportLoopClipFailed => '无法导出循环片段';

  @override
  String get playerMoreExportLoopClipFfmpegMissing => '此设备上没有可用的 FFmpeg';

  @override
  String get playerMoreKeyboardShortcuts => '键盘快捷键';

  @override
  String get subtitlesPanelTitle => '字幕与显示';

  @override
  String get subtitlesSectionSubtitles => '字幕';

  @override
  String get subtitlesSectionDisplay => '显示';

  @override
  String get transcriptTypefaceLabel => '字幕字体';

  @override
  String get transcriptTypefaceBook => '书本';

  @override
  String get transcriptTypefaceClean => '简洁';

  @override
  String get subtitlesHighlightSpokenWord => '高亮正在朗读的词';

  @override
  String get subtitlesHighlightSpokenWordHint => '朗读到哪个词，就在哪个词下画线。';

  @override
  String get subtitlesIpaUnderWords => '在词下显示音标';

  @override
  String get subtitlesCaptionOverlay => '视频下方字幕';

  @override
  String get subtitlesCaptionOverlayHint => '在视频画面下方显示当前句，背景透明。';

  @override
  String get subtitlesCaptionModeOff => '关闭';

  @override
  String get subtitlesCaptionModeOriginal => '原文';

  @override
  String get subtitlesCaptionModeTranslation => '译文';

  @override
  String get subtitlesCaptionModeBoth => '双语';

  @override
  String get subtitlesIpaUnderWordsHint => '点按单词即可试听。';

  @override
  String get subtitlesNeedsWordTimingsMore => '请先添加逐词时间与音标（··· 更多）。';

  @override
  String get subtitlesNeedsWordTimingsBelow => '请先添加逐词时间与音标（见下方）。';

  @override
  String get subtitlesManageFromMore => '在 ··· 更多 中添加或替换字幕。';

  @override
  String get transcriptEnrichRunningOwned => '正在生成逐词时间与发音';

  @override
  String get transcriptEnrichRunningYoutube => '正在生成发音';

  @override
  String get playerDictateShort => '听写';

  @override
  String get playerDictateHintHover => '听写 · 先听，再把鼠标移到一行上偷看';

  @override
  String get playerDictateHintHold => '长按可显示';

  @override
  String playerDockPractisedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已练习 $count 句',
      zero: '还没有练习过的句子',
    );
    return '$_temp0';
  }

  @override
  String playerDockLoopingLine(int line) {
    return '正在循环第 $line 句';
  }

  @override
  String playerDockLoopingLines(int start, int end) {
    return '正在循环第 $start–$end 句';
  }

  @override
  String playerDockLoopHint(String seconds) {
    return '$seconds 秒 · + 加一句，− 去一句';
  }

  @override
  String playerDockRecordingProgress(String elapsed, String total) {
    return '录音中 · $elapsed 秒 / $total 秒';
  }

  @override
  String playerDockDictatingLine(int line) {
    return '正在听写第 $line 句';
  }

  @override
  String get playerDockDictateHover => '把鼠标移到一行上偷看';

  @override
  String get playerDockDictateHold => '长按可显示';

  @override
  String get playerRepeatOff => '重复：关';

  @override
  String get playerRepeatItem => '重复播放整个内容';

  @override
  String get playerRepeatLoop => '重复播放回声片段';

  @override
  String playerMarginCloseTooltip(String close) {
    return '$close · Esc';
  }

  @override
  String takeNumbered(int number) {
    return '第 $number 遍';
  }

  @override
  String takesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 遍',
    );
    return '$_temp0';
  }

  @override
  String get takeNotScoredClick => '还没有评分 · 点击评分';

  @override
  String get takeNotScoredTap => '还没有评分 · 轻点评分';

  @override
  String get takesMarginTitleClick => '你的录音 · 点击播放';

  @override
  String get takesMarginTitleTap => '你的录音 · 轻点播放';

  @override
  String get takesPitchOnLoop => '在循环上显示音高曲线';

  @override
  String lookupInThisAudio(String time) {
    return '本音频 · $time';
  }

  @override
  String lookupInThisVideo(String time) {
    return '本视频 · $time';
  }

  @override
  String takeAssessmentTitle(int number) {
    return '第 $number 遍 · 评估';
  }

  @override
  String get settingsSectionNetwork => '网络';

  @override
  String get settingsSectionNetworkHint => '代理与 VPN 路由';

  @override
  String get settingsNetworkProxyModeTitle => '代理模式';

  @override
  String get settingsNetworkProxyModeSystem => '系统';

  @override
  String get settingsNetworkProxyModeManual => '手动';

  @override
  String get settingsNetworkProxyModeDirect => '直连';

  @override
  String get settingsNetworkProxyModeHint =>
      '“系统”跟随操作系统代理（Clash、sing-box 等）；“手动”使用下方地址；“直连”不使用任何代理。';

  @override
  String get settingsNetworkProxyUrlLabel => '代理地址';

  @override
  String get settingsNetworkProxyUrlHint => '127.0.0.1:7890 或 http://主机:端口';

  @override
  String get settingsNetworkProxyUrlInvalid =>
      '请输入 host:port 形式的 HTTP 代理，暂不支持 SOCKS 代理。';

  @override
  String get settingsNetworkProxySave => '保存代理';

  @override
  String get settingsNetworkProxySaved => '代理设置已保存。';

  @override
  String get settingsNetworkEffectiveTitle => '当前生效的代理';

  @override
  String get settingsNetworkEffectiveDirect => '直连（无代理）';

  @override
  String settingsNetworkEffectiveProxy(String endpoint, String source) {
    return '$endpoint（$source）';
  }

  @override
  String get settingsNetworkTestButton => '测试连接';

  @override
  String get settingsNetworkTestRunning => '正在测试…';

  @override
  String get settingsNetworkTestYoutube => 'YouTube';

  @override
  String settingsNetworkTestOk(String label, int ms, String route) {
    return '$label：可访问，耗时 $ms 毫秒，路由 $route';
  }

  @override
  String settingsNetworkTestFail(String label, String route, String error) {
    return '$label：失败，路由 $route（$error）';
  }

  @override
  String get settingsSectionLocalComponents => '本地组件';

  @override
  String get settingsSectionLocalComponentsHint => '管理离线识别 / 翻译的模型组件（下载、删除）。';
}
