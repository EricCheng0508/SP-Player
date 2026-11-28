// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SP Player';

  @override
  String get libraryTitle => 'Library';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeRecentMedia => 'Recent media';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeEmptyTitle => 'No recent media';

  @override
  String get homeContinuePracticing => 'Continue practicing';

  @override
  String homeContinueOpenSemantics(String title) {
    return 'Continue practicing, $title';
  }

  @override
  String get homeEmptyHint => 'Import media or drop a file here to start.';

  @override
  String get libraryTabAudio => 'Audio';

  @override
  String get libraryTabVideo => 'Video';

  @override
  String get libraryEmptyAudioTitle => 'We couldn\'t find any audio';

  @override
  String get libraryEmptyAudioHint =>
      'Your library doesn\'t contain any audio content.';

  @override
  String get libraryEmptyVideoTitle => 'We couldn\'t find any videos';

  @override
  String get libraryEmptyVideoHint =>
      'Your library doesn\'t contain any video content.';

  @override
  String get librarySearchNoMatchesTitle => 'No matches';

  @override
  String get librarySearchNoMatchesHint =>
      'Nothing in your library matches this search.';

  @override
  String get librarySearchHint => 'Search library';

  @override
  String get librarySearchClear => 'Clear search';

  @override
  String get libraryDeleteFailed => 'Could not remove this item. Try again.';

  @override
  String get transcriptAccessibilityTranscriptList => 'Transcript';

  @override
  String transcriptAccessibilityCue(String time, String snippet) {
    return '$time. $snippet';
  }

  @override
  String get transcriptAccessibilityCurrentLine => 'Current playback line.';

  @override
  String get transcriptAccessibilityEchoRegion => 'Echo practice region.';

  @override
  String get transcriptAccessibilityEchoCurrentLine => 'Current echo line.';

  @override
  String transcriptLineRecordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings',
      one: '1 recording',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorFriendlyTitle => 'Transcript unavailable';

  @override
  String get transcriptErrorFriendlyHint =>
      'Try choosing another subtitle track or importing a file.';

  @override
  String get transcriptFetchingSubtitles => 'Fetching subtitles…';

  @override
  String get transcriptSearchHint => 'Search transcript';

  @override
  String get transcriptSearchNoMatches => 'No matching lines';

  @override
  String get lookupSectionExplain => 'Explain this sentence';

  @override
  String get libraryTabPlaylists => 'Playlists';

  @override
  String get playlistCreateButton => 'New playlist';

  @override
  String get playlistRename => 'Rename playlist';

  @override
  String get playlistDelete => 'Delete playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get playlistSave => 'Save';

  @override
  String get playlistEmptyTitle => 'No playlists yet';

  @override
  String get playlistEmptyHint =>
      'Create a playlist to group media and play them in order.';

  @override
  String playlistItemCount(int count) {
    return '$count items';
  }

  @override
  String get playlistAddMedia => 'Add media';

  @override
  String get playlistPlayAll => 'Play all';

  @override
  String get playlistRemoveItem => 'Remove from playlist';

  @override
  String get playlistMoveUp => 'Move up';

  @override
  String get playlistMoveDown => 'Move down';

  @override
  String get playlistMissingMedia => 'Media no longer in library';

  @override
  String get playlistPickerNoMedia => 'Import media first, then add it here.';

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
  String get actionImport => 'Import';

  @override
  String get importFromFile => 'From file…';

  @override
  String get importFromYoutube => 'From YouTube URL…';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverBrowseAction => 'Browse Discover';

  @override
  String get discoverRecommendedHeading => 'Recommended';

  @override
  String get discoverSubscribeTitle => 'Subscribe to channel';

  @override
  String get discoverSubscribeHint => 'Paste a YouTube channel URL or @handle.';

  @override
  String get discoverSubscribePlaceholder => 'https://www.youtube.com/@channel';

  @override
  String get discoverSubscribeAction => 'Subscribe';

  @override
  String get discoverSubscribed => 'Subscribed to channel';

  @override
  String get discoverSubscribedLabel => 'Subscribed';

  @override
  String get discoverSubscribeFailed => 'Could not subscribe to that channel.';

  @override
  String get discoverUnsubscribeAction => 'Unsubscribe';

  @override
  String get discoverUnsubscribed => 'Unsubscribed from channel';

  @override
  String get discoverAddToLibrary => 'Add to library';

  @override
  String get discoverAddedToLibrary => 'Added to your library';

  @override
  String get discoverAddFailed => 'Could not add this video.';

  @override
  String get discoverInLibrary => 'In library';

  @override
  String get discoverFeedEmptyTitle => 'No videos in feed yet';

  @override
  String get discoverFeedEmptyHint =>
      'Subscribe to a channel and refresh to load recent uploads.';

  @override
  String get discoverFeedErrorTitle => 'Could not load feed';

  @override
  String get discoverFeedErrorHint => 'Check your connection and try again.';

  @override
  String get discoverRetry => 'Retry';

  @override
  String get discoverRefreshPartialFailed =>
      'Some channel feeds could not be refreshed.';

  @override
  String discoverRefreshPartialFailedDetail(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels',
      one: '1 channel',
    );
    return 'Could not refresh $_temp0: $names';
  }

  @override
  String discoverRefreshSingleFailed(Object name) {
    return 'Could not refresh $name.';
  }

  @override
  String get discoverRecommendedLoadFailed =>
      'Could not load recommended channels.';

  @override
  String get discoverSubscriptionsLoadFailed => 'Could not load subscriptions.';

  @override
  String get discoverNoSubscriptionsHint =>
      'Subscribe to a recommended channel or paste a channel URL.';

  @override
  String get discoverManageChannels => 'Manage channels';

  @override
  String get discoverFilterAll => 'All';

  @override
  String get discoverYourChannelsHeading => 'Your channels';

  @override
  String get discoverRecommendedAllSubscribed =>
      'You are subscribed to all recommended channels.';

  @override
  String get youtubeImportTitle => 'Import YouTube video';

  @override
  String get youtubeImportHint => 'Paste a YouTube link or video ID';

  @override
  String get youtubeImportInvalid => 'Could not read a valid YouTube video ID.';

  @override
  String get youtubeImporting => 'Adding video…';

  @override
  String get youtubeBadge => 'YouTube';

  @override
  String get youtubeLoginTooltip => 'YouTube account';

  @override
  String get youtubeOpenInBrowser => 'Open in browser';

  @override
  String get youtubeLoginClose => 'Close';

  @override
  String get youtubeLoginScreenTitle => 'YouTube sign-in';

  @override
  String get youtubeLogout => 'Sign out (clear cookies)';

  @override
  String get youtubeUnavailableOnDevice =>
      'YouTube is not available on this device.';

  @override
  String get youtubeUnavailableRuntimeMissing =>
      'The YouTube playback runtime is not installed on this device.';

  @override
  String get youtubeUnavailableRuntimeInitFailed =>
      'YouTube playback failed to start on this device.';

  @override
  String get youtubeUnavailableCodecsMissing =>
      'YouTube video codecs are missing on this device. Install the GStreamer plugins (gst-plugins-good, gst-plugins-bad, gst-libav) and restart the app.';

  @override
  String get youtubeUnavailableDisabledByBuild =>
      'YouTube playback is disabled in this build.';

  @override
  String get youtubeTapToPlayHint => 'Tap the video to play';

  @override
  String get youtubeVideoStallRelaunch =>
      'This GPU cannot render YouTube video. Relaunch the app to restore video with software rendering.';

  @override
  String get transportFullscreen => 'Fullscreen';

  @override
  String get transportExitFullscreen => 'Exit fullscreen';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get importMedia => 'Import media';

  @override
  String get importingMedia => 'Importing media…';

  @override
  String get importMediaFailed => 'Could not import this file.';

  @override
  String get importUnsupportedFileType =>
      'This file type isn’t supported. Choose an audio or video file.';

  @override
  String get navMainLabel => 'Primary navigation';

  @override
  String get miniPlayerMediaVideo => 'Video';

  @override
  String get miniPlayerMediaAudio => 'Audio';

  @override
  String get retry => 'Retry';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutSubtitle =>
      'SP Player — local transcripts and shadow reading.';

  @override
  String get settingsThemeDarkLocked => 'Follows your system appearance.';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get previousLine => 'Previous line';

  @override
  String get nextLine => 'Next line';

  @override
  String get replayLine => 'Replay line';

  @override
  String get echoMode => 'Echo mode';

  @override
  String get playerListenModeTitle => 'Listen';

  @override
  String get playerDockHideText => 'Hide text';

  @override
  String playerDockLinePosition(int line, int total) {
    return 'Line $line of $total';
  }

  @override
  String get playerDockLooping => '· looping';

  @override
  String get transcript => 'Transcript';

  @override
  String get playerTranscriptResizeHint =>
      'Drag to resize the transcript panel';

  @override
  String get importSubtitle => 'Import subtitle';

  @override
  String get noTranscript => 'No transcript yet';

  @override
  String get transcriptEmptyOverline => 'Transcript';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get playerOpenGenericError => 'Could not open this item.';

  @override
  String playbackRateTimes(String rate) {
    return '$rate×';
  }

  @override
  String get speed => 'Speed';

  @override
  String get volume => 'Volume';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get subtitlesPrimary => 'Primary';

  @override
  String get subtitlesTranslation => 'Translation (optional)';

  @override
  String get subtitlesNone => 'None';

  @override
  String get subtitlesNotSelected => 'Not selected';

  @override
  String get subtitlesDeleteTrack => 'Delete track';

  @override
  String get importSubtitleSuccess => 'Subtitle imported';

  @override
  String get noTranscriptHint =>
      'Add a subtitle file, extract embedded captions, or create an AI transcript.';

  @override
  String get noTranscriptHintRemote =>
      'Cloud captions load automatically when available. Open the CC menu to refresh.';

  @override
  String get transcriptEmptyExtract => 'Extract';

  @override
  String get transcriptEmptyAlign => 'Align existing subtitles / script';

  @override
  String get transcriptAlignNotInstalled =>
      'Alignment components are not installed — install them in Settings → Local components';

  @override
  String get transcriptAlignPipelinePending =>
      'Alignment components detected — word-level alignment lands in the next component release';

  @override
  String get transcriptEmptyAddSubtitle => 'Add subtitle';

  @override
  String get transcriptEmptyGenerate => 'AI transcript';

  @override
  String get subtitlesImportLanguageTitle => 'Subtitle language';

  @override
  String get subtitlesImportLanguageHint =>
      'BCP-47 code (e.g. en, zh-TW). Use und if unknown.';

  @override
  String get subtitlesImportLanguageFieldLabel => 'Language code';

  @override
  String get subtitlesProviderOfficial => 'Official';

  @override
  String get subtitlesProviderAuto => 'Auto';

  @override
  String get subtitlesProviderAi => 'AI';

  @override
  String get subtitlesProviderUser => 'User';

  @override
  String get subtitlesAutoTranslate => 'Auto translate';

  @override
  String subtitlesAutoTranslateLanguageChip(String language) {
    return 'To $language';
  }

  @override
  String get subtitlesExtractNoTracks =>
      'No embedded subtitle tracks in this file (only video and audio). If you have a separate .srt or .vtt, use Import file.';

  @override
  String subtitlesExtractedCount(int count) {
    return 'Extracted $count subtitle track(s).';
  }

  @override
  String get subtitlesRefreshDone => 'Transcripts updated from cloud.';

  @override
  String get transcriptDownloadDialogTitle => 'Download transcript';

  @override
  String get transcriptDownloadEmpty => 'No transcript to download yet.';

  @override
  String get transcriptDownloadSuccess => 'Transcript downloaded.';

  @override
  String get transcriptDownloadError => 'Could not download the transcript.';

  @override
  String get subtitlesNoPlayableUri =>
      'Could not resolve a playable file for this item.';

  @override
  String get expandEchoBackward => 'Expand echo backward';

  @override
  String get expandEchoForward => 'Expand echo forward';

  @override
  String get shrinkEchoBackward => 'Shrink echo backward';

  @override
  String get shrinkEchoForward => 'Shrink echo forward';

  @override
  String echoLoopCaptionLine(String range, String seconds) {
    return 'LOOP · LINE $range · $seconds S';
  }

  @override
  String echoLoopCaptionLines(String range, String seconds) {
    return 'LOOP · LINES $range · $seconds S';
  }

  @override
  String echoLoopCaptionRecording(int count) {
    return 'RECORDING TAKE $count';
  }

  @override
  String get shadowReadingHint =>
      'Practice speaking along this segment. Record your voice and compare pitch with the reference.';

  @override
  String get pitchContourTitle => 'Pitch contour';

  @override
  String get pitchContourError => 'Could not analyze pitch for this segment.';

  @override
  String get pitchContourWaveform => 'Waveform';

  @override
  String get pitchContourReference => 'Original pitch';

  @override
  String get pitchContourUser => 'Your pitch';

  @override
  String get pitchContourAnalyzing => 'Analyzing pitch…';

  @override
  String get shadowRecordingEmpty => 'No recordings for this segment yet.';

  @override
  String get shadowRecordingTake => 'Take';

  @override
  String get shadowTakesEmptyPrefix =>
      'No recordings for this segment yet. Press';

  @override
  String get shadowTakesEmptySuffix => 'and say it back.';

  @override
  String get shadowRecordingPlay => 'Play';

  @override
  String get shadowRecordingChooseTake => 'Switch take';

  @override
  String get shadowRecordingDelete => 'Delete';

  @override
  String get shadowRecordingDeleteConfirmTitle => 'Delete this take?';

  @override
  String shadowRecordingDeleteConfirmMessage(String takeLabel) {
    return '$takeLabel will be permanently deleted. This cannot be undone.';
  }

  @override
  String get shadowRecordingRecord => 'Record';

  @override
  String get shadowRecordingStop => 'Stop';

  @override
  String get shadowRecordingMicDenied =>
      'Microphone permission is required to record.';

  @override
  String shadowRecordingSaveFailed(String reason) {
    return 'Couldn\'t save recording: $reason';
  }

  @override
  String get settingsSectionAi => 'AI';

  @override
  String get settingsSectionAiHint =>
      'Configure your own API keys per feature; speech recognition and translation use local components by default.';

  @override
  String get settingsAiProvidersTileTitle => 'AI providers';

  @override
  String get settingsAiProvidersTitle => 'AI providers';

  @override
  String get settingsAiProvidersPrivacyNotice =>
      'API keys are stored securely on this device only and are never uploaded to any cloud.';

  @override
  String get settingsAiProvidersEnjoyAi => 'Default';

  @override
  String get settingsAiProvidersByok => 'Your API key';

  @override
  String get settingsAiProvidersModalityLlm => 'Language models';

  @override
  String get settingsAiProvidersModalityAsr => 'Speech recognition (subtitles)';

  @override
  String get settingsAiProvidersModalityTts => 'Text-to-speech';

  @override
  String get settingsAiProvidersModalityAssessment =>
      'Pronunciation assessment';

  @override
  String get settingsAiProvidersLlmSpecLabel => 'Protocol';

  @override
  String get settingsAiProvidersLlmSpecOpenAi => 'OpenAI-compatible';

  @override
  String get settingsAiProvidersLlmSpecAnthropic => 'Anthropic-compatible';

  @override
  String get settingsAiProvidersLlmSpecGoogle => 'Google-compatible';

  @override
  String get settingsAiProvidersPresetsLabel => 'Presets';

  @override
  String get settingsAiProvidersBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiProvidersBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get settingsAiProvidersApiKeyLabel => 'API key';

  @override
  String get settingsAiProvidersApiKeyExistingHint =>
      'Leave blank to keep saved key';

  @override
  String get settingsAiProvidersShowApiKey => 'Show API key';

  @override
  String get settingsAiProvidersHideApiKey => 'Hide API key';

  @override
  String get settingsAiProvidersModelLabel => 'Model';

  @override
  String get settingsAiProvidersFetchModels => 'Fetch models';

  @override
  String get settingsAiProvidersFetchedModelsLabel => 'Fetched models';

  @override
  String get settingsAiProvidersFetchModelsFailed =>
      'Could not fetch models. Check base URL and API key.';

  @override
  String get settingsAiProvidersFetchModelsEmpty =>
      'No models returned from this endpoint.';

  @override
  String get settingsAiProvidersSave => 'Save';

  @override
  String get settingsAiProvidersSaveSuccess => 'AI provider settings saved.';

  @override
  String get settingsAiProvidersRemoveByok => 'Remove';

  @override
  String get settingsAiProvidersRemoveByokTitle => 'Remove the saved key?';

  @override
  String get settingsAiProvidersRemoveByokBody =>
      'This deletes the API key saved on this device.';

  @override
  String get settingsAiProvidersRemoveByokSuccess => 'Saved key removed.';

  @override
  String get settingsAiProvidersCancel => 'Cancel';

  @override
  String get settingsAiProvidersComingSoon =>
      'BYOK configuration for this feature is coming soon.';

  @override
  String get settingsAiProvidersSpeechSubscriptionKeyLabel =>
      'Azure subscription key';

  @override
  String get settingsAiProvidersSpeechRegionLabel => 'Azure region';

  @override
  String get settingsAiProvidersSpeechRegionHint => 'eastus';

  @override
  String get settingsAiProvidersSpeechKindLabel => 'Vendor';

  @override
  String get settingsAiProvidersSpeechKindOpenAi => 'OpenAI Whisper';

  @override
  String get settingsAiProvidersSpeechKindAzure => 'Azure Speech';

  @override
  String get settingsAiProvidersSpeechKindHintOpenAi =>
      'OpenAI-compatible: speech-to-text (generate subtitles, dictation, echo transcription).';

  @override
  String get settingsAiProvidersSpeechKindHintAzure =>
      'Azure Speech: phoneme-level pronunciation diagnosis. Also supports speech-to-text. Without it, take scoring falls back to local assessment.';

  @override
  String get settingsAiProvidersSpeechWhisperModelLabel => 'Whisper model';

  @override
  String get settingsAiProvidersSpeechWhisperModelHint => 'whisper-1';

  @override
  String get settingsAiEngineLocal => 'Local (default)';

  @override
  String get settingsAiEngineCloud => 'Custom cloud';

  @override
  String get settingsAiProvidersSpeechTtsModelLabel => 'TTS model';

  @override
  String get settingsAiProvidersSpeechTtsModelHint => 'tts-1';

  @override
  String get settingsAiProvidersApiKeySavedMask => '••••••••••••';

  @override
  String get settingsAiProvidersApiKeyEdit => 'Edit key';

  @override
  String byokNotConfiguredMessage(String modality) {
    return 'BYOK is selected for $modality, but no API key is saved on this device.';
  }

  @override
  String get byokNotConfiguredOpenSettings =>
      'Open Settings → AI providers to add your key.';

  @override
  String get byokValidationApiKeyRequired => 'API key is required.';

  @override
  String get byokValidationBaseUrlRequired => 'Base URL is required.';

  @override
  String get byokValidationBaseUrlInvalid =>
      'Base URL must be a public HTTPS endpoint.';

  @override
  String get byokValidationModelRequired => 'Model is required.';

  @override
  String get byokValidationRegionRequired => 'Azure region is required.';

  @override
  String get byokValidationApiSpecRequired =>
      'Protocol configuration is incomplete.';

  @override
  String get byokValidationAzureKindRequired =>
      'Assessment BYOK requires Azure Speech.';

  @override
  String get settingsSectionRecording => 'Recording';

  @override
  String get settingsSectionRecordingHint =>
      'Microphone used for shadow-reading takes.';

  @override
  String get settingsTranscriptEnrichmentTitle => 'Enrich Craft word timings';

  @override
  String get settingsTranscriptKaraokeTitle => 'Highlight current word';

  @override
  String get settingsTranscriptIpaOverlayTitle => 'Show pronunciation (IPA)';

  @override
  String get transcriptKaraokeUnavailableRemoteHint =>
      'Karaoke needs word timings from a local file.';

  @override
  String get transcriptEnrichOwnedSubtitle =>
      'Uses this item\'s audio. Playback stays available.';

  @override
  String get transcriptEnrichYoutubeSubtitle =>
      'Karaoke stays unavailable. The video is not downloaded.';

  @override
  String get transcriptEnrichCancel => 'Cancel generation';

  @override
  String get transcriptEnrichRetry => 'Try generating again';

  @override
  String get transcriptEnrichFailed => 'Couldn\'t generate. Tap to try again.';

  @override
  String transcriptEnrichProgress(int completed, int total) {
    return '$completed of $total';
  }

  @override
  String get settingsRecordingMicTitle => 'Microphone';

  @override
  String settingsRecordingMicAuto(String label) {
    return 'Auto · $label';
  }

  @override
  String get settingsRecordingMicAutoNoDevice => 'Auto · system default';

  @override
  String get settingsRecordingMicAutoShort => 'Auto';

  @override
  String get settingsRecordingMicEmpty => 'No microphones detected';

  @override
  String get settingsRecordingMicAutoOption => 'Auto (skip virtual mics)';

  @override
  String get settingsRecordingMicDialogTitle => 'Choose microphone';

  @override
  String get shadowRecordingSilentWarning =>
      'No microphone signal detected. Open Settings → Recording to pick a different microphone.';

  @override
  String get shadowRecordingPlaybackFailed => 'Couldn\'t play this take.';

  @override
  String shadowRecordingOverTarget(String seconds) {
    return '+${seconds}s over target';
  }

  @override
  String shadowRecordingElapsedSemantics(String elapsed, String target) {
    return '$elapsed seconds elapsed of $target seconds target';
  }

  @override
  String shadowRecordingElapsedCountdown(String elapsed, String target) {
    return '$elapsed s / $target s';
  }

  @override
  String shadowRecordingElapsedSeconds(String elapsed) {
    return '$elapsed s';
  }

  @override
  String get shadowRecordingFileNotFound => 'Recording file was not found.';

  @override
  String get hotkeysTitle => 'Keyboard shortcuts';

  @override
  String get hotkeysHintFooter => 'Press Shift+/ (?) to open this list.';

  @override
  String get hotkeysCustomizedBadge => 'Custom';

  @override
  String get hotkeysSectionKeyboard => 'Keyboard shortcuts';

  @override
  String get hotkeysResetAll => 'Reset all shortcuts';

  @override
  String get hotkeysResetAllConfirmTitle => 'Reset all shortcuts?';

  @override
  String get hotkeysResetAllConfirmMessage =>
      'This restores every shortcut to its default binding. Custom bindings cannot be undone.';

  @override
  String get hotkeysCaptureTitle => 'Press new shortcut';

  @override
  String get hotkeysCaptureHint => 'Press a key combination. Escape cancels.';

  @override
  String get hotkeysConflictError => 'That shortcut is already used.';

  @override
  String get hotkeysScopeGlobal => 'Global';

  @override
  String get hotkeysScopePlayer => 'Player';

  @override
  String get hotkeysScopeLibrary => 'Library';

  @override
  String get hotkeysScopeModal => 'Modal';

  @override
  String get hotkeysDescHelp => 'Show keyboard shortcuts';

  @override
  String get hotkeysDescSearch => 'Open search';

  @override
  String get hotkeysDescSettings => 'Open settings';

  @override
  String get hotkeysDescCraft => 'Open Craft';

  @override
  String get hotkeysDescTogglePlay => 'Play / Pause';

  @override
  String get hotkeysDescToggleExpand => 'Toggle player expand/collapse';

  @override
  String get hotkeysDescToggleFullscreen => 'Toggle fullscreen';

  @override
  String get hotkeysDescSearchTranscript => 'Search transcript (Ctrl+F)';

  @override
  String get hotkeysDescSeekBack => 'Seek back 3 seconds';

  @override
  String get hotkeysDescSeekForward => 'Seek forward 3 seconds';

  @override
  String get hotkeysDescVolumeUp => 'Volume up';

  @override
  String get hotkeysDescVolumeDown => 'Volume down';

  @override
  String get hotkeysDescToggleMute => 'Mute / unmute';

  @override
  String get hotkeysDescPrevLine => 'Play previous line';

  @override
  String get hotkeysDescNextLine => 'Play next line';

  @override
  String get hotkeysDescReplayLine => 'Replay current line';

  @override
  String get hotkeysDescToggleEchoMode => 'Toggle Echo mode';

  @override
  String get hotkeysDescToggleBlurPractice => 'Dictate (hide text)';

  @override
  String get hotkeysDescToggleRecording => 'Start/Stop recording';

  @override
  String get hotkeysDescToggleAssessment =>
      'Show/Hide pronunciation assessment';

  @override
  String get hotkeysDescTogglePitchContour => 'Show/Hide pitch contour';

  @override
  String get hotkeysDescPlayRecording => 'Play/Pause recording';

  @override
  String get hotkeysDescSlowDown => 'Slow down playback speed';

  @override
  String get hotkeysDescSpeedUp => 'Speed up playback speed';

  @override
  String get hotkeysDescExpandEchoBackward => 'Add the line above to the loop';

  @override
  String get hotkeysDescExpandEchoForward => 'Add the line below to the loop';

  @override
  String get hotkeysDescShrinkEchoBackward => 'Drop the first line of the loop';

  @override
  String get hotkeysDescShrinkEchoForward => 'Drop the last line of the loop';

  @override
  String get hotkeysDescLibrarySearch => 'Focus search';

  @override
  String get hotkeysDescCloseModal =>
      'Close overlay, exit fullscreen, or cancel recording';

  @override
  String get assessmentTitle => 'Pronunciation assessment';

  @override
  String get assessmentDescription => 'Detailed scoring for your reading.';

  @override
  String get assessmentRun => 'Run pronunciation assessment';

  @override
  String get assessmentView => 'View pronunciation assessment';

  @override
  String get assessmentReassess => 'Re-assess';

  @override
  String get assessmentScoring => 'Scoring…';

  @override
  String get assessmentScoreAction => 'Score';

  @override
  String get assessmentOverallScore => 'Overall score';

  @override
  String get assessmentAccuracy => 'Accuracy';

  @override
  String get assessmentCompleteness => 'Completeness';

  @override
  String get assessmentFluency => 'Fluency';

  @override
  String get assessmentProsody => 'Prosody';

  @override
  String get assessmentPronunciationAnalysis => 'Pronunciation analysis';

  @override
  String get assessmentSyllables => 'Syllables';

  @override
  String get assessmentPhonemes => 'Phonemes';

  @override
  String get assessmentNoRecording => 'Recording file is missing or empty.';

  @override
  String get assessmentNoResultSummary =>
      'No detailed scores are available for this take.';

  @override
  String assessmentRunFailed(String reason) {
    return 'Couldn\'t run assessment: $reason';
  }

  @override
  String get assessmentErrorTypeOmission => 'Omission';

  @override
  String get assessmentErrorTypeInsertion => 'Insertion';

  @override
  String get assessmentErrorTypeMispronunciation => 'Mispronunciation';

  @override
  String get assessmentErrorTypeUnexpectedBreak => 'Unexpected break';

  @override
  String get assessmentErrorTypeMissingBreak => 'Missing break';

  @override
  String get assessmentErrorTypeMonotone => 'Monotone';

  @override
  String get assessmentErrorTypeCorrect => 'Correct';

  @override
  String get assessmentErrorExplOmission =>
      'This word was expected but not detected.';

  @override
  String get assessmentErrorExplInsertion =>
      'Extra word detected that wasn\'t in the reference.';

  @override
  String get assessmentErrorExplMispronunciation =>
      'This word may have been pronounced incorrectly.';

  @override
  String get assessmentErrorExplUnexpectedBreak =>
      'Unexpected pause detected before this word.';

  @override
  String get assessmentErrorExplMissingBreak =>
      'Expected pause was not detected before this word.';

  @override
  String get assessmentErrorExplMonotone =>
      'Pitch variation was lower than expected.';

  @override
  String get assessmentErrorExplCorrect => 'No issues detected for this word.';

  @override
  String get assessmentEmptyReference => 'Reference text is empty.';

  @override
  String get assessmentInvalidStored =>
      'Stored assessment data could not be read.';

  @override
  String get authCancel => 'Cancel';

  @override
  String get subscriptionViewPlans => 'View plans';

  @override
  String get settingsSectionAppearanceLanguageHint =>
      'Theme, and the languages you read, learn, and speak';

  @override
  String get hotkeysSectionKeyboardHint => 'Reference and customize shortcuts';

  @override
  String get settingsSectionDeveloperHint => 'Diagnostics and internal tooling';

  @override
  String get settingsSectionAboutHint => 'Version, licenses, and links';

  @override
  String get cloudRefreshTooltip => 'Refresh this tab';

  @override
  String get settingsApiBaseUrl => 'API base URL';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get homeTodaysGoal => 'Today\'s Goal';

  @override
  String get homeMinutes => 'min';

  @override
  String get homeGoalCompleted => 'Goal completed! Great job!';

  @override
  String get homeGoalAlmostThere => 'Almost there! Keep going!';

  @override
  String get homeGoalHalfway => 'Halfway there! You can do it!';

  @override
  String get homeGoalGoodStart => 'Good start! Keep practicing!';

  @override
  String get homeGoalJustStarted => 'Just started! Every minute counts!';

  @override
  String get homeGoalStartNow => 'Start your practice now!';

  @override
  String get mediaLocateTitle => 'Locate media file';

  @override
  String get mediaLocateBody =>
      'This item was added on another device. Choose the same file on this computer. We verify it matches your library using a secure fingerprint.';

  @override
  String get mediaLocateChooseFile => 'Choose file';

  @override
  String get mediaLocateHashMismatch =>
      'That file does not match this item. Make sure you selected the correct file.';

  @override
  String mediaLocateExpectedSize(String sizeLabel) {
    return 'Expected size: $sizeLabel';
  }

  @override
  String get mediaLocateSizeUnknown => 'Expected size: unknown';

  @override
  String get libraryDeleteMediaTitle => 'Delete from library?';

  @override
  String libraryDeleteMediaMessage(String title) {
    return 'Remove \"$title\" from this device. This cannot be undone.';
  }

  @override
  String get libraryDeleteMediaTooltip => 'Delete from library';

  @override
  String get libraryMediaDeleted => 'Removed from library.';

  @override
  String get cloudSyncBadgeSynced => 'Synced to cloud';

  @override
  String get cloudSyncBadgePending => 'Pending sync';

  @override
  String get cloudSyncBadgeLocalOnly => 'Local only';

  @override
  String get settingsSectionDeveloper => 'Developer';

  @override
  String get settingsAiPlaygroundTileTitle => 'AI playground';

  @override
  String get settingsAiPlaygroundTileSubtitle =>
      'Exercise ASR, chat, translation, and dictionary APIs';

  @override
  String get aiPlaygroundTitle => 'AI playground';

  @override
  String get aiPlaygroundIntro =>
      'Exercise AI modalities with your credentials from Settings → AI providers. Translation and dictionary follow the LLM provider.';

  @override
  String get aiPlaygroundActiveProviders => 'Active providers';

  @override
  String aiPlaygroundProviderByokDetail(String detail) {
    return 'BYOK · $detail';
  }

  @override
  String get aiPlaygroundPickAudio => 'Pick audio file';

  @override
  String get aiPlaygroundTranscribe => 'Transcribe';

  @override
  String get aiPlaygroundChatSystem => 'System (optional)';

  @override
  String get aiPlaygroundChatUser => 'User message';

  @override
  String get aiPlaygroundSendChat => 'Send chat';

  @override
  String get aiPlaygroundTranslateSource => 'Source language';

  @override
  String get aiPlaygroundTranslateTarget => 'Target language';

  @override
  String get aiPlaygroundTranslateText => 'Text to translate';

  @override
  String get aiPlaygroundTranslate => 'Translate';

  @override
  String get aiPlaygroundDictWord => 'Word';

  @override
  String get aiPlaygroundDictSource => 'Source language';

  @override
  String get aiPlaygroundDictTarget => 'Target language';

  @override
  String get aiPlaygroundDictLookup => 'Dictionary lookup';

  @override
  String get aiPlaygroundAssessmentReference =>
      'Reference text (what you spoke)';

  @override
  String get aiPlaygroundAssessmentLanguage => 'Language (e.g. en, en-US)';

  @override
  String get aiPlaygroundAssess => 'Run pronunciation assessment';

  @override
  String get aiPlaygroundAssessmentTtsNote =>
      'TTS is not wired yet; configure TTS BYOK under AI providers for synthesis. Assessment uses the provider shown above.';

  @override
  String get aiPlaygroundOutput => 'Output';

  @override
  String get aiPlaygroundClearOutput => 'Clear output';

  @override
  String get aiPlaygroundSectionAsr => 'ASR';

  @override
  String get aiPlaygroundSectionChat => 'Chat';

  @override
  String get aiPlaygroundSectionTranslation => 'Translation';

  @override
  String get aiPlaygroundSectionDictionary => 'Dictionary';

  @override
  String get aiPlaygroundSectionTtsAssessment => 'TTS / Assessment';

  @override
  String get youtubePasteFromClipboard => 'Paste';

  @override
  String get settingsSectionAppearanceLanguage => 'Appearance & Language';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAppearanceThemeSystem => 'System';

  @override
  String get settingsAppearanceThemeLight => 'Light';

  @override
  String get settingsAppearanceThemeDark => 'Dark';

  @override
  String get settingsAppearanceDisplayLanguage => 'Display language';

  @override
  String get settingsAppearanceLearningLanguage => 'Learning language';

  @override
  String get settingsAppearanceNativeLanguage => 'Native language';

  @override
  String get settingsLanguageSubtitleDeviceOnly =>
      'Stored on this device until you sign in.';

  @override
  String get settingsNativeLanguageGateSubtitle =>
      'Only one native language is available for your learning language.';

  @override
  String get settingsLanguageOptionEnUs => 'English (US)';

  @override
  String get settingsLanguageOptionEnGb => 'English (UK)';

  @override
  String get settingsLanguageOptionJaJp => 'Japanese';

  @override
  String get settingsLanguageOptionKoKr => 'Korean';

  @override
  String get settingsLanguageOptionEsEs => 'Spanish (Spain)';

  @override
  String get settingsLanguageOptionEsMx => 'Spanish (Mexico)';

  @override
  String get settingsLanguageOptionFrFr => 'French (France)';

  @override
  String get settingsLanguageOptionFrCa => 'French (Canada)';

  @override
  String get settingsLanguageOptionZhCn => 'Chinese (Simplified)';

  @override
  String get settingsLanguageOptionNbNo => 'Norwegian (Bokmål)';

  @override
  String get settingsLearningLanguageSubtitle =>
      'Default for Discover and import suggestions.';

  @override
  String get settingsLanguagePickerTitleLearning => 'Learning language';

  @override
  String get mediaLanguageUnknown => 'Unknown';

  @override
  String get mediaLanguagePickerTitle => 'Content language';

  @override
  String get mediaEditLanguage => 'Edit language';

  @override
  String get mediaLanguageUpdated => 'Language updated.';

  @override
  String get mediaLanguageUpdateFailed => 'Could not update language.';

  @override
  String get mediaEditDetails => 'Edit details';

  @override
  String get mediaDetailsTitleLabel => 'Title';

  @override
  String get mediaDetailsSave => 'Save';

  @override
  String get mediaDetailsUpdated => 'Details updated.';

  @override
  String get mediaDetailsUpdateFailed => 'Could not update details.';

  @override
  String get mediaDetailsMissing => 'This item is no longer in your library.';

  @override
  String get assessmentUnavailableLanguage =>
      'Pronunciation assessment is not available for this language.';

  @override
  String get discoverLanguageFilterAll => 'All languages';

  @override
  String get discoverLanguageFilterLabel => 'Language';

  @override
  String get settingsLanguagePickerTitleDisplay => 'Display language';

  @override
  String get settingsLanguagePickerTitleNative => 'Native language';

  @override
  String get settingsKeyboardOpenCheatsheet => 'Open shortcuts cheatsheet';

  @override
  String get settingsKeyboardOpenCheatsheetSubtitle =>
      'Browse and customize every shortcut';

  @override
  String get settingsKeyboardCustomizeTitle => 'Customize shortcuts';

  @override
  String get hotkeysHelpSearchHint => 'Search shortcuts';

  @override
  String get hotkeysHelpEmpty => 'No matching shortcuts';

  @override
  String get hotkeysHelpCustomize => 'Customize shortcuts';

  @override
  String hotkeysSettingsSubtitle(String key) {
    return 'Tap a row to change. Press $key anytime.';
  }

  @override
  String get hotkeysFilterHint => 'Filter shortcuts';

  @override
  String get hotkeysResetTooltip => 'Reset this shortcut';

  @override
  String get hotkeysEditTooltip => 'Change shortcut';

  @override
  String get settingsAboutMadeWithCare =>
      'Made with care for language learners.';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version';
  }

  @override
  String get settingsAboutOpenSourceTitle => 'Open source';

  @override
  String get settingsAboutOpenSourceSubtitle => 'View source code on GitHub';

  @override
  String get settingsDiagnosticsLoggingTitle => 'Diagnostic logging';

  @override
  String get settingsDiagnosticsLoggingSubtitle =>
      'Record extra detail for YouTube, sync, and sign-in issues';

  @override
  String get settingsDiagnosticsPrivacyNote =>
      'Logs stay on this device until you export them. Tokens and cookies are redacted.';

  @override
  String get settingsDiagnosticsExportTitle => 'Export diagnostic report';

  @override
  String get settingsDiagnosticsExportSubtitle =>
      'Save a zip of recent logs for support';

  @override
  String get settingsDiagnosticsExportSuccess => 'Diagnostic report saved.';

  @override
  String get settingsDiagnosticsExportError =>
      'Could not export diagnostic report.';

  @override
  String get settingsCheckForUpdatesTitle => 'Check for updates';

  @override
  String get settingsCheckForUpdatesSubtitle =>
      'See if a newer direct-download build is available';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateAvailableBadgeSemantics => 'Update available';

  @override
  String get updateMandatoryTitle => 'Update required';

  @override
  String updateVersionLine(String current, String latest) {
    return 'Installed $current → $latest';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateDismiss => 'Dismiss';

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateRetry => 'Retry';

  @override
  String get updatePreparing => 'Preparing download…';

  @override
  String updateDownloading(int percent) {
    return 'Downloading update… $percent%';
  }

  @override
  String get updateVerifying => 'Verifying download…';

  @override
  String get updateOpeningInstaller => 'Opening installer…';

  @override
  String get updateErrorDownload =>
      'Download failed. Check your connection and try again.';

  @override
  String get updateErrorChecksum =>
      'The download was corrupted. Please try again.';

  @override
  String get updateErrorPermission =>
      'Install permission was denied. Allow installs from this app in system settings, then retry.';

  @override
  String get updateErrorAlreadyRunning =>
      'An update download is already in progress.';

  @override
  String get updateErrorInstallation =>
      'Could not open the installer. Please try again.';

  @override
  String get updateErrorGeneric => 'Update failed. Please try again.';

  @override
  String get updateUpToDate => 'You\'re on the latest version.';

  @override
  String get updateCheckOffline =>
      'Could not check for updates. Check your connection.';

  @override
  String get updateStoreChannelHint =>
      'This build is from TestFlight or the Play Store — updates are handled by the store.';

  @override
  String get lookupSheetTitle => 'Look up';

  @override
  String get lookupSectionTranslation => 'Translation';

  @override
  String get lookupSectionContextualTranslation => 'Contextual translation';

  @override
  String get lookupSectionDictionary => 'Definition';

  @override
  String get lookupErrorRetry => 'Retry';

  @override
  String get lookupEmpty => 'No result.';

  @override
  String get lookupLemma => 'Lemma';

  @override
  String get lookupClose => 'Close';

  @override
  String get lookupCopy => 'Copy';

  @override
  String get lookupCopySuccess => 'Copied to clipboard';

  @override
  String get lookupTapToExpand => 'Expand to load';

  @override
  String get lookupSourceLanguage => 'Source language';

  @override
  String get lookupTargetLanguage => 'Target language';

  @override
  String get lookupSwapLanguages => 'Swap languages';

  @override
  String get lookupPickSourceTitle => 'Choose source language';

  @override
  String get lookupPickTargetTitle => 'Choose target language';

  @override
  String get lookupRefresh => 'Refresh';

  @override
  String get lookupSourceResetToLearning =>
      'Source language reset to learning default';

  @override
  String get vocabularyAddToVocabulary => 'Add to Vocabulary';

  @override
  String get vocabularyAddContext => 'Add Context';

  @override
  String get vocabularyAlreadyInVocabulary => 'Already in Vocabulary';

  @override
  String get vocabularyAdding => 'Adding…';

  @override
  String get vocabularyRemoving => 'Removing…';

  @override
  String get vocabularyConfirmDeleteTitle => 'Remove from vocabulary?';

  @override
  String get vocabularyConfirmDeleteBody =>
      'This deletes the word and all of its contexts.';

  @override
  String get vocabularyCancel => 'Cancel';

  @override
  String get vocabularyDelete => 'Delete';

  @override
  String get vocabularyTitle => 'Vocabulary';

  @override
  String get vocabularyReview => 'Review';

  @override
  String get vocabularyAllWords => 'All Words';

  @override
  String get vocabularyDue => 'Due';

  @override
  String get vocabularyStatusNew => 'New';

  @override
  String get vocabularyStatusLearning => 'Learning';

  @override
  String get vocabularyStatusReviewing => 'Reviewing';

  @override
  String get vocabularyStatusMastered => 'Mastered';

  @override
  String get vocabularyNoWords => 'No words yet';

  @override
  String get vocabularyNoWordsDescription =>
      'Select text in a transcript and choose Add to Vocabulary to start your word book.';

  @override
  String get vocabularyNoDueItems => 'Nothing due right now';

  @override
  String get vocabularyNoDueItemsDescription =>
      'You can still start a custom review of all words, by status, language, or a random set.';

  @override
  String get vocabularyNoMatches => 'No matching words';

  @override
  String get vocabularyNoMatchesDescription =>
      'Try a different search or clear the status and language filters.';

  @override
  String get vocabularyCustomReview => 'Custom review';

  @override
  String get vocabularySelectReviewItems => 'Choose what to review';

  @override
  String get vocabularyReviewDueItems => 'Due items';

  @override
  String get vocabularyReviewDueHint => 'Words scheduled for today or earlier';

  @override
  String get vocabularyReviewAll => 'All words';

  @override
  String get vocabularyReviewAllHint => 'Review every word in your book';

  @override
  String get vocabularyReviewByStatus => 'By status';

  @override
  String get vocabularyReviewByStatusHint =>
      'Focus on new, learning, reviewing, or mastered';

  @override
  String get vocabularyReviewByLanguage => 'By language';

  @override
  String get vocabularyReviewByLanguageHint =>
      'Limit the session to one source language';

  @override
  String get vocabularyReviewRandom => 'Random';

  @override
  String get vocabularyReviewRandomHint =>
      'Shuffle and take a short practice set';

  @override
  String get vocabularyNumberOfWords => 'Number of words';

  @override
  String vocabularyQueueCount(int count) {
    return '$count words';
  }

  @override
  String get vocabularyStartReview => 'Start review';

  @override
  String get vocabularyEmptyQueue => 'No words match this selection.';

  @override
  String get vocabularyExitReview => 'Exit review';

  @override
  String get vocabularyDontKnow => 'Don\'t Know';

  @override
  String get vocabularyKnow => 'Know';

  @override
  String get vocabularyKnowWell => 'Know Well';

  @override
  String get vocabularySkip => 'Skip';

  @override
  String get vocabularyUndo => 'Undo';

  @override
  String vocabularyProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get vocabularyReviewComplete => 'Review complete';

  @override
  String get vocabularyReviewCompleteDescription =>
      'Nice work. Your ratings are saved.';

  @override
  String get vocabularyDone => 'Done';

  @override
  String get vocabularySearchPlaceholder => 'Search words';

  @override
  String get vocabularyFilterStatus => 'Status';

  @override
  String get vocabularyFilterLanguage => 'Language';

  @override
  String get vocabularyFilterAll => 'All';

  @override
  String get vocabularyContext => 'Context';

  @override
  String get vocabularyDictionary => 'Dictionary';

  @override
  String get vocabularyNoContextAvailable => 'No context available';

  @override
  String get vocabularyDictionaryNotAvailable =>
      'Dictionary not available offline';

  @override
  String get vocabularyOverdue => 'Overdue';

  @override
  String get vocabularyToday => 'Today';

  @override
  String get vocabularyTomorrow => 'Tomorrow';

  @override
  String vocabularyInDays(int days) {
    return 'In $days days';
  }

  @override
  String get vocabularyFlipHint => 'Tap to flip';

  @override
  String get vocabularyPronounce => 'Pronounce';

  @override
  String get vocabularyFlipHintShortcuts => 'Space to flip · 1 / 2 / 3 to rate';

  @override
  String get vocabularyPlaySegment => 'Play segment';

  @override
  String get vocabularyOpenInPlayer => 'Open in player';

  @override
  String get vocabularyOpenInPlayerDescription =>
      'Opening the player will end this review session. Your ratings so far are saved.';

  @override
  String get vocabularyEchoReading => 'Echo reading';

  @override
  String get vocabularyPracticeDismiss => 'Close practice';

  @override
  String get vocabularyPracticePause => 'Pause';

  @override
  String get vocabularyPreviousContext => 'Previous context';

  @override
  String get vocabularyNextContext => 'Next context';

  @override
  String vocabularyContextOfTotal(int current, int total) {
    return '$current of $total';
  }

  @override
  String get vocabularyContextualTranslation => 'Contextual translation';

  @override
  String get vocabularyFetchDictionary => 'Look up dictionary';

  @override
  String get vocabularyFetchContextual => 'Translate context';

  @override
  String get vocabularyFetching => 'Loading…';

  @override
  String get vocabularyAiFetchFailed =>
      'Could not load. Try again when online.';

  @override
  String get vocabularyMediaUnavailable =>
      'Media actions unavailable for this context';

  @override
  String get vocabularyMediaPlayFailed => 'Could not play this segment';

  @override
  String get vocabularyMediaOpenFailed => 'Could not open this media';

  @override
  String get vocabularyConfirmContinue => 'Continue';

  @override
  String get vocabularyUnknownSource => 'Unknown source';

  @override
  String vocabularyLocatorLabel(String start, String duration) {
    return '${start}s · ${duration}s';
  }

  @override
  String get vocabularyExportToAnki => 'Export to Anki';

  @override
  String get vocabularyExport => 'Export';

  @override
  String get practicePosterShareTooltip => 'Share practice poster';

  @override
  String get practicePosterPreviewTitle => 'Share your practice';

  @override
  String get practicePosterTagline => 'Shadow reading';

  @override
  String get practicePosterStatTakes => 'Takes';

  @override
  String get practicePosterStatSentences => 'Sentences';

  @override
  String get practicePosterStatSpoken => 'Spoken';

  @override
  String get practicePosterQrHint =>
      'Scan to download SP Player\nplayer.enjoy.bot';

  @override
  String get practicePosterShareAction => 'Share poster';

  @override
  String get practicePosterShareLabel => 'Share';

  @override
  String get practicePosterShareSuccess => 'Poster shared.';

  @override
  String get practicePosterSaveSuccess => 'Poster saved.';

  @override
  String get practicePosterExportError => 'Could not share practice poster.';

  @override
  String get practicePosterLoadError =>
      'Could not load practice data for this video.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String notFoundSubtitle(String uri) {
    return 'We couldn\'t find $uri.';
  }

  @override
  String get notFoundBackHome => 'Back to home';

  @override
  String get recoveryTitle => 'Local data needs attention';

  @override
  String get recoverySubtitle =>
      'SP Player could not open its local database. The most common cause is a partial update. Your data is still on disk; you can copy the error before continuing.';

  @override
  String get recoveryOpenLogs => 'Open logs folder';

  @override
  String get recoveryOpenLogsError => 'Could not open the logs folder.';

  @override
  String get recoveryCopyError => 'Copy error';

  @override
  String get recoveryCopiedToClipboard => 'Error details copied to clipboard.';

  @override
  String get recoveryResetLibrary => 'Reset local library';

  @override
  String get recoveryResetLibrarySubtitle =>
      'Wipe the local database and start fresh. Your cloud library is not affected. A backup of the current state is written to the application support directory before the wipe.';

  @override
  String get recoveryResetLibraryConfirmTitle => 'Reset local library?';

  @override
  String get recoveryResetLibraryConfirmBody =>
      'This permanently deletes your local library, recordings, transcripts, and sync queue. The cloud library (if signed in) is preserved. A backup is written to the application support directory first.';

  @override
  String get recoveryResetLibraryConfirmAction => 'Reset everything';

  @override
  String get recoveryResetLibraryBackupError =>
      'Backup failed — the local database was not wiped. The error has been logged.';

  @override
  String get recoveryResetLibrarySuccess =>
      'Local library reset. Reloading your data…';

  @override
  String get recoveryResetLibraryError => 'Could not reset the local library.';

  @override
  String get widgetErrorTitle => 'Something went wrong';

  @override
  String get widgetErrorSubtitle =>
      'This screen hit an unexpected error. You can copy the details below and try navigating elsewhere.';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsSearchNoResultsTitle => 'No matching settings';

  @override
  String get settingsSearchNoResultsHint =>
      'Try a different word, or clear your search to browse everything.';

  @override
  String get settingsSearchClear => 'Clear search';

  @override
  String get settingsSectionNeedsAttention => 'Needs attention';

  @override
  String get transcriptBlurDisplayTitle => 'Hide transcript text';

  @override
  String get importCraftFromText => 'Craft…';

  @override
  String get homeCraftAction => 'Craft';

  @override
  String get craftHistoryTooltip => 'History';

  @override
  String get craftHistoryTitle => 'Craft history';

  @override
  String get craftHistoryEmptyTitle => 'No Craft items yet';

  @override
  String get craftHistoryEmptyHint =>
      'Create audio in Craft and it will show up here.';

  @override
  String get craftHistoryEmptyAction => 'Start crafting';

  @override
  String get craftHistoryRemoveTooltip => 'Remove Craft record';

  @override
  String get craftHistoryRemoveTitle => 'Remove Craft record?';

  @override
  String craftHistoryRemoveMessage(String title) {
    return 'Remove the Craft record for \"$title\". The practice audio stays in your library.';
  }

  @override
  String get craftHistoryRemoveConfirm => 'Remove';

  @override
  String get craftHistoryRemoved => 'Craft record removed';

  @override
  String get craftHistoryRemoveFailed => 'Could not remove this Craft record.';

  @override
  String get craftEditUnavailable => 'This Craft item is no longer available.';

  @override
  String get craftSourceLanguageLabel => 'Source language';

  @override
  String get craftTargetLanguageLabel => 'Learning language';

  @override
  String get craftTextInputHint => 'Paste or type text…';

  @override
  String get craftPasteFromClipboard => 'Paste from clipboard';

  @override
  String get craftCraftingProgress => 'Crafting your audio…';

  @override
  String get craftSameLanguageHint =>
      'Looks like this is already in your learning language.';

  @override
  String get craftOfflineBanner =>
      'You\'re offline. Craft needs an internet connection.';

  @override
  String get craftSignInRequired => 'Sign in to use Craft';

  @override
  String get craftSignInCta => 'Sign in';

  @override
  String get craftFailureTts =>
      'We couldn\'t turn the text into audio. Check your TTS provider settings or try again.';

  @override
  String get craftFailureTranslate =>
      'We couldn\'t translate the text. Try again or switch to Speak directly.';

  @override
  String get craftFailureSave =>
      'The audio was generated but couldn\'t be saved. Free up space and try again.';

  @override
  String get craftRetry => 'Retry';

  @override
  String get craftOpenAiSettings => 'Open AI settings';

  @override
  String get libraryProviderCraftBadge => 'Craft';

  @override
  String get craftScreenTitle => 'Craft';

  @override
  String get craftOverline => 'Practice audio from your own words';

  @override
  String get craftTranslateTool => 'Translate';

  @override
  String get craftSynthesizeTool => 'Synthesize';

  @override
  String get craftStyleLabel => 'Style';

  @override
  String get craftStyleLiteral => 'Literal';

  @override
  String get craftStyleNatural => 'Natural';

  @override
  String get craftStyleCasual => 'Casual';

  @override
  String get craftStyleFormal => 'Formal';

  @override
  String get craftStyleSimplified => 'Simplified';

  @override
  String get craftStyleDetailed => 'Detailed';

  @override
  String get craftStyleCustom => 'Custom';

  @override
  String get craftCustomPromptHint => 'Enter your custom translation prompt…';

  @override
  String get craftSwapLanguages => 'Swap languages';

  @override
  String get craftTranslateButton => 'Translate';

  @override
  String get craftReTranslateButton => 'Re-translate';

  @override
  String get craftCopyTranslation => 'Copy';

  @override
  String get craftCopiedToClipboard => 'Copied to clipboard';

  @override
  String get craftTranslatedText => 'Translated text';

  @override
  String get craftUseTranslatedText => 'Use translated text';

  @override
  String get craftVoiceLabel => 'Voice';

  @override
  String get craftNoVoicesForLanguage =>
      'No voices available for this language.';

  @override
  String get craftSynthesizeButton => 'Synthesize';

  @override
  String get craftReSynthesizeButton => 'Re-synthesize';

  @override
  String get craftSaveToLibrary => 'Save to library';

  @override
  String get craftPreviewLabel => 'Preview';

  @override
  String get craftSourceText => 'Source text';

  @override
  String get craftSynthText => 'Text to synthesize';

  @override
  String get craftModeExpress => 'Express';

  @override
  String get craftModeAdvanced => 'Advanced';

  @override
  String get craftStageCapture => 'Capture';

  @override
  String get craftStageRewrite => 'Rewrite';

  @override
  String get craftStageAudio => 'Audio';

  @override
  String get craftCaptureTitle => 'Say what\'s on your mind';

  @override
  String get craftCaptureSubtitle =>
      'Tap to record. Speak naturally in your language.';

  @override
  String get craftCaptureStop => 'Stop';

  @override
  String get craftCaptureCancel => 'Cancel';

  @override
  String get craftCaptureTypeInstead => 'Type instead';

  @override
  String get craftLoadingTranscribing => 'Transcribing…';

  @override
  String get craftLoadingRewriting => 'Crafting…';

  @override
  String get craftLoadingSynthesizing => 'Generating audio…';

  @override
  String get craftRewriteYourWords => 'Your words';

  @override
  String get craftRewriteTargetLabel => 'In your target language';

  @override
  String get craftRewriteRegenerate => 'Regenerate';

  @override
  String get craftRewriteReRecord => 'Re-record';

  @override
  String get craftRewriteGenerateAudio => 'Generate audio';

  @override
  String get craftAudioPreview => 'Preview';

  @override
  String get craftAudioSaySomethingElse => 'Save & say another';

  @override
  String get craftAudioPracticeNow => 'Save & practice';

  @override
  String get craftAudioUnsavedHint =>
      'Not saved yet. Leave now and this audio is discarded — it won’t appear in history.';

  @override
  String get craftAudioDiscardTitle => 'Discard this audio?';

  @override
  String get craftAudioDiscardMessage =>
      'Generated audio is only kept after you save. Leaving now discards it, and credits already used for this preview are not refunded.';

  @override
  String get craftAudioDiscardConfirm => 'Discard';

  @override
  String get craftSavedToLibrary => 'Saved to library';

  @override
  String get craftSolidTranscriptSttHint =>
      'If line timings look off, regenerate them with speech-to-text from the transcript panel.';

  @override
  String get craftStyleAuto => '✨ Auto';

  @override
  String get craftFailureAsr =>
      'We couldn\'t hear you clearly. Try recording again.';

  @override
  String get craftFailureEmptyTranscript =>
      'That was too short. Try speaking a bit longer.';

  @override
  String get craftRecordingMicDenied =>
      'Microphone access denied. Please enable it in settings.';

  @override
  String get errorGenericLoadFailed =>
      'Something went wrong. Please try again.';

  @override
  String get subscriptionViewPlansAndPackages => 'View plans & packages';

  @override
  String get byokProviderBillingMessage =>
      'Your AI provider declined this request. Please check your provider\'s billing or plan.';

  @override
  String get pronouncePlay => 'Play pronunciation';

  @override
  String get pronounceStop => 'Stop pronunciation';

  @override
  String get pronounceLoading => 'Loading pronunciation…';

  @override
  String get pronounceUnavailableLanguage =>
      'Pronunciation unavailable for this language';

  @override
  String get pronounceTextTooLong => 'Text is too long to pronounce';

  @override
  String get pronounceFailed => 'Couldn\'t play pronunciation';

  @override
  String get assessmentPlayMyRecording => 'Play my recording';

  @override
  String get assessmentStopMyRecording => 'Stop my recording';

  @override
  String get assessmentRecordingUnavailable => 'Recording file is unavailable';

  @override
  String get assessmentPlayMyClip => 'Play my recording of this word';

  @override
  String get assessmentStopMyClip => 'Stop my recording of this word';

  @override
  String get assessmentClipUnavailable => 'No recording clip for this word';

  @override
  String get onboardingTipSkip => 'Skip';

  @override
  String get onboardingTipHomeImportTitle => 'Import media';

  @override
  String get onboardingTipHomeImportBody =>
      'Bring in a local file or YouTube video to practice with.';

  @override
  String get onboardingTipHomeCraftTitle => 'Craft';

  @override
  String get onboardingTipHomeCraftBody =>
      'Create practice audio from text when you do not have a video yet.';

  @override
  String get onboardingTipEmptyTranscriptLocalTitle => 'Add a transcript';

  @override
  String get onboardingTipEmptyTranscriptLocalBody =>
      'Extract subtitles from the file or import a subtitle file so you can practice line by line.';

  @override
  String get onboardingTipEmptyTranscriptYoutubeTitle => 'Fetch transcript';

  @override
  String get onboardingTipEmptyTranscriptYoutubeBody =>
      'Pull captions for this YouTube video from the cloud to unlock practice.';

  @override
  String get onboardingTipEchoTitle => 'Echo mode';

  @override
  String get onboardingTipEchoBody =>
      'Turn on Echo to shadow each line and practice speaking along with the audio.';

  @override
  String get onboardingTipRecordTitle => 'Record yourself';

  @override
  String get onboardingTipRecordBody =>
      'Record your voice on a line, then compare it with the original.';

  @override
  String get onboardingTipAssessTitle => 'Assess pronunciation';

  @override
  String get onboardingTipAssessBody =>
      'After you record, check pronunciation feedback for that take.';

  @override
  String get settingsResetProductTipsTitle => 'Reset product tips';

  @override
  String get settingsResetProductTipsSubtitle =>
      'Show Home and Player tips again as if you were new.';

  @override
  String get settingsResetProductTipsConfirmTitle => 'Reset product tips?';

  @override
  String get settingsResetProductTipsConfirmBody =>
      'Tips for Craft, Import, transcripts, and practice will show again. Your library and account stay unchanged.';

  @override
  String get settingsResetProductTipsConfirmAction => 'Reset tips';

  @override
  String get settingsResetProductTipsDone => 'Product tips reset';

  @override
  String get settingsAnalyticsCaptureTitle => 'Usage analytics';

  @override
  String get settingsAnalyticsCaptureSubtitle =>
      'Share anonymous usage data to help improve Enjoy. Never includes your media, transcripts, or notes.';

  @override
  String get transcriptEmptyFetchYoutube => 'Fetch transcript';

  @override
  String homeGoalOfMinutes(int minutes) {
    return 'of $minutes min';
  }

  @override
  String homeGoalProgressRemaining(int done, int goal, int left) {
    return '$done / $goal min · $left min to go';
  }

  @override
  String homeGoalProgressDone(int done, int goal) {
    return '$done / $goal min';
  }

  @override
  String get homeContinueAction => 'Continue';

  @override
  String get homeOpenLibrary => 'Open library';

  @override
  String homeContinueLine(int line, int total) {
    return 'line $line of $total';
  }

  @override
  String get homeContinueEchoOn => 'Echo on';

  @override
  String get mediaRelativeToday => 'today';

  @override
  String get mediaRelativeYesterday => 'yesterday';

  @override
  String libraryTileAdded(String date) {
    return 'Added $date';
  }

  @override
  String get vocabularyOverline => 'Your word book';

  @override
  String vocabularyReviewDueAction(int count) {
    return 'Review $count due';
  }

  @override
  String get vocabularyDueToday => 'due today';

  @override
  String vocabularyDueEstimate(int minutes) {
    return 'Words scheduled for today or earlier · about $minutes min';
  }

  @override
  String get vocabularyByStatus => 'by status';

  @override
  String vocabularyDueWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words are waiting',
      one: '$count word is waiting',
    );
    return '$_temp0';
  }

  @override
  String get vocabularyDueReviewBody =>
      'Words scheduled for today or earlier. Space flips a card; 1, 2 and 3 rate it.';

  @override
  String vocabularyFilterValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get vocabularyFewer => 'Fewer';

  @override
  String get vocabularyMore => 'More';

  @override
  String get libraryOverlineLocal => 'On this device';

  @override
  String get libraryOverlineCloud => 'Saved to your Enjoy account';

  @override
  String librarySearchResults(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches for “$query”',
      one: '1 match for “$query”',
    );
    return '$_temp0';
  }

  @override
  String get discoverOverline => 'YouTube channels you follow';

  @override
  String get discoverRecentUploads => 'Recent uploads';

  @override
  String discoverUpdatedAgo(String age) {
    return 'Updated $age';
  }

  @override
  String discoverHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String discoverDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String discoverMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get discoverJustNow => 'just now';

  @override
  String get discoverAddToLibraryAction => 'Add to library';

  @override
  String get discoverStripSubscribe => 'Subscribe';

  @override
  String get playerEchoShort => 'Echo';

  @override
  String playerLineOfTotal(Object line, Object total) {
    return 'Line $line of $total';
  }

  @override
  String get assessmentMarginOverline => 'Pronunciation';

  @override
  String get assessmentLevelExcellent => 'Excellent';

  @override
  String get assessmentLevelGood => 'Good';

  @override
  String get assessmentLevelFair => 'Fair';

  @override
  String get assessmentLevelPoor => 'Needs work';

  @override
  String get playerMore => 'More';

  @override
  String get playerMoreDescEditTranscript =>
      'Edit the text and timing of the current transcript in the editor';

  @override
  String get playerMoreDescAddSubtitleFile =>
      'Pick a .srt / .vtt subtitle file from your computer and import it as a new track';

  @override
  String get playerMoreDescEmbeddedSubtitles =>
      'Extract subtitle tracks embedded inside the video file (MKV/MP4) - no speech recognition needed';

  @override
  String get playerMoreDescAiTranscript =>
      'Generate or regenerate subtitles with local speech recognition; old videos get the latest timing calibration by re-transcribing';

  @override
  String get playerMoreDescWordTimings =>
      'Add word-by-word timing and phonetics, for karaoke-style highlighting and shadowing practice';

  @override
  String get playerMoreDescRefreshFromCloud =>
      'Re-fetch transcripts from the cloud (YouTube official captions, or subtitles synced while signed in)';

  @override
  String get playerMoreDescDownloadTranscript =>
      'Export the current transcript as a .srt subtitle file on your computer';

  @override
  String get playerMoreDescEditDetails =>
      'Edit the title, cover and other details of this video';

  @override
  String get playerMoreDescExportLoopClip =>
      'Save the active Echo loop as a separate video clip (enabled while a loop is active)';

  @override
  String get playerMoreTranscriptSection => 'Transcript';

  @override
  String get playerMoreAddSubtitleFile => 'Add a subtitle file…';

  @override
  String get playerMoreUseEmbeddedSubtitles => 'Use embedded subtitles…';

  @override
  String get playerMoreCreateAiTranscript => 'Create an AI transcript…';

  @override
  String get playerMoreTranscribeAgain => 'Transcribe again…';

  @override
  String get playerMoreAddWordTimings => 'Add word timings & IPA';

  @override
  String get playerMoreAddIpa => 'Add pronunciation (IPA)';

  @override
  String get playerMoreRefreshFromCloud => 'Refresh from cloud';

  @override
  String get playerMoreEditTranscript => 'Edit transcript';

  @override
  String get transcriptEditorTitle => 'Edit transcript';

  @override
  String get transcriptEditorSave => 'Save';

  @override
  String get transcriptEditorSaved => 'Transcript updated';

  @override
  String get transcriptEditorSaveFailed =>
      'Couldn\'t save the transcript. Please try again.';

  @override
  String get transcriptEditorInvalidTiming =>
      'Start and duration must be times in seconds, like 1.25.';

  @override
  String get transcriptEditorEmpty => 'This media has no transcript to edit.';

  @override
  String get transcriptEditorNoCues => 'This transcript has no lines to edit.';

  @override
  String get transcriptEditorDiscardTitle => 'Discard unsaved edits?';

  @override
  String get transcriptEditorDiscardMessage =>
      'Your edits to this transcript have not been saved.';

  @override
  String get transcriptEditorDiscardConfirm => 'Discard';

  @override
  String transcriptEditorLineLabel(int index) {
    return 'Line $index';
  }

  @override
  String get transcriptEditorFieldStart => 'Start (seconds)';

  @override
  String get transcriptEditorFieldDuration => 'Duration (seconds)';

  @override
  String get playerMoreDownloadTranscript => 'Download transcript…';

  @override
  String get playerMoreTranslateAll => 'Translate full video';

  @override
  String get fullTranslateBannerCta => 'Translate full video';

  @override
  String get fullTranslateBannerContinue => 'Continue translation';

  @override
  String fullTranslateBannerRunningTitle(int translated, int total) {
    return 'Translating $translated / $total lines';
  }

  @override
  String fullTranslateBannerCachedProgress(int translated, int total) {
    return 'Cached $translated / $total lines';
  }

  @override
  String fullTranslateBannerReachedMinute(int minutes) {
    return 'translated up to minute $minutes';
  }

  @override
  String fullTranslateBannerPausedFailure(int failed) {
    return '$failed lines failed — continue translation to retry';
  }

  @override
  String get fullTranslateBannerPausedStopped =>
      'Stopped — continue translation to resume';

  @override
  String get fullTranslateBannerErrorGeneric =>
      'Cannot start translation — check the transcript and language settings';

  @override
  String get fullTranslateBannerErrorConfig =>
      'Configure a language model in Settings → AI first';

  @override
  String fullTranslateExportIncomplete(int remaining) {
    return '$remaining lines are not translated yet — run \'Translate full video\' first';
  }

  @override
  String get playerMoreMediaSection => 'Media';

  @override
  String get playerMoreEditDetails => 'Edit details';

  @override
  String get playerMoreExportLoopClip => 'Export the loop as a clip…';

  @override
  String get playerMoreExportLoopClipSuccess => 'Loop clip exported';

  @override
  String get playerMoreExportLoopClipFailed => 'Couldn\'t export the loop clip';

  @override
  String get playerMoreExportLoopClipFfmpegMissing =>
      'FFmpeg isn\'t available on this device';

  @override
  String get playerMoreKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get subtitlesPanelTitle => 'Subtitles & display';

  @override
  String get subtitlesSectionSubtitles => 'Subtitles';

  @override
  String get subtitlesSectionDisplay => 'Display';

  @override
  String get transcriptTypefaceLabel => 'Transcript type';

  @override
  String get transcriptTypefaceBook => 'Book';

  @override
  String get transcriptTypefaceClean => 'Clean';

  @override
  String get subtitlesHighlightSpokenWord => 'Highlight the spoken word';

  @override
  String get subtitlesHighlightSpokenWordHint =>
      'Underline each word as it is said.';

  @override
  String get subtitlesIpaUnderWords => 'IPA under words';

  @override
  String get subtitlesCaptionOverlay => 'Caption below video';

  @override
  String get subtitlesCaptionOverlayHint =>
      'Show the active line over the bottom of the video, transparent background.';

  @override
  String get subtitlesCaptionModeOff => 'Off';

  @override
  String get subtitlesCaptionModeOriginal => 'Original';

  @override
  String get subtitlesCaptionModeTranslation => 'Translation';

  @override
  String get subtitlesCaptionModeBoth => 'Bilingual';

  @override
  String get subtitlesIpaUnderWordsHint => 'Tap a word to hear it.';

  @override
  String get subtitlesNeedsWordTimingsMore =>
      'Add word timings & IPA first (··· More).';

  @override
  String get subtitlesNeedsWordTimingsBelow =>
      'Add word timings & IPA first (below).';

  @override
  String get subtitlesManageFromMore =>
      'Add or replace the transcript from ··· More.';

  @override
  String get transcriptEnrichRunningOwned =>
      'Generating word timings and pronunciation';

  @override
  String get transcriptEnrichRunningYoutube => 'Generating pronunciation';

  @override
  String get playerDictateShort => 'Dictate';

  @override
  String get playerDictateHintHover =>
      'Dictate · listen, then hover a line to peek';

  @override
  String get playerDictateHintHold => 'Press and hold to show';

  @override
  String playerDockPractisedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines practised',
      one: '1 line practised',
      zero: 'No lines practised yet',
    );
    return '$_temp0';
  }

  @override
  String playerDockLoopingLine(int line) {
    return 'Looping line $line';
  }

  @override
  String playerDockLoopingLines(int start, int end) {
    return 'Looping lines $start–$end';
  }

  @override
  String playerDockLoopHint(String seconds) {
    return '${seconds}s · + adds a line, − drops one';
  }

  @override
  String playerDockRecordingProgress(String elapsed, String total) {
    return 'Recording · ${elapsed}s of ${total}s';
  }

  @override
  String playerDockDictatingLine(int line) {
    return 'Dictating line $line';
  }

  @override
  String get playerDockDictateHover => 'Hover a line to peek';

  @override
  String get playerDockDictateHold => 'Hold to show';

  @override
  String get playerRepeatOff => 'Repeat: off';

  @override
  String get playerRepeatItem => 'Repeat this item';

  @override
  String get playerRepeatLoop => 'Repeat the echo loop';

  @override
  String playerMarginCloseTooltip(String close) {
    return '$close · Esc';
  }

  @override
  String takeNumbered(int number) {
    return 'Take $number';
  }

  @override
  String takesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count takes',
      one: '1 take',
    );
    return '$_temp0';
  }

  @override
  String get takeNotScoredClick => 'Not scored yet · click to score';

  @override
  String get takeNotScoredTap => 'Not scored yet · tap to score';

  @override
  String get takesMarginTitleClick => 'Your takes · click to play';

  @override
  String get takesMarginTitleTap => 'Your takes · tap to play';

  @override
  String get takesPitchOnLoop => 'Pitch contour on the loop';

  @override
  String lookupInThisAudio(String time) {
    return 'In this audio · $time';
  }

  @override
  String lookupInThisVideo(String time) {
    return 'In this video · $time';
  }

  @override
  String takeAssessmentTitle(int number) {
    return 'Take $number · Assessment';
  }

  @override
  String get settingsSectionNetwork => 'Network';

  @override
  String get settingsSectionNetworkHint => 'Proxy and VPN routing';

  @override
  String get settingsNetworkProxyModeTitle => 'Proxy mode';

  @override
  String get settingsNetworkProxyModeSystem => 'System';

  @override
  String get settingsNetworkProxyModeManual => 'Manual';

  @override
  String get settingsNetworkProxyModeDirect => 'Direct';

  @override
  String get settingsNetworkProxyModeHint =>
      'System follows your OS proxy (Clash, sing-box and similar). Manual uses the address below. Direct bypasses every proxy.';

  @override
  String get settingsNetworkProxyUrlLabel => 'Proxy address';

  @override
  String get settingsNetworkProxyUrlHint =>
      '127.0.0.1:7890 or http://host:port';

  @override
  String get settingsNetworkProxyUrlInvalid =>
      'Enter an HTTP proxy as host:port. SOCKS proxies are not supported.';

  @override
  String get settingsNetworkProxySave => 'Save proxy';

  @override
  String get settingsNetworkProxySaved => 'Proxy settings saved.';

  @override
  String get settingsNetworkEffectiveTitle => 'Effective proxy';

  @override
  String get settingsNetworkEffectiveDirect => 'Direct (no proxy)';

  @override
  String settingsNetworkEffectiveProxy(String endpoint, String source) {
    return '$endpoint ($source)';
  }

  @override
  String get settingsNetworkTestButton => 'Test connection';

  @override
  String get settingsNetworkTestRunning => 'Testing...';

  @override
  String get settingsNetworkTestYoutube => 'YouTube';

  @override
  String settingsNetworkTestOk(String label, int ms, String route) {
    return '$label: reachable in $ms ms via $route';
  }

  @override
  String settingsNetworkTestFail(String label, String route, String error) {
    return '$label: failed via $route ($error)';
  }

  @override
  String get playerDictationVoiceMode => 'Voice';

  @override
  String get playerDictationTextMode => 'Text';

  @override
  String get playerDictationVoiceHint =>
      'Listen and retell by voice. Tap Record when ready.';

  @override
  String get playerDictationVoiceHintHotkey =>
      'Listen and retell by voice. Tap Record or press R when ready.';

  @override
  String get playerDictationTextPlaceholder => 'Type what you hear...';

  @override
  String playerDictationWordCountProgress(int typed, int total) {
    return '$typed of about $total words';
  }

  @override
  String get playerDictationCheckAnswer => 'Check answer';

  @override
  String get playerDictationCheckingVoice => 'Transcribing speech...';

  @override
  String get playerDictationTryAgain => 'Try again';

  @override
  String get playerDictationNextLine => 'Next line';

  @override
  String get playerDictationRetryTranscription => 'Retry transcription';

  @override
  String get playerDictationLegendCorrect => 'Correct';

  @override
  String get playerDictationLegendMissed => 'Missed';

  @override
  String get playerDictationLegendExtra => 'Extra';

  @override
  String playerDictationStatsCorrect(int count) {
    return '$count correct';
  }

  @override
  String playerDictationStatsMissed(int count) {
    return '$count missed';
  }

  @override
  String playerDictationStatsExtra(int count) {
    return '$count extra';
  }

  @override
  String playerDictationPreviousAttempts(int count) {
    return 'Previous dictations ($count)';
  }

  @override
  String playerDictationAttemptAccuracy(int accuracy) {
    return '$accuracy% accuracy';
  }

  @override
  String get playerDictationRecordAgain => 'Record again';

  @override
  String get playerDictationRecordRetelling => 'Record retelling';

  @override
  String get playerDictationRecordRetellingHotkey => 'Record retelling (R)';

  @override
  String get playerDictationHeaderListen => 'DICTATION — LISTEN & RETELL';

  @override
  String get playerDictationHeaderChecked => 'DICTATION — CHECKED';

  @override
  String get settingsSectionLocalComponents => 'Local components';

  @override
  String get settingsSectionLocalComponentsHint =>
      'Manage offline transcription / translation model components.';
}
