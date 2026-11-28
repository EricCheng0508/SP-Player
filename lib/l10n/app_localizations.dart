import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh', 'CN'),
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SP Player'**
  String get appTitle;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeRecentMedia.
  ///
  /// In en, this message translates to:
  /// **'Recent media'**
  String get homeRecentMedia;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent media'**
  String get homeEmptyTitle;

  /// No description provided for @homeContinuePracticing.
  ///
  /// In en, this message translates to:
  /// **'Continue practicing'**
  String get homeContinuePracticing;

  /// No description provided for @homeContinueOpenSemantics.
  ///
  /// In en, this message translates to:
  /// **'Continue practicing, {title}'**
  String homeContinueOpenSemantics(String title);

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Import media or drop a file here to start.'**
  String get homeEmptyHint;

  /// No description provided for @libraryTabAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get libraryTabAudio;

  /// No description provided for @libraryTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get libraryTabVideo;

  /// No description provided for @libraryEmptyAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any audio'**
  String get libraryEmptyAudioTitle;

  /// No description provided for @libraryEmptyAudioHint.
  ///
  /// In en, this message translates to:
  /// **'Your library doesn\'t contain any audio content.'**
  String get libraryEmptyAudioHint;

  /// No description provided for @libraryEmptyVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any videos'**
  String get libraryEmptyVideoTitle;

  /// No description provided for @libraryEmptyVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Your library doesn\'t contain any video content.'**
  String get libraryEmptyVideoHint;

  /// No description provided for @librarySearchNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get librarySearchNoMatchesTitle;

  /// No description provided for @librarySearchNoMatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your library matches this search.'**
  String get librarySearchNoMatchesHint;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search library'**
  String get librarySearchHint;

  /// No description provided for @librarySearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get librarySearchClear;

  /// No description provided for @libraryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this item. Try again.'**
  String get libraryDeleteFailed;

  /// No description provided for @transcriptAccessibilityTranscriptList.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptAccessibilityTranscriptList;

  /// No description provided for @transcriptAccessibilityCue.
  ///
  /// In en, this message translates to:
  /// **'{time}. {snippet}'**
  String transcriptAccessibilityCue(String time, String snippet);

  /// No description provided for @transcriptAccessibilityCurrentLine.
  ///
  /// In en, this message translates to:
  /// **'Current playback line.'**
  String get transcriptAccessibilityCurrentLine;

  /// No description provided for @transcriptAccessibilityEchoRegion.
  ///
  /// In en, this message translates to:
  /// **'Echo practice region.'**
  String get transcriptAccessibilityEchoRegion;

  /// No description provided for @transcriptAccessibilityEchoCurrentLine.
  ///
  /// In en, this message translates to:
  /// **'Current echo line.'**
  String get transcriptAccessibilityEchoCurrentLine;

  /// No description provided for @transcriptLineRecordingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recording} other{{count} recordings}}'**
  String transcriptLineRecordingCount(int count);

  /// No description provided for @transcriptErrorFriendlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript unavailable'**
  String get transcriptErrorFriendlyTitle;

  /// No description provided for @transcriptErrorFriendlyHint.
  ///
  /// In en, this message translates to:
  /// **'Try choosing another subtitle track or importing a file.'**
  String get transcriptErrorFriendlyHint;

  /// No description provided for @transcriptFetchingSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Fetching subtitles…'**
  String get transcriptFetchingSubtitles;

  /// No description provided for @transcriptSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transcript'**
  String get transcriptSearchHint;

  /// No description provided for @transcriptSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching lines'**
  String get transcriptSearchNoMatches;

  /// No description provided for @lookupSectionExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain this sentence'**
  String get lookupSectionExplain;

  /// No description provided for @libraryTabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get libraryTabPlaylists;

  /// No description provided for @playlistCreateButton.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistCreateButton;

  /// No description provided for @playlistRename.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get playlistRename;

  /// No description provided for @playlistDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get playlistDelete;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @playlistSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get playlistSave;

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create a playlist to group media and play them in order.'**
  String get playlistEmptyHint;

  /// No description provided for @playlistItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String playlistItemCount(int count);

  /// No description provided for @playlistAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get playlistAddMedia;

  /// No description provided for @playlistPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playlistPlayAll;

  /// No description provided for @playlistRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistRemoveItem;

  /// No description provided for @playlistMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get playlistMoveUp;

  /// No description provided for @playlistMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get playlistMoveDown;

  /// No description provided for @playlistMissingMedia.
  ///
  /// In en, this message translates to:
  /// **'Media no longer in library'**
  String get playlistMissingMedia;

  /// No description provided for @playlistPickerNoMedia.
  ///
  /// In en, this message translates to:
  /// **'Import media first, then add it here.'**
  String get playlistPickerNoMedia;

  /// No description provided for @asrStatusExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting audio…'**
  String get asrStatusExtracting;

  /// No description provided for @asrStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading audio…'**
  String get asrStatusUploading;

  /// No description provided for @asrLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Spoken language'**
  String get asrLanguageTitle;

  /// No description provided for @asrLanguageAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect language'**
  String get asrLanguageAutoDetect;

  /// No description provided for @asrStatusRecognizing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing…'**
  String get asrStatusRecognizing;

  /// No description provided for @asrStatusPolling.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get asrStatusPolling;

  /// No description provided for @asrStatusSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get asrStatusSaving;

  /// No description provided for @asrStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transcript ready'**
  String get asrStatusSuccess;

  /// No description provided for @asrStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get asrStatusCancelled;

  /// No description provided for @asrStatusAligning.
  ///
  /// In en, this message translates to:
  /// **'Aligning…'**
  String get asrStatusAligning;

  /// No description provided for @asrStageExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract audio'**
  String get asrStageExtract;

  /// No description provided for @asrStageRecognize.
  ///
  /// In en, this message translates to:
  /// **'Recognize'**
  String get asrStageRecognize;

  /// No description provided for @asrStageAlign.
  ///
  /// In en, this message translates to:
  /// **'Align'**
  String get asrStageAlign;

  /// No description provided for @asrStageSegment.
  ///
  /// In en, this message translates to:
  /// **'Segment'**
  String get asrStageSegment;

  /// No description provided for @asrBannerElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get asrBannerElapsed;

  /// Generation banner info line: which local ASR engine is running.
  ///
  /// In en, this message translates to:
  /// **'Engine {engine}'**
  String asrBannerEngine(String engine);

  /// No description provided for @asrErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate transcript'**
  String get asrErrorGeneric;

  /// No description provided for @asrErrorFfmpegUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio extraction isn\'t available on this device'**
  String get asrErrorFfmpegUnavailable;

  /// No description provided for @asrErrorNoAudioTrack.
  ///
  /// In en, this message translates to:
  /// **'This file has no audio to transcribe'**
  String get asrErrorNoAudioTrack;

  /// No description provided for @asrErrorExtractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t extract audio. Please try again.'**
  String get asrErrorExtractionFailed;

  /// No description provided for @asrErrorFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large to transcribe'**
  String get asrErrorFileTooLarge;

  /// No description provided for @asrErrorUnsupportedSource.
  ///
  /// In en, this message translates to:
  /// **'This source isn\'t supported'**
  String get asrErrorUnsupportedSource;

  /// No description provided for @asrErrorUnsupportedMedia.
  ///
  /// In en, this message translates to:
  /// **'This audio format isn\'t supported for long transcription'**
  String get asrErrorUnsupportedMedia;

  /// No description provided for @asrErrorProviderTimeout.
  ///
  /// In en, this message translates to:
  /// **'Transcription timed out. Please try again.'**
  String get asrErrorProviderTimeout;

  /// No description provided for @asrErrorProviderRetryable.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed. Please try again.'**
  String get asrErrorProviderRetryable;

  /// No description provided for @asrErrorByokMissing.
  ///
  /// In en, this message translates to:
  /// **'Set up your AI provider to generate a transcript'**
  String get asrErrorByokMissing;

  /// No description provided for @asrErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and retry.'**
  String get asrErrorNetwork;

  /// No description provided for @asrErrorNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'No speech detected in this audio'**
  String get asrErrorNoSpeech;

  /// No description provided for @asrLongMediaConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'This may take a while'**
  String get asrLongMediaConfirmTitle;

  /// No description provided for @asrLongMediaConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Generating a transcript for {minutes} minutes of audio may take several minutes. Recognition runs on your own machine, so nothing is billed. Continue?'**
  String asrLongMediaConfirmBody(int minutes);

  /// No description provided for @asrLongMediaConfirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get asrLongMediaConfirmContinue;

  /// No description provided for @asrLongMediaConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get asrLongMediaConfirmCancel;

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'From file…'**
  String get importFromFile;

  /// No description provided for @importFromYoutube.
  ///
  /// In en, this message translates to:
  /// **'From YouTube URL…'**
  String get importFromYoutube;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverBrowseAction.
  ///
  /// In en, this message translates to:
  /// **'Browse Discover'**
  String get discoverBrowseAction;

  /// No description provided for @discoverRecommendedHeading.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get discoverRecommendedHeading;

  /// No description provided for @discoverSubscribeTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to channel'**
  String get discoverSubscribeTitle;

  /// No description provided for @discoverSubscribeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube channel URL or @handle.'**
  String get discoverSubscribeHint;

  /// No description provided for @discoverSubscribePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://www.youtube.com/@channel'**
  String get discoverSubscribePlaceholder;

  /// No description provided for @discoverSubscribeAction.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get discoverSubscribeAction;

  /// No description provided for @discoverSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed to channel'**
  String get discoverSubscribed;

  /// No description provided for @discoverSubscribedLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get discoverSubscribedLabel;

  /// No description provided for @discoverSubscribeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not subscribe to that channel.'**
  String get discoverSubscribeFailed;

  /// No description provided for @discoverUnsubscribeAction.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get discoverUnsubscribeAction;

  /// No description provided for @discoverUnsubscribed.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed from channel'**
  String get discoverUnsubscribed;

  /// No description provided for @discoverAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get discoverAddToLibrary;

  /// No description provided for @discoverAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added to your library'**
  String get discoverAddedToLibrary;

  /// No description provided for @discoverAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add this video.'**
  String get discoverAddFailed;

  /// No description provided for @discoverInLibrary.
  ///
  /// In en, this message translates to:
  /// **'In library'**
  String get discoverInLibrary;

  /// No description provided for @discoverFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos in feed yet'**
  String get discoverFeedEmptyTitle;

  /// No description provided for @discoverFeedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to a channel and refresh to load recent uploads.'**
  String get discoverFeedEmptyHint;

  /// No description provided for @discoverFeedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load feed'**
  String get discoverFeedErrorTitle;

  /// No description provided for @discoverFeedErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get discoverFeedErrorHint;

  /// No description provided for @discoverRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get discoverRetry;

  /// No description provided for @discoverRefreshPartialFailed.
  ///
  /// In en, this message translates to:
  /// **'Some channel feeds could not be refreshed.'**
  String get discoverRefreshPartialFailed;

  /// No description provided for @discoverRefreshPartialFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh {count, plural, one{1 channel} other{{count} channels}}: {names}'**
  String discoverRefreshPartialFailedDetail(int count, String names);

  /// No description provided for @discoverRefreshSingleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh {name}.'**
  String discoverRefreshSingleFailed(Object name);

  /// No description provided for @discoverRecommendedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recommended channels.'**
  String get discoverRecommendedLoadFailed;

  /// No description provided for @discoverSubscriptionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscriptions.'**
  String get discoverSubscriptionsLoadFailed;

  /// No description provided for @discoverNoSubscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to a recommended channel or paste a channel URL.'**
  String get discoverNoSubscriptionsHint;

  /// No description provided for @discoverManageChannels.
  ///
  /// In en, this message translates to:
  /// **'Manage channels'**
  String get discoverManageChannels;

  /// No description provided for @discoverFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoverFilterAll;

  /// No description provided for @discoverYourChannelsHeading.
  ///
  /// In en, this message translates to:
  /// **'Your channels'**
  String get discoverYourChannelsHeading;

  /// No description provided for @discoverRecommendedAllSubscribed.
  ///
  /// In en, this message translates to:
  /// **'You are subscribed to all recommended channels.'**
  String get discoverRecommendedAllSubscribed;

  /// No description provided for @youtubeImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import YouTube video'**
  String get youtubeImportTitle;

  /// No description provided for @youtubeImportHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube link or video ID'**
  String get youtubeImportHint;

  /// No description provided for @youtubeImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not read a valid YouTube video ID.'**
  String get youtubeImportInvalid;

  /// No description provided for @youtubeImporting.
  ///
  /// In en, this message translates to:
  /// **'Adding video…'**
  String get youtubeImporting;

  /// No description provided for @youtubeBadge.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtubeBadge;

  /// No description provided for @youtubeLoginTooltip.
  ///
  /// In en, this message translates to:
  /// **'YouTube account'**
  String get youtubeLoginTooltip;

  /// No description provided for @youtubeOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get youtubeOpenInBrowser;

  /// No description provided for @youtubeLoginClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get youtubeLoginClose;

  /// No description provided for @youtubeLoginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'YouTube sign-in'**
  String get youtubeLoginScreenTitle;

  /// No description provided for @youtubeLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out (clear cookies)'**
  String get youtubeLogout;

  /// No description provided for @youtubeUnavailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'YouTube is not available on this device.'**
  String get youtubeUnavailableOnDevice;

  /// No description provided for @youtubeUnavailableRuntimeMissing.
  ///
  /// In en, this message translates to:
  /// **'The YouTube playback runtime is not installed on this device.'**
  String get youtubeUnavailableRuntimeMissing;

  /// No description provided for @youtubeUnavailableRuntimeInitFailed.
  ///
  /// In en, this message translates to:
  /// **'YouTube playback failed to start on this device.'**
  String get youtubeUnavailableRuntimeInitFailed;

  /// No description provided for @youtubeUnavailableCodecsMissing.
  ///
  /// In en, this message translates to:
  /// **'YouTube video codecs are missing on this device. Install the GStreamer plugins (gst-plugins-good, gst-plugins-bad, gst-libav) and restart the app.'**
  String get youtubeUnavailableCodecsMissing;

  /// No description provided for @youtubeUnavailableDisabledByBuild.
  ///
  /// In en, this message translates to:
  /// **'YouTube playback is disabled in this build.'**
  String get youtubeUnavailableDisabledByBuild;

  /// Overlay when YouTube autoplay needs a user gesture or playback stopped immediately after play
  ///
  /// In en, this message translates to:
  /// **'Tap the video to play'**
  String get youtubeTapToPlayHint;

  /// Notice shown when the frame watchdog arms software rendering for the next launch
  ///
  /// In en, this message translates to:
  /// **'This GPU cannot render YouTube video. Relaunch the app to restore video with software rendering.'**
  String get youtubeVideoStallRelaunch;

  /// No description provided for @transportFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get transportFullscreen;

  /// No description provided for @transportExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get transportExitFullscreen;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @importMedia.
  ///
  /// In en, this message translates to:
  /// **'Import media'**
  String get importMedia;

  /// No description provided for @importingMedia.
  ///
  /// In en, this message translates to:
  /// **'Importing media…'**
  String get importingMedia;

  /// No description provided for @importMediaFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import this file.'**
  String get importMediaFailed;

  /// No description provided for @importUnsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'This file type isn’t supported. Choose an audio or video file.'**
  String get importUnsupportedFileType;

  /// No description provided for @navMainLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary navigation'**
  String get navMainLabel;

  /// No description provided for @miniPlayerMediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get miniPlayerMediaVideo;

  /// No description provided for @miniPlayerMediaAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get miniPlayerMediaAudio;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SP Player — local transcripts and shadow reading.'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsThemeDarkLocked.
  ///
  /// In en, this message translates to:
  /// **'Follows your system appearance.'**
  String get settingsThemeDarkLocked;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @previousLine.
  ///
  /// In en, this message translates to:
  /// **'Previous line'**
  String get previousLine;

  /// No description provided for @nextLine.
  ///
  /// In en, this message translates to:
  /// **'Next line'**
  String get nextLine;

  /// No description provided for @replayLine.
  ///
  /// In en, this message translates to:
  /// **'Replay line'**
  String get replayLine;

  /// No description provided for @echoMode.
  ///
  /// In en, this message translates to:
  /// **'Echo mode'**
  String get echoMode;

  /// Player top-bar segmented option for reading along (the non-echo mode).
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get playerListenModeTitle;

  /// Dock pill that toggles hiding the transcript text (blur practice).
  ///
  /// In en, this message translates to:
  /// **'Hide text'**
  String get playerDockHideText;

  /// Dock readout of the active transcript line.
  ///
  /// In en, this message translates to:
  /// **'Line {line} of {total}'**
  String playerDockLinePosition(int line, int total);

  /// Suffix shown in the dock while the Echo loop is active.
  ///
  /// In en, this message translates to:
  /// **'· looping'**
  String get playerDockLooping;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @playerTranscriptResizeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize the transcript panel'**
  String get playerTranscriptResizeHint;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import subtitle'**
  String get importSubtitle;

  /// No description provided for @noTranscript.
  ///
  /// In en, this message translates to:
  /// **'No transcript yet'**
  String get noTranscript;

  /// Overline above the empty-transcript title.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptEmptyOverline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @playerOpenGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this item.'**
  String get playerOpenGenericError;

  /// No description provided for @playbackRateTimes.
  ///
  /// In en, this message translates to:
  /// **'{rate}×'**
  String playbackRateTimes(String rate);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @subtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitles;

  /// No description provided for @subtitlesPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get subtitlesPrimary;

  /// No description provided for @subtitlesTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation (optional)'**
  String get subtitlesTranslation;

  /// No description provided for @subtitlesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get subtitlesNone;

  /// No description provided for @subtitlesNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get subtitlesNotSelected;

  /// No description provided for @subtitlesDeleteTrack.
  ///
  /// In en, this message translates to:
  /// **'Delete track'**
  String get subtitlesDeleteTrack;

  /// No description provided for @importSubtitleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subtitle imported'**
  String get importSubtitleSuccess;

  /// No description provided for @noTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Add a subtitle file, extract embedded captions, or create an AI transcript.'**
  String get noTranscriptHint;

  /// No description provided for @noTranscriptHintRemote.
  ///
  /// In en, this message translates to:
  /// **'Cloud captions load automatically when available. Open the CC menu to refresh.'**
  String get noTranscriptHintRemote;

  /// No description provided for @transcriptEmptyExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get transcriptEmptyExtract;

  /// Empty state: align an already-correct SRT/TXT to this media's timeline instead of re-recognizing (ADR-0106).
  ///
  /// In en, this message translates to:
  /// **'Align existing subtitles / script'**
  String get transcriptEmptyAlign;

  /// Align entry blocked: CTC aligner components missing.
  ///
  /// In en, this message translates to:
  /// **'Alignment components are not installed — install them in Settings → Local components'**
  String get transcriptAlignNotInstalled;

  /// Align entry placeholder while the CTC pipeline ships (P1).
  ///
  /// In en, this message translates to:
  /// **'Alignment components detected — word-level alignment lands in the next component release'**
  String get transcriptAlignPipelinePending;

  /// No description provided for @transcriptEmptyAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add subtitle'**
  String get transcriptEmptyAddSubtitle;

  /// No description provided for @transcriptEmptyGenerate.
  ///
  /// In en, this message translates to:
  /// **'AI transcript'**
  String get transcriptEmptyGenerate;

  /// No description provided for @subtitlesImportLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle language'**
  String get subtitlesImportLanguageTitle;

  /// No description provided for @subtitlesImportLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'BCP-47 code (e.g. en, zh-TW). Use und if unknown.'**
  String get subtitlesImportLanguageHint;

  /// No description provided for @subtitlesImportLanguageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Language code'**
  String get subtitlesImportLanguageFieldLabel;

  /// No description provided for @subtitlesProviderOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get subtitlesProviderOfficial;

  /// No description provided for @subtitlesProviderAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get subtitlesProviderAuto;

  /// No description provided for @subtitlesProviderAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get subtitlesProviderAi;

  /// No description provided for @subtitlesProviderUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get subtitlesProviderUser;

  /// No description provided for @subtitlesAutoTranslate.
  ///
  /// In en, this message translates to:
  /// **'Auto translate'**
  String get subtitlesAutoTranslate;

  /// No description provided for @subtitlesAutoTranslateLanguageChip.
  ///
  /// In en, this message translates to:
  /// **'To {language}'**
  String subtitlesAutoTranslateLanguageChip(String language);

  /// No description provided for @subtitlesExtractNoTracks.
  ///
  /// In en, this message translates to:
  /// **'No embedded subtitle tracks in this file (only video and audio). If you have a separate .srt or .vtt, use Import file.'**
  String get subtitlesExtractNoTracks;

  /// No description provided for @subtitlesExtractedCount.
  ///
  /// In en, this message translates to:
  /// **'Extracted {count} subtitle track(s).'**
  String subtitlesExtractedCount(int count);

  /// No description provided for @subtitlesRefreshDone.
  ///
  /// In en, this message translates to:
  /// **'Transcripts updated from cloud.'**
  String get subtitlesRefreshDone;

  /// Title of the dialog that picks the subtitle format for a transcript download.
  ///
  /// In en, this message translates to:
  /// **'Download transcript'**
  String get transcriptDownloadDialogTitle;

  /// Notice when the download is triggered with no active transcript.
  ///
  /// In en, this message translates to:
  /// **'No transcript to download yet.'**
  String get transcriptDownloadEmpty;

  /// Notice after the transcript file was saved or shared.
  ///
  /// In en, this message translates to:
  /// **'Transcript downloaded.'**
  String get transcriptDownloadSuccess;

  /// Notice when saving or sharing the transcript file failed.
  ///
  /// In en, this message translates to:
  /// **'Could not download the transcript.'**
  String get transcriptDownloadError;

  /// No description provided for @subtitlesNoPlayableUri.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve a playable file for this item.'**
  String get subtitlesNoPlayableUri;

  /// No description provided for @expandEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Expand echo backward'**
  String get expandEchoBackward;

  /// No description provided for @expandEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Expand echo forward'**
  String get expandEchoForward;

  /// No description provided for @shrinkEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Shrink echo backward'**
  String get shrinkEchoBackward;

  /// No description provided for @shrinkEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Shrink echo forward'**
  String get shrinkEchoForward;

  /// Echo loop caption for a single line.
  ///
  /// In en, this message translates to:
  /// **'LOOP · LINE {range} · {seconds} S'**
  String echoLoopCaptionLine(String range, String seconds);

  /// Echo loop caption for a line span.
  ///
  /// In en, this message translates to:
  /// **'LOOP · LINES {range} · {seconds} S'**
  String echoLoopCaptionLines(String range, String seconds);

  /// Echo loop caption while recording a take.
  ///
  /// In en, this message translates to:
  /// **'RECORDING TAKE {count}'**
  String echoLoopCaptionRecording(int count);

  /// No description provided for @shadowReadingHint.
  ///
  /// In en, this message translates to:
  /// **'Practice speaking along this segment. Record your voice and compare pitch with the reference.'**
  String get shadowReadingHint;

  /// No description provided for @pitchContourTitle.
  ///
  /// In en, this message translates to:
  /// **'Pitch contour'**
  String get pitchContourTitle;

  /// No description provided for @pitchContourError.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze pitch for this segment.'**
  String get pitchContourError;

  /// No description provided for @pitchContourWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get pitchContourWaveform;

  /// No description provided for @pitchContourReference.
  ///
  /// In en, this message translates to:
  /// **'Original pitch'**
  String get pitchContourReference;

  /// No description provided for @pitchContourUser.
  ///
  /// In en, this message translates to:
  /// **'Your pitch'**
  String get pitchContourUser;

  /// No description provided for @pitchContourAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing pitch…'**
  String get pitchContourAnalyzing;

  /// No description provided for @shadowRecordingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recordings for this segment yet.'**
  String get shadowRecordingEmpty;

  /// No description provided for @shadowRecordingTake.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get shadowRecordingTake;

  /// No description provided for @shadowTakesEmptyPrefix.
  ///
  /// In en, this message translates to:
  /// **'No recordings for this segment yet. Press'**
  String get shadowTakesEmptyPrefix;

  /// No description provided for @shadowTakesEmptySuffix.
  ///
  /// In en, this message translates to:
  /// **'and say it back.'**
  String get shadowTakesEmptySuffix;

  /// No description provided for @shadowRecordingPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get shadowRecordingPlay;

  /// No description provided for @shadowRecordingChooseTake.
  ///
  /// In en, this message translates to:
  /// **'Switch take'**
  String get shadowRecordingChooseTake;

  /// No description provided for @shadowRecordingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shadowRecordingDelete;

  /// No description provided for @shadowRecordingDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this take?'**
  String get shadowRecordingDeleteConfirmTitle;

  /// No description provided for @shadowRecordingDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{takeLabel} will be permanently deleted. This cannot be undone.'**
  String shadowRecordingDeleteConfirmMessage(String takeLabel);

  /// No description provided for @shadowRecordingRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get shadowRecordingRecord;

  /// No description provided for @shadowRecordingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get shadowRecordingStop;

  /// No description provided for @shadowRecordingMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record.'**
  String get shadowRecordingMicDenied;

  /// Save failed after recording stopped; reason is a short technical detail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save recording: {reason}'**
  String shadowRecordingSaveFailed(String reason);

  /// Header for the AI provider settings section.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsSectionAi;

  /// Subtitle under the AI settings section header.
  ///
  /// In en, this message translates to:
  /// **'Configure your own API keys per feature; speech recognition and translation use local components by default.'**
  String get settingsSectionAiHint;

  /// Settings tile title for AI provider configuration.
  ///
  /// In en, this message translates to:
  /// **'AI providers'**
  String get settingsAiProvidersTileTitle;

  /// Screen title for AI provider settings.
  ///
  /// In en, this message translates to:
  /// **'AI providers'**
  String get settingsAiProvidersTitle;

  /// Privacy notice on the AI providers settings screen.
  ///
  /// In en, this message translates to:
  /// **'API keys are stored securely on this device only and are never uploaded to any cloud.'**
  String get settingsAiProvidersPrivacyNotice;

  /// Label when a modality uses Enjoy cloud AI.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsAiProvidersEnjoyAi;

  /// Label when a modality uses BYOK credentials.
  ///
  /// In en, this message translates to:
  /// **'Your API key'**
  String get settingsAiProvidersByok;

  /// Card title for LLM-backed features (chat, translation, dictionary).
  ///
  /// In en, this message translates to:
  /// **'Language models'**
  String get settingsAiProvidersModalityLlm;

  /// Card title for ASR modality.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition (subtitles)'**
  String get settingsAiProvidersModalityAsr;

  /// Card title for TTS modality.
  ///
  /// In en, this message translates to:
  /// **'Text-to-speech'**
  String get settingsAiProvidersModalityTts;

  /// Card title for pronunciation assessment modality.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation assessment'**
  String get settingsAiProvidersModalityAssessment;

  /// Label for LLM protocol spec selector.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get settingsAiProvidersLlmSpecLabel;

  /// OpenAI-compatible LLM protocol spec option.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible'**
  String get settingsAiProvidersLlmSpecOpenAi;

  /// Anthropic-compatible LLM protocol spec option.
  ///
  /// In en, this message translates to:
  /// **'Anthropic-compatible'**
  String get settingsAiProvidersLlmSpecAnthropic;

  /// Google-compatible LLM protocol spec option.
  ///
  /// In en, this message translates to:
  /// **'Google-compatible'**
  String get settingsAiProvidersLlmSpecGoogle;

  /// Label for BYOK provider preset chips.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get settingsAiProvidersPresetsLabel;

  /// BYOK base URL field label.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get settingsAiProvidersBaseUrlLabel;

  /// BYOK base URL field hint.
  ///
  /// In en, this message translates to:
  /// **'https://api.example.com/v1'**
  String get settingsAiProvidersBaseUrlHint;

  /// BYOK API key field label.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsAiProvidersApiKeyLabel;

  /// Hint when a BYOK key is already stored.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep saved key'**
  String get settingsAiProvidersApiKeyExistingHint;

  /// Tooltip to reveal BYOK API key field.
  ///
  /// In en, this message translates to:
  /// **'Show API key'**
  String get settingsAiProvidersShowApiKey;

  /// Tooltip to mask BYOK API key field.
  ///
  /// In en, this message translates to:
  /// **'Hide API key'**
  String get settingsAiProvidersHideApiKey;

  /// BYOK model field label.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsAiProvidersModelLabel;

  /// Button to list models from OpenAI-compatible endpoint.
  ///
  /// In en, this message translates to:
  /// **'Fetch models'**
  String get settingsAiProvidersFetchModels;

  /// Dropdown label for fetched OpenAI-compatible models.
  ///
  /// In en, this message translates to:
  /// **'Fetched models'**
  String get settingsAiProvidersFetchedModelsLabel;

  /// Error when OpenAI-compatible model list fails.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch models. Check base URL and API key.'**
  String get settingsAiProvidersFetchModelsFailed;

  /// Message when model list is empty.
  ///
  /// In en, this message translates to:
  /// **'No models returned from this endpoint.'**
  String get settingsAiProvidersFetchModelsEmpty;

  /// Save BYOK settings button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsAiProvidersSave;

  /// Success notice after saving BYOK settings.
  ///
  /// In en, this message translates to:
  /// **'AI provider settings saved.'**
  String get settingsAiProvidersSaveSuccess;

  /// Remove BYOK credentials action.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsAiProvidersRemoveByok;

  /// Confirm dialog title for removing BYOK.
  ///
  /// In en, this message translates to:
  /// **'Remove the saved key?'**
  String get settingsAiProvidersRemoveByokTitle;

  /// Confirm dialog body for removing BYOK.
  ///
  /// In en, this message translates to:
  /// **'This deletes the API key saved on this device.'**
  String get settingsAiProvidersRemoveByokBody;

  /// Success notice after removing BYOK.
  ///
  /// In en, this message translates to:
  /// **'Saved key removed.'**
  String get settingsAiProvidersRemoveByokSuccess;

  /// Cancel action in BYOK dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsAiProvidersCancel;

  /// Placeholder for modalities not yet configurable in UI.
  ///
  /// In en, this message translates to:
  /// **'BYOK configuration for this feature is coming soon.'**
  String get settingsAiProvidersComingSoon;

  /// Label for Azure Speech subscription key field in assessment BYOK form
  ///
  /// In en, this message translates to:
  /// **'Azure subscription key'**
  String get settingsAiProvidersSpeechSubscriptionKeyLabel;

  /// Label for Azure Speech region field in assessment BYOK form
  ///
  /// In en, this message translates to:
  /// **'Azure region'**
  String get settingsAiProvidersSpeechRegionLabel;

  /// Hint for Azure Speech region field
  ///
  /// In en, this message translates to:
  /// **'eastus'**
  String get settingsAiProvidersSpeechRegionHint;

  /// Label for ASR/TTS BYOK vendor selector
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get settingsAiProvidersSpeechKindLabel;

  /// OpenAI-compatible Whisper option for speech BYOK
  ///
  /// In en, this message translates to:
  /// **'OpenAI Whisper'**
  String get settingsAiProvidersSpeechKindOpenAi;

  /// Azure Speech option for speech BYOK
  ///
  /// In en, this message translates to:
  /// **'Azure Speech'**
  String get settingsAiProvidersSpeechKindAzure;

  /// Hint under the speech provider segmented button, OpenAI option.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible: speech-to-text (generate subtitles, dictation, echo transcription).'**
  String get settingsAiProvidersSpeechKindHintOpenAi;

  /// Hint under the speech provider segmented button, Azure option.
  ///
  /// In en, this message translates to:
  /// **'Azure Speech: phoneme-level pronunciation diagnosis. Also supports speech-to-text. Without it, take scoring falls back to local assessment.'**
  String get settingsAiProvidersSpeechKindHintAzure;

  /// Label for Whisper model field in ASR BYOK form
  ///
  /// In en, this message translates to:
  /// **'Whisper model'**
  String get settingsAiProvidersSpeechWhisperModelLabel;

  /// Hint for Whisper model field
  ///
  /// In en, this message translates to:
  /// **'whisper-1'**
  String get settingsAiProvidersSpeechWhisperModelHint;

  /// No description provided for @settingsAiEngineLocal.
  ///
  /// In en, this message translates to:
  /// **'Local (default)'**
  String get settingsAiEngineLocal;

  /// No description provided for @settingsAiEngineCloud.
  ///
  /// In en, this message translates to:
  /// **'Custom cloud'**
  String get settingsAiEngineCloud;

  /// Label for OpenAI-compatible TTS model field
  ///
  /// In en, this message translates to:
  /// **'TTS model'**
  String get settingsAiProvidersSpeechTtsModelLabel;

  /// Hint for OpenAI-compatible TTS model field
  ///
  /// In en, this message translates to:
  /// **'tts-1'**
  String get settingsAiProvidersSpeechTtsModelHint;

  /// Placeholder shown when a BYOK API key is saved but hidden
  ///
  /// In en, this message translates to:
  /// **'••••••••••••'**
  String get settingsAiProvidersApiKeySavedMask;

  /// Button to replace a saved BYOK API key
  ///
  /// In en, this message translates to:
  /// **'Edit key'**
  String get settingsAiProvidersApiKeyEdit;

  /// Runtime error when BYOK modality has no secure key
  ///
  /// In en, this message translates to:
  /// **'BYOK is selected for {modality}, but no API key is saved on this device.'**
  String byokNotConfiguredMessage(String modality);

  /// Hint to open AI provider settings after BYOK misconfiguration
  ///
  /// In en, this message translates to:
  /// **'Open Settings → AI providers to add your key.'**
  String get byokNotConfiguredOpenSettings;

  /// BYOK validation: missing API key.
  ///
  /// In en, this message translates to:
  /// **'API key is required.'**
  String get byokValidationApiKeyRequired;

  /// BYOK validation: missing base URL.
  ///
  /// In en, this message translates to:
  /// **'Base URL is required.'**
  String get byokValidationBaseUrlRequired;

  /// BYOK validation: URL guard failure.
  ///
  /// In en, this message translates to:
  /// **'Base URL must be a public HTTPS endpoint.'**
  String get byokValidationBaseUrlInvalid;

  /// BYOK validation: missing model.
  ///
  /// In en, this message translates to:
  /// **'Model is required.'**
  String get byokValidationModelRequired;

  /// BYOK validation: missing Azure region.
  ///
  /// In en, this message translates to:
  /// **'Azure region is required.'**
  String get byokValidationRegionRequired;

  /// BYOK validation: missing LLM spec or speech kind.
  ///
  /// In en, this message translates to:
  /// **'Protocol configuration is incomplete.'**
  String get byokValidationApiSpecRequired;

  /// BYOK validation: assessment must use Azure Speech.
  ///
  /// In en, this message translates to:
  /// **'Assessment BYOK requires Azure Speech.'**
  String get byokValidationAzureKindRequired;

  /// Header for the recording settings section.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get settingsSectionRecording;

  /// Subtitle under the recording section header.
  ///
  /// In en, this message translates to:
  /// **'Microphone used for shadow-reading takes.'**
  String get settingsSectionRecordingHint;

  /// Settings switch title for opt-in Craft timeline enrichment.
  ///
  /// In en, this message translates to:
  /// **'Enrich Craft word timings'**
  String get settingsTranscriptEnrichmentTitle;

  /// Settings switch title for opt-in karaoke word highlight in the transcript panel.
  ///
  /// In en, this message translates to:
  /// **'Highlight current word'**
  String get settingsTranscriptKaraokeTitle;

  /// Settings switch title for opt-in stored IPA overlay on transcript words.
  ///
  /// In en, this message translates to:
  /// **'Show pronunciation (IPA)'**
  String get settingsTranscriptIpaOverlayTitle;

  /// Hint when karaoke stays off for YouTube or other non-extractable media.
  ///
  /// In en, this message translates to:
  /// **'Karaoke needs word timings from a local file.'**
  String get transcriptKaraokeUnavailableRemoteHint;

  /// CC-sheet tile subtitle for owned-media transcript enrichment.
  ///
  /// In en, this message translates to:
  /// **'Uses this item\'s audio. Playback stays available.'**
  String get transcriptEnrichOwnedSubtitle;

  /// CC-sheet tile subtitle for YouTube IPA-only enrichment.
  ///
  /// In en, this message translates to:
  /// **'Karaoke stays unavailable. The video is not downloaded.'**
  String get transcriptEnrichYoutubeSubtitle;

  /// Busy enrich tile title that cancels an in-flight run.
  ///
  /// In en, this message translates to:
  /// **'Cancel generation'**
  String get transcriptEnrichCancel;

  /// Enrich tile title after a failed run.
  ///
  /// In en, this message translates to:
  /// **'Try generating again'**
  String get transcriptEnrichRetry;

  /// Inline error on the enrich tile after failure or cancel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate. Tap to try again.'**
  String get transcriptEnrichFailed;

  /// Busy enrich tile subtitle while aligning cues on a long transcript.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total}'**
  String transcriptEnrichProgress(int completed, int total);

  /// Title of the microphone picker tile in settings.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingsRecordingMicTitle;

  /// Subtitle of the mic tile when auto-picking. The label is the resolved device.
  ///
  /// In en, this message translates to:
  /// **'Auto · {label}'**
  String settingsRecordingMicAuto(String label);

  /// Subtitle of the mic tile when auto-picking and no devices were enumerated yet.
  ///
  /// In en, this message translates to:
  /// **'Auto · system default'**
  String get settingsRecordingMicAutoNoDevice;

  /// Short trailing value for the settings hub recording row when the microphone is auto-picked.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsRecordingMicAutoShort;

  /// Subtitle / empty state when the OS reports no input devices.
  ///
  /// In en, this message translates to:
  /// **'No microphones detected'**
  String get settingsRecordingMicEmpty;

  /// Menu/dialog option that lets the heuristic pick the first non-virtual device.
  ///
  /// In en, this message translates to:
  /// **'Auto (skip virtual mics)'**
  String get settingsRecordingMicAutoOption;

  /// Title of the modal dialog used to pick a recording input device.
  ///
  /// In en, this message translates to:
  /// **'Choose microphone'**
  String get settingsRecordingMicDialogTitle;

  /// Warning shown right after a take when the captured WAV has no signal energy (e.g. Windows captured a virtual loopback device).
  ///
  /// In en, this message translates to:
  /// **'No microphone signal detected. Open Settings → Recording to pick a different microphone.'**
  String get shadowRecordingSilentWarning;

  /// No description provided for @shadowRecordingPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play this take.'**
  String get shadowRecordingPlaybackFailed;

  /// Shown while recording after elapsed time exceeds the reference segment duration.
  ///
  /// In en, this message translates to:
  /// **'+{seconds}s over target'**
  String shadowRecordingOverTarget(String seconds);

  /// Accessibility label for the live recording progress while shadow-reading against a target duration.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} seconds elapsed of {target} seconds target'**
  String shadowRecordingElapsedSemantics(String elapsed, String target);

  /// Visible live recording progress against a target duration (elapsed / target).
  ///
  /// In en, this message translates to:
  /// **'{elapsed} s / {target} s'**
  String shadowRecordingElapsedCountdown(String elapsed, String target);

  /// Visible live recording progress with no target duration.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} s'**
  String shadowRecordingElapsedSeconds(String elapsed);

  /// Reason shown when a just-recorded file is missing from disk after stopping.
  ///
  /// In en, this message translates to:
  /// **'Recording file was not found.'**
  String get shadowRecordingFileNotFound;

  /// No description provided for @hotkeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get hotkeysTitle;

  /// No description provided for @hotkeysHintFooter.
  ///
  /// In en, this message translates to:
  /// **'Press Shift+/ (?) to open this list.'**
  String get hotkeysHintFooter;

  /// No description provided for @hotkeysCustomizedBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get hotkeysCustomizedBadge;

  /// No description provided for @hotkeysSectionKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get hotkeysSectionKeyboard;

  /// No description provided for @hotkeysResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all shortcuts'**
  String get hotkeysResetAll;

  /// No description provided for @hotkeysResetAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all shortcuts?'**
  String get hotkeysResetAllConfirmTitle;

  /// No description provided for @hotkeysResetAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This restores every shortcut to its default binding. Custom bindings cannot be undone.'**
  String get hotkeysResetAllConfirmMessage;

  /// No description provided for @hotkeysCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Press new shortcut'**
  String get hotkeysCaptureTitle;

  /// No description provided for @hotkeysCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Press a key combination. Escape cancels.'**
  String get hotkeysCaptureHint;

  /// No description provided for @hotkeysConflictError.
  ///
  /// In en, this message translates to:
  /// **'That shortcut is already used.'**
  String get hotkeysConflictError;

  /// No description provided for @hotkeysScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get hotkeysScopeGlobal;

  /// No description provided for @hotkeysScopePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get hotkeysScopePlayer;

  /// No description provided for @hotkeysScopeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get hotkeysScopeLibrary;

  /// No description provided for @hotkeysScopeModal.
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get hotkeysScopeModal;

  /// No description provided for @hotkeysDescHelp.
  ///
  /// In en, this message translates to:
  /// **'Show keyboard shortcuts'**
  String get hotkeysDescHelp;

  /// No description provided for @hotkeysDescSearch.
  ///
  /// In en, this message translates to:
  /// **'Open search'**
  String get hotkeysDescSearch;

  /// No description provided for @hotkeysDescSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get hotkeysDescSettings;

  /// No description provided for @hotkeysDescCraft.
  ///
  /// In en, this message translates to:
  /// **'Open Craft'**
  String get hotkeysDescCraft;

  /// No description provided for @hotkeysDescTogglePlay.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get hotkeysDescTogglePlay;

  /// No description provided for @hotkeysDescToggleExpand.
  ///
  /// In en, this message translates to:
  /// **'Toggle player expand/collapse'**
  String get hotkeysDescToggleExpand;

  /// No description provided for @hotkeysDescToggleFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen'**
  String get hotkeysDescToggleFullscreen;

  /// No description provided for @hotkeysDescSearchTranscript.
  ///
  /// In en, this message translates to:
  /// **'Search transcript (Ctrl+F)'**
  String get hotkeysDescSearchTranscript;

  /// No description provided for @hotkeysDescSeekBack.
  ///
  /// In en, this message translates to:
  /// **'Seek back 3 seconds'**
  String get hotkeysDescSeekBack;

  /// No description provided for @hotkeysDescSeekForward.
  ///
  /// In en, this message translates to:
  /// **'Seek forward 3 seconds'**
  String get hotkeysDescSeekForward;

  /// No description provided for @hotkeysDescVolumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get hotkeysDescVolumeUp;

  /// No description provided for @hotkeysDescVolumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get hotkeysDescVolumeDown;

  /// No description provided for @hotkeysDescToggleMute.
  ///
  /// In en, this message translates to:
  /// **'Mute / unmute'**
  String get hotkeysDescToggleMute;

  /// No description provided for @hotkeysDescPrevLine.
  ///
  /// In en, this message translates to:
  /// **'Play previous line'**
  String get hotkeysDescPrevLine;

  /// No description provided for @hotkeysDescNextLine.
  ///
  /// In en, this message translates to:
  /// **'Play next line'**
  String get hotkeysDescNextLine;

  /// No description provided for @hotkeysDescReplayLine.
  ///
  /// In en, this message translates to:
  /// **'Replay current line'**
  String get hotkeysDescReplayLine;

  /// No description provided for @hotkeysDescToggleEchoMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Echo mode'**
  String get hotkeysDescToggleEchoMode;

  /// No description provided for @hotkeysDescToggleBlurPractice.
  ///
  /// In en, this message translates to:
  /// **'Dictate (hide text)'**
  String get hotkeysDescToggleBlurPractice;

  /// No description provided for @hotkeysDescToggleRecording.
  ///
  /// In en, this message translates to:
  /// **'Start/Stop recording'**
  String get hotkeysDescToggleRecording;

  /// No description provided for @hotkeysDescToggleAssessment.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide pronunciation assessment'**
  String get hotkeysDescToggleAssessment;

  /// No description provided for @hotkeysDescTogglePitchContour.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide pitch contour'**
  String get hotkeysDescTogglePitchContour;

  /// No description provided for @hotkeysDescPlayRecording.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause recording'**
  String get hotkeysDescPlayRecording;

  /// No description provided for @hotkeysDescSlowDown.
  ///
  /// In en, this message translates to:
  /// **'Slow down playback speed'**
  String get hotkeysDescSlowDown;

  /// No description provided for @hotkeysDescSpeedUp.
  ///
  /// In en, this message translates to:
  /// **'Speed up playback speed'**
  String get hotkeysDescSpeedUp;

  /// No description provided for @hotkeysDescExpandEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Add the line above to the loop'**
  String get hotkeysDescExpandEchoBackward;

  /// No description provided for @hotkeysDescExpandEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Add the line below to the loop'**
  String get hotkeysDescExpandEchoForward;

  /// No description provided for @hotkeysDescShrinkEchoBackward.
  ///
  /// In en, this message translates to:
  /// **'Drop the first line of the loop'**
  String get hotkeysDescShrinkEchoBackward;

  /// No description provided for @hotkeysDescShrinkEchoForward.
  ///
  /// In en, this message translates to:
  /// **'Drop the last line of the loop'**
  String get hotkeysDescShrinkEchoForward;

  /// No description provided for @hotkeysDescLibrarySearch.
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get hotkeysDescLibrarySearch;

  /// No description provided for @hotkeysDescCloseModal.
  ///
  /// In en, this message translates to:
  /// **'Close overlay, exit fullscreen, or cancel recording'**
  String get hotkeysDescCloseModal;

  /// No description provided for @assessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation assessment'**
  String get assessmentTitle;

  /// No description provided for @assessmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed scoring for your reading.'**
  String get assessmentDescription;

  /// No description provided for @assessmentRun.
  ///
  /// In en, this message translates to:
  /// **'Run pronunciation assessment'**
  String get assessmentRun;

  /// No description provided for @assessmentView.
  ///
  /// In en, this message translates to:
  /// **'View pronunciation assessment'**
  String get assessmentView;

  /// No description provided for @assessmentReassess.
  ///
  /// In en, this message translates to:
  /// **'Re-assess'**
  String get assessmentReassess;

  /// No description provided for @assessmentScoring.
  ///
  /// In en, this message translates to:
  /// **'Scoring…'**
  String get assessmentScoring;

  /// No description provided for @assessmentScoreAction.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get assessmentScoreAction;

  /// No description provided for @assessmentOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall score'**
  String get assessmentOverallScore;

  /// No description provided for @assessmentAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get assessmentAccuracy;

  /// No description provided for @assessmentCompleteness.
  ///
  /// In en, this message translates to:
  /// **'Completeness'**
  String get assessmentCompleteness;

  /// No description provided for @assessmentFluency.
  ///
  /// In en, this message translates to:
  /// **'Fluency'**
  String get assessmentFluency;

  /// No description provided for @assessmentProsody.
  ///
  /// In en, this message translates to:
  /// **'Prosody'**
  String get assessmentProsody;

  /// No description provided for @assessmentPronunciationAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation analysis'**
  String get assessmentPronunciationAnalysis;

  /// No description provided for @assessmentSyllables.
  ///
  /// In en, this message translates to:
  /// **'Syllables'**
  String get assessmentSyllables;

  /// No description provided for @assessmentPhonemes.
  ///
  /// In en, this message translates to:
  /// **'Phonemes'**
  String get assessmentPhonemes;

  /// No description provided for @assessmentNoRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording file is missing or empty.'**
  String get assessmentNoRecording;

  /// No description provided for @assessmentNoResultSummary.
  ///
  /// In en, this message translates to:
  /// **'No detailed scores are available for this take.'**
  String get assessmentNoResultSummary;

  /// No description provided for @assessmentRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t run assessment: {reason}'**
  String assessmentRunFailed(String reason);

  /// No description provided for @assessmentErrorTypeOmission.
  ///
  /// In en, this message translates to:
  /// **'Omission'**
  String get assessmentErrorTypeOmission;

  /// No description provided for @assessmentErrorTypeInsertion.
  ///
  /// In en, this message translates to:
  /// **'Insertion'**
  String get assessmentErrorTypeInsertion;

  /// No description provided for @assessmentErrorTypeMispronunciation.
  ///
  /// In en, this message translates to:
  /// **'Mispronunciation'**
  String get assessmentErrorTypeMispronunciation;

  /// No description provided for @assessmentErrorTypeUnexpectedBreak.
  ///
  /// In en, this message translates to:
  /// **'Unexpected break'**
  String get assessmentErrorTypeUnexpectedBreak;

  /// No description provided for @assessmentErrorTypeMissingBreak.
  ///
  /// In en, this message translates to:
  /// **'Missing break'**
  String get assessmentErrorTypeMissingBreak;

  /// No description provided for @assessmentErrorTypeMonotone.
  ///
  /// In en, this message translates to:
  /// **'Monotone'**
  String get assessmentErrorTypeMonotone;

  /// No description provided for @assessmentErrorTypeCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get assessmentErrorTypeCorrect;

  /// No description provided for @assessmentErrorExplOmission.
  ///
  /// In en, this message translates to:
  /// **'This word was expected but not detected.'**
  String get assessmentErrorExplOmission;

  /// No description provided for @assessmentErrorExplInsertion.
  ///
  /// In en, this message translates to:
  /// **'Extra word detected that wasn\'t in the reference.'**
  String get assessmentErrorExplInsertion;

  /// No description provided for @assessmentErrorExplMispronunciation.
  ///
  /// In en, this message translates to:
  /// **'This word may have been pronounced incorrectly.'**
  String get assessmentErrorExplMispronunciation;

  /// No description provided for @assessmentErrorExplUnexpectedBreak.
  ///
  /// In en, this message translates to:
  /// **'Unexpected pause detected before this word.'**
  String get assessmentErrorExplUnexpectedBreak;

  /// No description provided for @assessmentErrorExplMissingBreak.
  ///
  /// In en, this message translates to:
  /// **'Expected pause was not detected before this word.'**
  String get assessmentErrorExplMissingBreak;

  /// No description provided for @assessmentErrorExplMonotone.
  ///
  /// In en, this message translates to:
  /// **'Pitch variation was lower than expected.'**
  String get assessmentErrorExplMonotone;

  /// No description provided for @assessmentErrorExplCorrect.
  ///
  /// In en, this message translates to:
  /// **'No issues detected for this word.'**
  String get assessmentErrorExplCorrect;

  /// No description provided for @assessmentEmptyReference.
  ///
  /// In en, this message translates to:
  /// **'Reference text is empty.'**
  String get assessmentEmptyReference;

  /// No description provided for @assessmentInvalidStored.
  ///
  /// In en, this message translates to:
  /// **'Stored assessment data could not be read.'**
  String get assessmentInvalidStored;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @subscriptionViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get subscriptionViewPlans;

  /// No description provided for @settingsSectionAppearanceLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Theme, and the languages you read, learn, and speak'**
  String get settingsSectionAppearanceLanguageHint;

  /// No description provided for @hotkeysSectionKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Reference and customize shortcuts'**
  String get hotkeysSectionKeyboardHint;

  /// No description provided for @settingsSectionDeveloperHint.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics and internal tooling'**
  String get settingsSectionDeveloperHint;

  /// No description provided for @settingsSectionAboutHint.
  ///
  /// In en, this message translates to:
  /// **'Version, licenses, and links'**
  String get settingsSectionAboutHint;

  /// No description provided for @cloudRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh this tab'**
  String get cloudRefreshTooltip;

  /// No description provided for @settingsApiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get settingsApiBaseUrl;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetwork;

  /// No description provided for @homeTodaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get homeTodaysGoal;

  /// No description provided for @homeMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get homeMinutes;

  /// No description provided for @homeGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed! Great job!'**
  String get homeGoalCompleted;

  /// No description provided for @homeGoalAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Keep going!'**
  String get homeGoalAlmostThere;

  /// No description provided for @homeGoalHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway there! You can do it!'**
  String get homeGoalHalfway;

  /// No description provided for @homeGoalGoodStart.
  ///
  /// In en, this message translates to:
  /// **'Good start! Keep practicing!'**
  String get homeGoalGoodStart;

  /// No description provided for @homeGoalJustStarted.
  ///
  /// In en, this message translates to:
  /// **'Just started! Every minute counts!'**
  String get homeGoalJustStarted;

  /// No description provided for @homeGoalStartNow.
  ///
  /// In en, this message translates to:
  /// **'Start your practice now!'**
  String get homeGoalStartNow;

  /// No description provided for @mediaLocateTitle.
  ///
  /// In en, this message translates to:
  /// **'Locate media file'**
  String get mediaLocateTitle;

  /// No description provided for @mediaLocateBody.
  ///
  /// In en, this message translates to:
  /// **'This item was added on another device. Choose the same file on this computer. We verify it matches your library using a secure fingerprint.'**
  String get mediaLocateBody;

  /// No description provided for @mediaLocateChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get mediaLocateChooseFile;

  /// No description provided for @mediaLocateHashMismatch.
  ///
  /// In en, this message translates to:
  /// **'That file does not match this item. Make sure you selected the correct file.'**
  String get mediaLocateHashMismatch;

  /// No description provided for @mediaLocateExpectedSize.
  ///
  /// In en, this message translates to:
  /// **'Expected size: {sizeLabel}'**
  String mediaLocateExpectedSize(String sizeLabel);

  /// No description provided for @mediaLocateSizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Expected size: unknown'**
  String get mediaLocateSizeUnknown;

  /// No description provided for @libraryDeleteMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from library?'**
  String get libraryDeleteMediaTitle;

  /// No description provided for @libraryDeleteMediaMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from this device. This cannot be undone.'**
  String libraryDeleteMediaMessage(String title);

  /// No description provided for @libraryDeleteMediaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete from library'**
  String get libraryDeleteMediaTooltip;

  /// No description provided for @libraryMediaDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed from library.'**
  String get libraryMediaDeleted;

  /// Tooltip/label shown on library items whose crafted audio is synced to cloud storage and playable from any signed-in device.
  ///
  /// In en, this message translates to:
  /// **'Synced to cloud'**
  String get cloudSyncBadgeSynced;

  /// Tooltip/label shown on crafted audios that have been queued for cloud upload but not yet completed (e.g. offline at save time).
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get cloudSyncBadgePending;

  /// Tooltip/label shown on library items that have not been uploaded to cloud storage (e.g. imported user files, pre-feature crafted audios that have not yet been synced).
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get cloudSyncBadgeLocalOnly;

  /// No description provided for @settingsSectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsSectionDeveloper;

  /// No description provided for @settingsAiPlaygroundTileTitle.
  ///
  /// In en, this message translates to:
  /// **'AI playground'**
  String get settingsAiPlaygroundTileTitle;

  /// No description provided for @settingsAiPlaygroundTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise ASR, chat, translation, and dictionary APIs'**
  String get settingsAiPlaygroundTileSubtitle;

  /// No description provided for @aiPlaygroundTitle.
  ///
  /// In en, this message translates to:
  /// **'AI playground'**
  String get aiPlaygroundTitle;

  /// No description provided for @aiPlaygroundIntro.
  ///
  /// In en, this message translates to:
  /// **'Exercise AI modalities with your credentials from Settings → AI providers. Translation and dictionary follow the LLM provider.'**
  String get aiPlaygroundIntro;

  /// No description provided for @aiPlaygroundActiveProviders.
  ///
  /// In en, this message translates to:
  /// **'Active providers'**
  String get aiPlaygroundActiveProviders;

  /// BYOK provider label with preset or vendor detail
  ///
  /// In en, this message translates to:
  /// **'BYOK · {detail}'**
  String aiPlaygroundProviderByokDetail(String detail);

  /// No description provided for @aiPlaygroundPickAudio.
  ///
  /// In en, this message translates to:
  /// **'Pick audio file'**
  String get aiPlaygroundPickAudio;

  /// No description provided for @aiPlaygroundTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get aiPlaygroundTranscribe;

  /// No description provided for @aiPlaygroundChatSystem.
  ///
  /// In en, this message translates to:
  /// **'System (optional)'**
  String get aiPlaygroundChatSystem;

  /// No description provided for @aiPlaygroundChatUser.
  ///
  /// In en, this message translates to:
  /// **'User message'**
  String get aiPlaygroundChatUser;

  /// No description provided for @aiPlaygroundSendChat.
  ///
  /// In en, this message translates to:
  /// **'Send chat'**
  String get aiPlaygroundSendChat;

  /// No description provided for @aiPlaygroundTranslateSource.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get aiPlaygroundTranslateSource;

  /// No description provided for @aiPlaygroundTranslateTarget.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get aiPlaygroundTranslateTarget;

  /// No description provided for @aiPlaygroundTranslateText.
  ///
  /// In en, this message translates to:
  /// **'Text to translate'**
  String get aiPlaygroundTranslateText;

  /// No description provided for @aiPlaygroundTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get aiPlaygroundTranslate;

  /// No description provided for @aiPlaygroundDictWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get aiPlaygroundDictWord;

  /// No description provided for @aiPlaygroundDictSource.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get aiPlaygroundDictSource;

  /// No description provided for @aiPlaygroundDictTarget.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get aiPlaygroundDictTarget;

  /// No description provided for @aiPlaygroundDictLookup.
  ///
  /// In en, this message translates to:
  /// **'Dictionary lookup'**
  String get aiPlaygroundDictLookup;

  /// No description provided for @aiPlaygroundAssessmentReference.
  ///
  /// In en, this message translates to:
  /// **'Reference text (what you spoke)'**
  String get aiPlaygroundAssessmentReference;

  /// No description provided for @aiPlaygroundAssessmentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language (e.g. en, en-US)'**
  String get aiPlaygroundAssessmentLanguage;

  /// No description provided for @aiPlaygroundAssess.
  ///
  /// In en, this message translates to:
  /// **'Run pronunciation assessment'**
  String get aiPlaygroundAssess;

  /// No description provided for @aiPlaygroundAssessmentTtsNote.
  ///
  /// In en, this message translates to:
  /// **'TTS is not wired yet; configure TTS BYOK under AI providers for synthesis. Assessment uses the provider shown above.'**
  String get aiPlaygroundAssessmentTtsNote;

  /// No description provided for @aiPlaygroundOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get aiPlaygroundOutput;

  /// No description provided for @aiPlaygroundClearOutput.
  ///
  /// In en, this message translates to:
  /// **'Clear output'**
  String get aiPlaygroundClearOutput;

  /// No description provided for @aiPlaygroundSectionAsr.
  ///
  /// In en, this message translates to:
  /// **'ASR'**
  String get aiPlaygroundSectionAsr;

  /// No description provided for @aiPlaygroundSectionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get aiPlaygroundSectionChat;

  /// No description provided for @aiPlaygroundSectionTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get aiPlaygroundSectionTranslation;

  /// No description provided for @aiPlaygroundSectionDictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get aiPlaygroundSectionDictionary;

  /// No description provided for @aiPlaygroundSectionTtsAssessment.
  ///
  /// In en, this message translates to:
  /// **'TTS / Assessment'**
  String get aiPlaygroundSectionTtsAssessment;

  /// No description provided for @youtubePasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get youtubePasteFromClipboard;

  /// No description provided for @settingsSectionAppearanceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Language'**
  String get settingsSectionAppearanceLanguage;

  /// No description provided for @settingsAppearanceTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsAppearanceTheme;

  /// No description provided for @settingsAppearanceThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsAppearanceThemeSystem;

  /// No description provided for @settingsAppearanceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsAppearanceThemeLight;

  /// No description provided for @settingsAppearanceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsAppearanceThemeDark;

  /// No description provided for @settingsAppearanceDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settingsAppearanceDisplayLanguage;

  /// No description provided for @settingsAppearanceLearningLanguage.
  ///
  /// In en, this message translates to:
  /// **'Learning language'**
  String get settingsAppearanceLearningLanguage;

  /// No description provided for @settingsAppearanceNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Native language'**
  String get settingsAppearanceNativeLanguage;

  /// No description provided for @settingsLanguageSubtitleDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device until you sign in.'**
  String get settingsLanguageSubtitleDeviceOnly;

  /// No description provided for @settingsNativeLanguageGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only one native language is available for your learning language.'**
  String get settingsNativeLanguageGateSubtitle;

  /// No description provided for @settingsLanguageOptionEnUs.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get settingsLanguageOptionEnUs;

  /// No description provided for @settingsLanguageOptionEnGb.
  ///
  /// In en, this message translates to:
  /// **'English (UK)'**
  String get settingsLanguageOptionEnGb;

  /// No description provided for @settingsLanguageOptionJaJp.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get settingsLanguageOptionJaJp;

  /// No description provided for @settingsLanguageOptionKoKr.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get settingsLanguageOptionKoKr;

  /// No description provided for @settingsLanguageOptionEsEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish (Spain)'**
  String get settingsLanguageOptionEsEs;

  /// No description provided for @settingsLanguageOptionEsMx.
  ///
  /// In en, this message translates to:
  /// **'Spanish (Mexico)'**
  String get settingsLanguageOptionEsMx;

  /// No description provided for @settingsLanguageOptionFrFr.
  ///
  /// In en, this message translates to:
  /// **'French (France)'**
  String get settingsLanguageOptionFrFr;

  /// No description provided for @settingsLanguageOptionFrCa.
  ///
  /// In en, this message translates to:
  /// **'French (Canada)'**
  String get settingsLanguageOptionFrCa;

  /// No description provided for @settingsLanguageOptionZhCn.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get settingsLanguageOptionZhCn;

  /// No description provided for @settingsLanguageOptionNbNo.
  ///
  /// In en, this message translates to:
  /// **'Norwegian (Bokmål)'**
  String get settingsLanguageOptionNbNo;

  /// No description provided for @settingsLearningLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default for Discover and import suggestions.'**
  String get settingsLearningLanguageSubtitle;

  /// No description provided for @settingsLanguagePickerTitleLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning language'**
  String get settingsLanguagePickerTitleLearning;

  /// No description provided for @mediaLanguageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get mediaLanguageUnknown;

  /// No description provided for @mediaLanguagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Content language'**
  String get mediaLanguagePickerTitle;

  /// No description provided for @mediaEditLanguage.
  ///
  /// In en, this message translates to:
  /// **'Edit language'**
  String get mediaEditLanguage;

  /// No description provided for @mediaLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated.'**
  String get mediaLanguageUpdated;

  /// No description provided for @mediaLanguageUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update language.'**
  String get mediaLanguageUpdateFailed;

  /// More menu Media entry and Edit details dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get mediaEditDetails;

  /// Edit details dialog: label of the title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get mediaDetailsTitleLabel;

  /// Edit details dialog: save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mediaDetailsSave;

  /// Notice after saving media details.
  ///
  /// In en, this message translates to:
  /// **'Details updated.'**
  String get mediaDetailsUpdated;

  /// Notice when saving media details fails.
  ///
  /// In en, this message translates to:
  /// **'Could not update details.'**
  String get mediaDetailsUpdateFailed;

  /// Notice when the media was deleted before Edit details opened.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer in your library.'**
  String get mediaDetailsMissing;

  /// No description provided for @assessmentUnavailableLanguage.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation assessment is not available for this language.'**
  String get assessmentUnavailableLanguage;

  /// No description provided for @discoverLanguageFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get discoverLanguageFilterAll;

  /// No description provided for @discoverLanguageFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get discoverLanguageFilterLabel;

  /// No description provided for @settingsLanguagePickerTitleDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settingsLanguagePickerTitleDisplay;

  /// No description provided for @settingsLanguagePickerTitleNative.
  ///
  /// In en, this message translates to:
  /// **'Native language'**
  String get settingsLanguagePickerTitleNative;

  /// No description provided for @settingsKeyboardOpenCheatsheet.
  ///
  /// In en, this message translates to:
  /// **'Open shortcuts cheatsheet'**
  String get settingsKeyboardOpenCheatsheet;

  /// No description provided for @settingsKeyboardOpenCheatsheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and customize every shortcut'**
  String get settingsKeyboardOpenCheatsheetSubtitle;

  /// No description provided for @settingsKeyboardCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize shortcuts'**
  String get settingsKeyboardCustomizeTitle;

  /// No description provided for @hotkeysHelpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts'**
  String get hotkeysHelpSearchHint;

  /// No description provided for @hotkeysHelpEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching shortcuts'**
  String get hotkeysHelpEmpty;

  /// No description provided for @hotkeysHelpCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize shortcuts'**
  String get hotkeysHelpCustomize;

  /// No description provided for @hotkeysSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to change. Press {key} anytime.'**
  String hotkeysSettingsSubtitle(String key);

  /// No description provided for @hotkeysFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter shortcuts'**
  String get hotkeysFilterHint;

  /// No description provided for @hotkeysResetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset this shortcut'**
  String get hotkeysResetTooltip;

  /// No description provided for @hotkeysEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change shortcut'**
  String get hotkeysEditTooltip;

  /// No description provided for @settingsAboutMadeWithCare.
  ///
  /// In en, this message translates to:
  /// **'Made with care for language learners.'**
  String get settingsAboutMadeWithCare;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String settingsAboutVersion(String version);

  /// No description provided for @settingsAboutOpenSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get settingsAboutOpenSourceTitle;

  /// No description provided for @settingsAboutOpenSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View source code on GitHub'**
  String get settingsAboutOpenSourceSubtitle;

  /// No description provided for @settingsDiagnosticsLoggingTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic logging'**
  String get settingsDiagnosticsLoggingTitle;

  /// No description provided for @settingsDiagnosticsLoggingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record extra detail for YouTube, sync, and sign-in issues'**
  String get settingsDiagnosticsLoggingSubtitle;

  /// No description provided for @settingsDiagnosticsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Logs stay on this device until you export them. Tokens and cookies are redacted.'**
  String get settingsDiagnosticsPrivacyNote;

  /// No description provided for @settingsDiagnosticsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export diagnostic report'**
  String get settingsDiagnosticsExportTitle;

  /// No description provided for @settingsDiagnosticsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a zip of recent logs for support'**
  String get settingsDiagnosticsExportSubtitle;

  /// No description provided for @settingsDiagnosticsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic report saved.'**
  String get settingsDiagnosticsExportSuccess;

  /// No description provided for @settingsDiagnosticsExportError.
  ///
  /// In en, this message translates to:
  /// **'Could not export diagnostic report.'**
  String get settingsDiagnosticsExportError;

  /// No description provided for @settingsCheckForUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdatesTitle;

  /// No description provided for @settingsCheckForUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See if a newer direct-download build is available'**
  String get settingsCheckForUpdatesSubtitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBadgeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableBadgeSemantics;

  /// No description provided for @updateMandatoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateMandatoryTitle;

  /// No description provided for @updateVersionLine.
  ///
  /// In en, this message translates to:
  /// **'Installed {current} → {latest}'**
  String updateVersionLine(String current, String latest);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get updateDismiss;

  /// No description provided for @updateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get updateCancel;

  /// No description provided for @updateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get updateRetry;

  /// No description provided for @updatePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing download…'**
  String get updatePreparing;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update… {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying download…'**
  String get updateVerifying;

  /// No description provided for @updateOpeningInstaller.
  ///
  /// In en, this message translates to:
  /// **'Opening installer…'**
  String get updateOpeningInstaller;

  /// No description provided for @updateErrorDownload.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check your connection and try again.'**
  String get updateErrorDownload;

  /// No description provided for @updateErrorChecksum.
  ///
  /// In en, this message translates to:
  /// **'The download was corrupted. Please try again.'**
  String get updateErrorChecksum;

  /// No description provided for @updateErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Install permission was denied. Allow installs from this app in system settings, then retry.'**
  String get updateErrorPermission;

  /// No description provided for @updateErrorAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'An update download is already in progress.'**
  String get updateErrorAlreadyRunning;

  /// No description provided for @updateErrorInstallation.
  ///
  /// In en, this message translates to:
  /// **'Could not open the installer. Please try again.'**
  String get updateErrorInstallation;

  /// No description provided for @updateErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again.'**
  String get updateErrorGeneric;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version.'**
  String get updateUpToDate;

  /// No description provided for @updateCheckOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Check your connection.'**
  String get updateCheckOffline;

  /// No description provided for @updateStoreChannelHint.
  ///
  /// In en, this message translates to:
  /// **'This build is from TestFlight or the Play Store — updates are handled by the store.'**
  String get updateStoreChannelHint;

  /// No description provided for @lookupSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get lookupSheetTitle;

  /// No description provided for @lookupSectionTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get lookupSectionTranslation;

  /// No description provided for @lookupSectionContextualTranslation.
  ///
  /// In en, this message translates to:
  /// **'Contextual translation'**
  String get lookupSectionContextualTranslation;

  /// No description provided for @lookupSectionDictionary.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get lookupSectionDictionary;

  /// No description provided for @lookupErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get lookupErrorRetry;

  /// No description provided for @lookupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No result.'**
  String get lookupEmpty;

  /// No description provided for @lookupLemma.
  ///
  /// In en, this message translates to:
  /// **'Lemma'**
  String get lookupLemma;

  /// No description provided for @lookupClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get lookupClose;

  /// No description provided for @lookupCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get lookupCopy;

  /// No description provided for @lookupCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get lookupCopySuccess;

  /// No description provided for @lookupTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand to load'**
  String get lookupTapToExpand;

  /// No description provided for @lookupSourceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get lookupSourceLanguage;

  /// No description provided for @lookupTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get lookupTargetLanguage;

  /// No description provided for @lookupSwapLanguages.
  ///
  /// In en, this message translates to:
  /// **'Swap languages'**
  String get lookupSwapLanguages;

  /// No description provided for @lookupPickSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose source language'**
  String get lookupPickSourceTitle;

  /// No description provided for @lookupPickTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose target language'**
  String get lookupPickTargetTitle;

  /// No description provided for @lookupRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get lookupRefresh;

  /// No description provided for @lookupSourceResetToLearning.
  ///
  /// In en, this message translates to:
  /// **'Source language reset to learning default'**
  String get lookupSourceResetToLearning;

  /// No description provided for @vocabularyAddToVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Add to Vocabulary'**
  String get vocabularyAddToVocabulary;

  /// No description provided for @vocabularyAddContext.
  ///
  /// In en, this message translates to:
  /// **'Add Context'**
  String get vocabularyAddContext;

  /// No description provided for @vocabularyAlreadyInVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Already in Vocabulary'**
  String get vocabularyAlreadyInVocabulary;

  /// No description provided for @vocabularyAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get vocabularyAdding;

  /// No description provided for @vocabularyRemoving.
  ///
  /// In en, this message translates to:
  /// **'Removing…'**
  String get vocabularyRemoving;

  /// No description provided for @vocabularyConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from vocabulary?'**
  String get vocabularyConfirmDeleteTitle;

  /// No description provided for @vocabularyConfirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the word and all of its contexts.'**
  String get vocabularyConfirmDeleteBody;

  /// No description provided for @vocabularyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vocabularyCancel;

  /// No description provided for @vocabularyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vocabularyDelete;

  /// No description provided for @vocabularyTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabularyTitle;

  /// No description provided for @vocabularyReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get vocabularyReview;

  /// No description provided for @vocabularyAllWords.
  ///
  /// In en, this message translates to:
  /// **'All Words'**
  String get vocabularyAllWords;

  /// No description provided for @vocabularyDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get vocabularyDue;

  /// No description provided for @vocabularyStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get vocabularyStatusNew;

  /// No description provided for @vocabularyStatusLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get vocabularyStatusLearning;

  /// No description provided for @vocabularyStatusReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get vocabularyStatusReviewing;

  /// No description provided for @vocabularyStatusMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get vocabularyStatusMastered;

  /// No description provided for @vocabularyNoWords.
  ///
  /// In en, this message translates to:
  /// **'No words yet'**
  String get vocabularyNoWords;

  /// No description provided for @vocabularyNoWordsDescription.
  ///
  /// In en, this message translates to:
  /// **'Select text in a transcript and choose Add to Vocabulary to start your word book.'**
  String get vocabularyNoWordsDescription;

  /// No description provided for @vocabularyNoDueItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing due right now'**
  String get vocabularyNoDueItems;

  /// No description provided for @vocabularyNoDueItemsDescription.
  ///
  /// In en, this message translates to:
  /// **'You can still start a custom review of all words, by status, language, or a random set.'**
  String get vocabularyNoDueItemsDescription;

  /// No description provided for @vocabularyNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching words'**
  String get vocabularyNoMatches;

  /// No description provided for @vocabularyNoMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear the status and language filters.'**
  String get vocabularyNoMatchesDescription;

  /// No description provided for @vocabularyCustomReview.
  ///
  /// In en, this message translates to:
  /// **'Custom review'**
  String get vocabularyCustomReview;

  /// No description provided for @vocabularySelectReviewItems.
  ///
  /// In en, this message translates to:
  /// **'Choose what to review'**
  String get vocabularySelectReviewItems;

  /// No description provided for @vocabularyReviewDueItems.
  ///
  /// In en, this message translates to:
  /// **'Due items'**
  String get vocabularyReviewDueItems;

  /// No description provided for @vocabularyReviewDueHint.
  ///
  /// In en, this message translates to:
  /// **'Words scheduled for today or earlier'**
  String get vocabularyReviewDueHint;

  /// No description provided for @vocabularyReviewAll.
  ///
  /// In en, this message translates to:
  /// **'All words'**
  String get vocabularyReviewAll;

  /// No description provided for @vocabularyReviewAllHint.
  ///
  /// In en, this message translates to:
  /// **'Review every word in your book'**
  String get vocabularyReviewAllHint;

  /// No description provided for @vocabularyReviewByStatus.
  ///
  /// In en, this message translates to:
  /// **'By status'**
  String get vocabularyReviewByStatus;

  /// No description provided for @vocabularyReviewByStatusHint.
  ///
  /// In en, this message translates to:
  /// **'Focus on new, learning, reviewing, or mastered'**
  String get vocabularyReviewByStatusHint;

  /// No description provided for @vocabularyReviewByLanguage.
  ///
  /// In en, this message translates to:
  /// **'By language'**
  String get vocabularyReviewByLanguage;

  /// No description provided for @vocabularyReviewByLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Limit the session to one source language'**
  String get vocabularyReviewByLanguageHint;

  /// No description provided for @vocabularyReviewRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get vocabularyReviewRandom;

  /// No description provided for @vocabularyReviewRandomHint.
  ///
  /// In en, this message translates to:
  /// **'Shuffle and take a short practice set'**
  String get vocabularyReviewRandomHint;

  /// No description provided for @vocabularyNumberOfWords.
  ///
  /// In en, this message translates to:
  /// **'Number of words'**
  String get vocabularyNumberOfWords;

  /// No description provided for @vocabularyQueueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String vocabularyQueueCount(int count);

  /// No description provided for @vocabularyStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get vocabularyStartReview;

  /// No description provided for @vocabularyEmptyQueue.
  ///
  /// In en, this message translates to:
  /// **'No words match this selection.'**
  String get vocabularyEmptyQueue;

  /// No description provided for @vocabularyExitReview.
  ///
  /// In en, this message translates to:
  /// **'Exit review'**
  String get vocabularyExitReview;

  /// No description provided for @vocabularyDontKnow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Know'**
  String get vocabularyDontKnow;

  /// No description provided for @vocabularyKnow.
  ///
  /// In en, this message translates to:
  /// **'Know'**
  String get vocabularyKnow;

  /// No description provided for @vocabularyKnowWell.
  ///
  /// In en, this message translates to:
  /// **'Know Well'**
  String get vocabularyKnowWell;

  /// No description provided for @vocabularySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get vocabularySkip;

  /// No description provided for @vocabularyUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get vocabularyUndo;

  /// No description provided for @vocabularyProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String vocabularyProgress(int current, int total);

  /// No description provided for @vocabularyReviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Review complete'**
  String get vocabularyReviewComplete;

  /// No description provided for @vocabularyReviewCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Nice work. Your ratings are saved.'**
  String get vocabularyReviewCompleteDescription;

  /// No description provided for @vocabularyDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get vocabularyDone;

  /// No description provided for @vocabularySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search words'**
  String get vocabularySearchPlaceholder;

  /// No description provided for @vocabularyFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get vocabularyFilterStatus;

  /// No description provided for @vocabularyFilterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get vocabularyFilterLanguage;

  /// No description provided for @vocabularyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vocabularyFilterAll;

  /// No description provided for @vocabularyContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get vocabularyContext;

  /// No description provided for @vocabularyDictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get vocabularyDictionary;

  /// No description provided for @vocabularyNoContextAvailable.
  ///
  /// In en, this message translates to:
  /// **'No context available'**
  String get vocabularyNoContextAvailable;

  /// No description provided for @vocabularyDictionaryNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Dictionary not available offline'**
  String get vocabularyDictionaryNotAvailable;

  /// No description provided for @vocabularyOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get vocabularyOverdue;

  /// No description provided for @vocabularyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get vocabularyToday;

  /// No description provided for @vocabularyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get vocabularyTomorrow;

  /// No description provided for @vocabularyInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String vocabularyInDays(int days);

  /// No description provided for @vocabularyFlipHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to flip'**
  String get vocabularyFlipHint;

  /// No description provided for @vocabularyPronounce.
  ///
  /// In en, this message translates to:
  /// **'Pronounce'**
  String get vocabularyPronounce;

  /// No description provided for @vocabularyFlipHintShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Space to flip · 1 / 2 / 3 to rate'**
  String get vocabularyFlipHintShortcuts;

  /// No description provided for @vocabularyPlaySegment.
  ///
  /// In en, this message translates to:
  /// **'Play segment'**
  String get vocabularyPlaySegment;

  /// No description provided for @vocabularyOpenInPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open in player'**
  String get vocabularyOpenInPlayer;

  /// No description provided for @vocabularyOpenInPlayerDescription.
  ///
  /// In en, this message translates to:
  /// **'Opening the player will end this review session. Your ratings so far are saved.'**
  String get vocabularyOpenInPlayerDescription;

  /// No description provided for @vocabularyEchoReading.
  ///
  /// In en, this message translates to:
  /// **'Echo reading'**
  String get vocabularyEchoReading;

  /// No description provided for @vocabularyPracticeDismiss.
  ///
  /// In en, this message translates to:
  /// **'Close practice'**
  String get vocabularyPracticeDismiss;

  /// No description provided for @vocabularyPracticePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get vocabularyPracticePause;

  /// No description provided for @vocabularyPreviousContext.
  ///
  /// In en, this message translates to:
  /// **'Previous context'**
  String get vocabularyPreviousContext;

  /// No description provided for @vocabularyNextContext.
  ///
  /// In en, this message translates to:
  /// **'Next context'**
  String get vocabularyNextContext;

  /// No description provided for @vocabularyContextOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String vocabularyContextOfTotal(int current, int total);

  /// No description provided for @vocabularyContextualTranslation.
  ///
  /// In en, this message translates to:
  /// **'Contextual translation'**
  String get vocabularyContextualTranslation;

  /// No description provided for @vocabularyFetchDictionary.
  ///
  /// In en, this message translates to:
  /// **'Look up dictionary'**
  String get vocabularyFetchDictionary;

  /// No description provided for @vocabularyFetchContextual.
  ///
  /// In en, this message translates to:
  /// **'Translate context'**
  String get vocabularyFetchContextual;

  /// No description provided for @vocabularyFetching.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get vocabularyFetching;

  /// No description provided for @vocabularyAiFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Try again when online.'**
  String get vocabularyAiFetchFailed;

  /// No description provided for @vocabularyMediaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Media actions unavailable for this context'**
  String get vocabularyMediaUnavailable;

  /// No description provided for @vocabularyMediaPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play this segment'**
  String get vocabularyMediaPlayFailed;

  /// No description provided for @vocabularyMediaOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this media'**
  String get vocabularyMediaOpenFailed;

  /// No description provided for @vocabularyConfirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get vocabularyConfirmContinue;

  /// No description provided for @vocabularyUnknownSource.
  ///
  /// In en, this message translates to:
  /// **'Unknown source'**
  String get vocabularyUnknownSource;

  /// No description provided for @vocabularyLocatorLabel.
  ///
  /// In en, this message translates to:
  /// **'{start}s · {duration}s'**
  String vocabularyLocatorLabel(String start, String duration);

  /// No description provided for @vocabularyExportToAnki.
  ///
  /// In en, this message translates to:
  /// **'Export to Anki'**
  String get vocabularyExportToAnki;

  /// No description provided for @vocabularyExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get vocabularyExport;

  /// No description provided for @practicePosterShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share practice poster'**
  String get practicePosterShareTooltip;

  /// No description provided for @practicePosterPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your practice'**
  String get practicePosterPreviewTitle;

  /// No description provided for @practicePosterTagline.
  ///
  /// In en, this message translates to:
  /// **'Shadow reading'**
  String get practicePosterTagline;

  /// No description provided for @practicePosterStatTakes.
  ///
  /// In en, this message translates to:
  /// **'Takes'**
  String get practicePosterStatTakes;

  /// No description provided for @practicePosterStatSentences.
  ///
  /// In en, this message translates to:
  /// **'Sentences'**
  String get practicePosterStatSentences;

  /// No description provided for @practicePosterStatSpoken.
  ///
  /// In en, this message translates to:
  /// **'Spoken'**
  String get practicePosterStatSpoken;

  /// No description provided for @practicePosterQrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan to download SP Player\nplayer.enjoy.bot'**
  String get practicePosterQrHint;

  /// No description provided for @practicePosterShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share poster'**
  String get practicePosterShareAction;

  /// No description provided for @practicePosterShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get practicePosterShareLabel;

  /// No description provided for @practicePosterShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Poster shared.'**
  String get practicePosterShareSuccess;

  /// No description provided for @practicePosterSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Poster saved.'**
  String get practicePosterSaveSuccess;

  /// No description provided for @practicePosterExportError.
  ///
  /// In en, this message translates to:
  /// **'Could not share practice poster.'**
  String get practicePosterExportError;

  /// No description provided for @practicePosterLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load practice data for this video.'**
  String get practicePosterLoadError;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find {uri}.'**
  String notFoundSubtitle(String uri);

  /// No description provided for @notFoundBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get notFoundBackHome;

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Local data needs attention'**
  String get recoveryTitle;

  /// No description provided for @recoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'SP Player could not open its local database. The most common cause is a partial update. Your data is still on disk; you can copy the error before continuing.'**
  String get recoverySubtitle;

  /// No description provided for @recoveryOpenLogs.
  ///
  /// In en, this message translates to:
  /// **'Open logs folder'**
  String get recoveryOpenLogs;

  /// No description provided for @recoveryOpenLogsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the logs folder.'**
  String get recoveryOpenLogsError;

  /// No description provided for @recoveryCopyError.
  ///
  /// In en, this message translates to:
  /// **'Copy error'**
  String get recoveryCopyError;

  /// No description provided for @recoveryCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Error details copied to clipboard.'**
  String get recoveryCopiedToClipboard;

  /// No description provided for @recoveryResetLibrary.
  ///
  /// In en, this message translates to:
  /// **'Reset local library'**
  String get recoveryResetLibrary;

  /// No description provided for @recoveryResetLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe the local database and start fresh. Your cloud library is not affected. A backup of the current state is written to the application support directory before the wipe.'**
  String get recoveryResetLibrarySubtitle;

  /// No description provided for @recoveryResetLibraryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset local library?'**
  String get recoveryResetLibraryConfirmTitle;

  /// No description provided for @recoveryResetLibraryConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your local library, recordings, transcripts, and sync queue. The cloud library (if signed in) is preserved. A backup is written to the application support directory first.'**
  String get recoveryResetLibraryConfirmBody;

  /// No description provided for @recoveryResetLibraryConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Reset everything'**
  String get recoveryResetLibraryConfirmAction;

  /// No description provided for @recoveryResetLibraryBackupError.
  ///
  /// In en, this message translates to:
  /// **'Backup failed — the local database was not wiped. The error has been logged.'**
  String get recoveryResetLibraryBackupError;

  /// No description provided for @recoveryResetLibrarySuccess.
  ///
  /// In en, this message translates to:
  /// **'Local library reset. Reloading your data…'**
  String get recoveryResetLibrarySuccess;

  /// No description provided for @recoveryResetLibraryError.
  ///
  /// In en, this message translates to:
  /// **'Could not reset the local library.'**
  String get recoveryResetLibraryError;

  /// No description provided for @widgetErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get widgetErrorTitle;

  /// No description provided for @widgetErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This screen hit an unexpected error. You can copy the details below and try navigating elsewhere.'**
  String get widgetErrorSubtitle;

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// No description provided for @settingsSearchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching settings'**
  String get settingsSearchNoResultsTitle;

  /// No description provided for @settingsSearchNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different word, or clear your search to browse everything.'**
  String get settingsSearchNoResultsHint;

  /// No description provided for @settingsSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get settingsSearchClear;

  /// No description provided for @settingsSectionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get settingsSectionNeedsAttention;

  /// No description provided for @transcriptBlurDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide transcript text'**
  String get transcriptBlurDisplayTitle;

  /// No description provided for @importCraftFromText.
  ///
  /// In en, this message translates to:
  /// **'Craft…'**
  String get importCraftFromText;

  /// No description provided for @homeCraftAction.
  ///
  /// In en, this message translates to:
  /// **'Craft'**
  String get homeCraftAction;

  /// No description provided for @craftHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get craftHistoryTooltip;

  /// No description provided for @craftHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Craft history'**
  String get craftHistoryTitle;

  /// No description provided for @craftHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Craft items yet'**
  String get craftHistoryEmptyTitle;

  /// No description provided for @craftHistoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create audio in Craft and it will show up here.'**
  String get craftHistoryEmptyHint;

  /// No description provided for @craftHistoryEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Start crafting'**
  String get craftHistoryEmptyAction;

  /// No description provided for @craftHistoryRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove Craft record'**
  String get craftHistoryRemoveTooltip;

  /// No description provided for @craftHistoryRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Craft record?'**
  String get craftHistoryRemoveTitle;

  /// No description provided for @craftHistoryRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove the Craft record for \"{title}\". The practice audio stays in your library.'**
  String craftHistoryRemoveMessage(String title);

  /// No description provided for @craftHistoryRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get craftHistoryRemoveConfirm;

  /// No description provided for @craftHistoryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Craft record removed'**
  String get craftHistoryRemoved;

  /// No description provided for @craftHistoryRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this Craft record.'**
  String get craftHistoryRemoveFailed;

  /// No description provided for @craftEditUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Craft item is no longer available.'**
  String get craftEditUnavailable;

  /// No description provided for @craftSourceLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get craftSourceLanguageLabel;

  /// No description provided for @craftTargetLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning language'**
  String get craftTargetLanguageLabel;

  /// No description provided for @craftTextInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type text…'**
  String get craftTextInputHint;

  /// No description provided for @craftPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get craftPasteFromClipboard;

  /// No description provided for @craftCraftingProgress.
  ///
  /// In en, this message translates to:
  /// **'Crafting your audio…'**
  String get craftCraftingProgress;

  /// No description provided for @craftSameLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Looks like this is already in your learning language.'**
  String get craftSameLanguageHint;

  /// No description provided for @craftOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Craft needs an internet connection.'**
  String get craftOfflineBanner;

  /// No description provided for @craftSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use Craft'**
  String get craftSignInRequired;

  /// No description provided for @craftSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get craftSignInCta;

  /// No description provided for @craftFailureTts.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t turn the text into audio. Check your TTS provider settings or try again.'**
  String get craftFailureTts;

  /// No description provided for @craftFailureTranslate.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t translate the text. Try again or switch to Speak directly.'**
  String get craftFailureTranslate;

  /// No description provided for @craftFailureSave.
  ///
  /// In en, this message translates to:
  /// **'The audio was generated but couldn\'t be saved. Free up space and try again.'**
  String get craftFailureSave;

  /// No description provided for @craftRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get craftRetry;

  /// No description provided for @craftOpenAiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open AI settings'**
  String get craftOpenAiSettings;

  /// No description provided for @libraryProviderCraftBadge.
  ///
  /// In en, this message translates to:
  /// **'Craft'**
  String get libraryProviderCraftBadge;

  /// No description provided for @craftScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Craft'**
  String get craftScreenTitle;

  /// Overline above the Craft page title.
  ///
  /// In en, this message translates to:
  /// **'Practice audio from your own words'**
  String get craftOverline;

  /// No description provided for @craftTranslateTool.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get craftTranslateTool;

  /// No description provided for @craftSynthesizeTool.
  ///
  /// In en, this message translates to:
  /// **'Synthesize'**
  String get craftSynthesizeTool;

  /// No description provided for @craftStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get craftStyleLabel;

  /// No description provided for @craftStyleLiteral.
  ///
  /// In en, this message translates to:
  /// **'Literal'**
  String get craftStyleLiteral;

  /// No description provided for @craftStyleNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get craftStyleNatural;

  /// No description provided for @craftStyleCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get craftStyleCasual;

  /// No description provided for @craftStyleFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get craftStyleFormal;

  /// No description provided for @craftStyleSimplified.
  ///
  /// In en, this message translates to:
  /// **'Simplified'**
  String get craftStyleSimplified;

  /// No description provided for @craftStyleDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get craftStyleDetailed;

  /// No description provided for @craftStyleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get craftStyleCustom;

  /// No description provided for @craftCustomPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your custom translation prompt…'**
  String get craftCustomPromptHint;

  /// No description provided for @craftSwapLanguages.
  ///
  /// In en, this message translates to:
  /// **'Swap languages'**
  String get craftSwapLanguages;

  /// No description provided for @craftTranslateButton.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get craftTranslateButton;

  /// No description provided for @craftReTranslateButton.
  ///
  /// In en, this message translates to:
  /// **'Re-translate'**
  String get craftReTranslateButton;

  /// No description provided for @craftCopyTranslation.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get craftCopyTranslation;

  /// No description provided for @craftCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get craftCopiedToClipboard;

  /// No description provided for @craftTranslatedText.
  ///
  /// In en, this message translates to:
  /// **'Translated text'**
  String get craftTranslatedText;

  /// No description provided for @craftUseTranslatedText.
  ///
  /// In en, this message translates to:
  /// **'Use translated text'**
  String get craftUseTranslatedText;

  /// No description provided for @craftVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get craftVoiceLabel;

  /// No description provided for @craftNoVoicesForLanguage.
  ///
  /// In en, this message translates to:
  /// **'No voices available for this language.'**
  String get craftNoVoicesForLanguage;

  /// No description provided for @craftSynthesizeButton.
  ///
  /// In en, this message translates to:
  /// **'Synthesize'**
  String get craftSynthesizeButton;

  /// No description provided for @craftReSynthesizeButton.
  ///
  /// In en, this message translates to:
  /// **'Re-synthesize'**
  String get craftReSynthesizeButton;

  /// No description provided for @craftSaveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to library'**
  String get craftSaveToLibrary;

  /// No description provided for @craftPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get craftPreviewLabel;

  /// No description provided for @craftSourceText.
  ///
  /// In en, this message translates to:
  /// **'Source text'**
  String get craftSourceText;

  /// No description provided for @craftSynthText.
  ///
  /// In en, this message translates to:
  /// **'Text to synthesize'**
  String get craftSynthText;

  /// No description provided for @craftModeExpress.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get craftModeExpress;

  /// No description provided for @craftModeAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get craftModeAdvanced;

  /// No description provided for @craftStageCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get craftStageCapture;

  /// No description provided for @craftStageRewrite.
  ///
  /// In en, this message translates to:
  /// **'Rewrite'**
  String get craftStageRewrite;

  /// No description provided for @craftStageAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get craftStageAudio;

  /// No description provided for @craftCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Say what\'s on your mind'**
  String get craftCaptureTitle;

  /// No description provided for @craftCaptureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to record. Speak naturally in your language.'**
  String get craftCaptureSubtitle;

  /// No description provided for @craftCaptureStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get craftCaptureStop;

  /// No description provided for @craftCaptureCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get craftCaptureCancel;

  /// No description provided for @craftCaptureTypeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get craftCaptureTypeInstead;

  /// Loading hint under the spinner while ASR runs after capture.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get craftLoadingTranscribing;

  /// Loading hint under the spinner while the LLM rewrite runs.
  ///
  /// In en, this message translates to:
  /// **'Crafting…'**
  String get craftLoadingRewriting;

  /// Loading hint under the spinner while TTS synthesizes audio.
  ///
  /// In en, this message translates to:
  /// **'Generating audio…'**
  String get craftLoadingSynthesizing;

  /// No description provided for @craftRewriteYourWords.
  ///
  /// In en, this message translates to:
  /// **'Your words'**
  String get craftRewriteYourWords;

  /// No description provided for @craftRewriteTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'In your target language'**
  String get craftRewriteTargetLabel;

  /// No description provided for @craftRewriteRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get craftRewriteRegenerate;

  /// No description provided for @craftRewriteReRecord.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get craftRewriteReRecord;

  /// No description provided for @craftRewriteGenerateAudio.
  ///
  /// In en, this message translates to:
  /// **'Generate audio'**
  String get craftRewriteGenerateAudio;

  /// No description provided for @craftAudioPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get craftAudioPreview;

  /// Express audio-stage secondary CTA: save the preview to the library, then return to capture.
  ///
  /// In en, this message translates to:
  /// **'Save & say another'**
  String get craftAudioSaySomethingElse;

  /// Express audio-stage primary CTA: save the preview to the library and open the player.
  ///
  /// In en, this message translates to:
  /// **'Save & practice'**
  String get craftAudioPracticeNow;

  /// Inline reminder on the Express audio stage that TTS preview is in-memory until a save CTA is used.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet. Leave now and this audio is discarded — it won’t appear in history.'**
  String get craftAudioUnsavedHint;

  /// Title for the leave/mode-switch confirm when Craft has an unsaved TTS preview.
  ///
  /// In en, this message translates to:
  /// **'Discard this audio?'**
  String get craftAudioDiscardTitle;

  /// Body for the leave/mode-switch confirm when Craft has an unsaved TTS preview.
  ///
  /// In en, this message translates to:
  /// **'Generated audio is only kept after you save. Leaving now discards it, and credits already used for this preview are not refunded.'**
  String get craftAudioDiscardMessage;

  /// Confirm action that drops the unsaved Craft TTS preview and continues navigation.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get craftAudioDiscardConfirm;

  /// No description provided for @craftSavedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to library'**
  String get craftSavedToLibrary;

  /// Once-per-session snackbar after Craft save that wrote solid synthesis cues; points to STT replace, not re-TTS.
  ///
  /// In en, this message translates to:
  /// **'If line timings look off, regenerate them with speech-to-text from the transcript panel.'**
  String get craftSolidTranscriptSttHint;

  /// No description provided for @craftStyleAuto.
  ///
  /// In en, this message translates to:
  /// **'✨ Auto'**
  String get craftStyleAuto;

  /// No description provided for @craftFailureAsr.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t hear you clearly. Try recording again.'**
  String get craftFailureAsr;

  /// No description provided for @craftFailureEmptyTranscript.
  ///
  /// In en, this message translates to:
  /// **'That was too short. Try speaking a bit longer.'**
  String get craftFailureEmptyTranscript;

  /// No description provided for @craftRecordingMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access denied. Please enable it in settings.'**
  String get craftRecordingMicDenied;

  /// Generic fallback message when loading data fails in an unexpected way.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGenericLoadFailed;

  /// No description provided for @subscriptionViewPlansAndPackages.
  ///
  /// In en, this message translates to:
  /// **'View plans & packages'**
  String get subscriptionViewPlansAndPackages;

  /// No description provided for @byokProviderBillingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your AI provider declined this request. Please check your provider\'s billing or plan.'**
  String get byokProviderBillingMessage;

  /// No description provided for @pronouncePlay.
  ///
  /// In en, this message translates to:
  /// **'Play pronunciation'**
  String get pronouncePlay;

  /// No description provided for @pronounceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop pronunciation'**
  String get pronounceStop;

  /// No description provided for @pronounceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading pronunciation…'**
  String get pronounceLoading;

  /// No description provided for @pronounceUnavailableLanguage.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation unavailable for this language'**
  String get pronounceUnavailableLanguage;

  /// No description provided for @pronounceTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text is too long to pronounce'**
  String get pronounceTextTooLong;

  /// No description provided for @pronounceFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play pronunciation'**
  String get pronounceFailed;

  /// Tooltip for playing the full assessment take from the result dialog.
  ///
  /// In en, this message translates to:
  /// **'Play my recording'**
  String get assessmentPlayMyRecording;

  /// Tooltip while the assessment take is playing.
  ///
  /// In en, this message translates to:
  /// **'Stop my recording'**
  String get assessmentStopMyRecording;

  /// Tooltip when the take path is missing or the file cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Recording file is unavailable'**
  String get assessmentRecordingUnavailable;

  /// Tooltip for playing the timed word clip from the learner take.
  ///
  /// In en, this message translates to:
  /// **'Play my recording of this word'**
  String get assessmentPlayMyClip;

  /// Tooltip while the word clip is playing.
  ///
  /// In en, this message translates to:
  /// **'Stop my recording of this word'**
  String get assessmentStopMyClip;

  /// Tooltip when word timing is missing, omitted, or zero duration.
  ///
  /// In en, this message translates to:
  /// **'No recording clip for this word'**
  String get assessmentClipUnavailable;

  /// No description provided for @onboardingTipSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingTipSkip;

  /// No description provided for @onboardingTipHomeImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import media'**
  String get onboardingTipHomeImportTitle;

  /// No description provided for @onboardingTipHomeImportBody.
  ///
  /// In en, this message translates to:
  /// **'Bring in a local file or YouTube video to practice with.'**
  String get onboardingTipHomeImportBody;

  /// No description provided for @onboardingTipHomeCraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Craft'**
  String get onboardingTipHomeCraftTitle;

  /// No description provided for @onboardingTipHomeCraftBody.
  ///
  /// In en, this message translates to:
  /// **'Create practice audio from text when you do not have a video yet.'**
  String get onboardingTipHomeCraftBody;

  /// No description provided for @onboardingTipEmptyTranscriptLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a transcript'**
  String get onboardingTipEmptyTranscriptLocalTitle;

  /// No description provided for @onboardingTipEmptyTranscriptLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Extract subtitles from the file or import a subtitle file so you can practice line by line.'**
  String get onboardingTipEmptyTranscriptLocalBody;

  /// No description provided for @onboardingTipEmptyTranscriptYoutubeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch transcript'**
  String get onboardingTipEmptyTranscriptYoutubeTitle;

  /// No description provided for @onboardingTipEmptyTranscriptYoutubeBody.
  ///
  /// In en, this message translates to:
  /// **'Pull captions for this YouTube video from the cloud to unlock practice.'**
  String get onboardingTipEmptyTranscriptYoutubeBody;

  /// No description provided for @onboardingTipEchoTitle.
  ///
  /// In en, this message translates to:
  /// **'Echo mode'**
  String get onboardingTipEchoTitle;

  /// No description provided for @onboardingTipEchoBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Echo to shadow each line and practice speaking along with the audio.'**
  String get onboardingTipEchoBody;

  /// No description provided for @onboardingTipRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record yourself'**
  String get onboardingTipRecordTitle;

  /// No description provided for @onboardingTipRecordBody.
  ///
  /// In en, this message translates to:
  /// **'Record your voice on a line, then compare it with the original.'**
  String get onboardingTipRecordBody;

  /// No description provided for @onboardingTipAssessTitle.
  ///
  /// In en, this message translates to:
  /// **'Assess pronunciation'**
  String get onboardingTipAssessTitle;

  /// No description provided for @onboardingTipAssessBody.
  ///
  /// In en, this message translates to:
  /// **'After you record, check pronunciation feedback for that take.'**
  String get onboardingTipAssessBody;

  /// No description provided for @settingsResetProductTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset product tips'**
  String get settingsResetProductTipsTitle;

  /// No description provided for @settingsResetProductTipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show Home and Player tips again as if you were new.'**
  String get settingsResetProductTipsSubtitle;

  /// No description provided for @settingsResetProductTipsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset product tips?'**
  String get settingsResetProductTipsConfirmTitle;

  /// No description provided for @settingsResetProductTipsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Tips for Craft, Import, transcripts, and practice will show again. Your library and account stay unchanged.'**
  String get settingsResetProductTipsConfirmBody;

  /// No description provided for @settingsResetProductTipsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Reset tips'**
  String get settingsResetProductTipsConfirmAction;

  /// No description provided for @settingsResetProductTipsDone.
  ///
  /// In en, this message translates to:
  /// **'Product tips reset'**
  String get settingsResetProductTipsDone;

  /// No description provided for @settingsAnalyticsCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics'**
  String get settingsAnalyticsCaptureTitle;

  /// No description provided for @settingsAnalyticsCaptureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage data to help improve Enjoy. Never includes your media, transcripts, or notes.'**
  String get settingsAnalyticsCaptureSubtitle;

  /// No description provided for @transcriptEmptyFetchYoutube.
  ///
  /// In en, this message translates to:
  /// **'Fetch transcript'**
  String get transcriptEmptyFetchYoutube;

  /// Caption under the minutes practiced inside the Home goal ring.
  ///
  /// In en, this message translates to:
  /// **'of {minutes} min'**
  String homeGoalOfMinutes(int minutes);

  /// Home goal card summary while the goal is not met.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} min · {left} min to go'**
  String homeGoalProgressRemaining(int done, int goal, int left);

  /// Home goal card summary once the goal is met.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} min'**
  String homeGoalProgressDone(int done, int goal);

  /// Button on the Home Continue practicing card.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinueAction;

  /// Link beside the Home Recent media heading.
  ///
  /// In en, this message translates to:
  /// **'Open library'**
  String get homeOpenLibrary;

  /// Continue practicing meta: the transcript line to resume at.
  ///
  /// In en, this message translates to:
  /// **'line {line} of {total}'**
  String homeContinueLine(int line, int total);

  /// Continue practicing meta when the session was in Echo.
  ///
  /// In en, this message translates to:
  /// **'Echo on'**
  String get homeContinueEchoOn;

  /// Media tile meta: added or opened today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get mediaRelativeToday;

  /// Media tile meta: added or opened yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get mediaRelativeYesterday;

  /// Library tile meta: when the item was added (date is today / yesterday / a short date).
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String libraryTileAdded(String date);

  /// Overline above the Vocabulary page title.
  ///
  /// In en, this message translates to:
  /// **'Your word book'**
  String get vocabularyOverline;

  /// Vocabulary header action that starts a due-items review.
  ///
  /// In en, this message translates to:
  /// **'Review {count} due'**
  String vocabularyReviewDueAction(int count);

  /// Unit after the due count on the Vocabulary due card.
  ///
  /// In en, this message translates to:
  /// **'due today'**
  String get vocabularyDueToday;

  /// Vocabulary due card caption with the estimated review time.
  ///
  /// In en, this message translates to:
  /// **'Words scheduled for today or earlier · about {minutes} min'**
  String vocabularyDueEstimate(int minutes);

  /// Caption on the Vocabulary status breakdown card.
  ///
  /// In en, this message translates to:
  /// **'by status'**
  String get vocabularyByStatus;

  /// Headline of the Vocabulary Review tab due card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} word is waiting} other{{count} words are waiting}}'**
  String vocabularyDueWaiting(int count);

  /// Body of the Vocabulary Review tab due card.
  ///
  /// In en, this message translates to:
  /// **'Words scheduled for today or earlier. Space flips a card; 1, 2 and 3 rate it.'**
  String get vocabularyDueReviewBody;

  /// Vocabulary filter button: the filter name and its current value.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String vocabularyFilterValue(String label, String value);

  /// Stepper button: fewer words.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get vocabularyFewer;

  /// Stepper button: more words.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get vocabularyMore;

  /// Overline above the Library title for local media.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get libraryOverlineLocal;

  /// Overline above the Library title for cloud media.
  ///
  /// In en, this message translates to:
  /// **'Saved to your Enjoy account'**
  String get libraryOverlineCloud;

  /// Line above library results while a search is active.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 match for “{query}”} other{{count} matches for “{query}”}}'**
  String librarySearchResults(int count, String query);

  /// Overline above the Discover title.
  ///
  /// In en, this message translates to:
  /// **'YouTube channels you follow'**
  String get discoverOverline;

  /// Heading above the Discover feed.
  ///
  /// In en, this message translates to:
  /// **'Recent uploads'**
  String get discoverRecentUploads;

  /// Caption beside Recent uploads: how fresh the feed is.
  ///
  /// In en, this message translates to:
  /// **'Updated {age}'**
  String discoverUpdatedAgo(String age);

  /// Compact age of a feed entry or refresh.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String discoverHoursAgo(int count);

  /// Compact age of a feed entry or refresh.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String discoverDaysAgo(int count);

  /// Compact age of a feed entry or refresh.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String discoverMinutesAgo(int count);

  /// Age of a feed entry or refresh under a minute old.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get discoverJustNow;

  /// Discover feed tile action button.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get discoverAddToLibraryAction;

  /// Trailing tile in the Discover channel strip; opens manage / subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get discoverStripSubscribe;

  /// Short label for the Echo mode segment in the player top bar.
  ///
  /// In en, this message translates to:
  /// **'Echo'**
  String get playerEchoShort;

  /// No description provided for @playerLineOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Line {line} of {total}'**
  String playerLineOfTotal(Object line, Object total);

  /// No description provided for @assessmentMarginOverline.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get assessmentMarginOverline;

  /// Assessment score level (91–100).
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get assessmentLevelExcellent;

  /// Assessment score level (81–90).
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get assessmentLevelGood;

  /// Assessment score level (61–80).
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get assessmentLevelFair;

  /// Assessment score level (below 61).
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get assessmentLevelPoor;

  /// Top-bar button that opens the player's More menu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get playerMore;

  /// No description provided for @playerMoreDescEditTranscript.
  ///
  /// In en, this message translates to:
  /// **'Edit the text and timing of the current transcript in the editor'**
  String get playerMoreDescEditTranscript;

  /// No description provided for @playerMoreDescAddSubtitleFile.
  ///
  /// In en, this message translates to:
  /// **'Pick a .srt / .vtt subtitle file from your computer and import it as a new track'**
  String get playerMoreDescAddSubtitleFile;

  /// No description provided for @playerMoreDescEmbeddedSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Extract subtitle tracks embedded inside the video file (MKV/MP4) - no speech recognition needed'**
  String get playerMoreDescEmbeddedSubtitles;

  /// No description provided for @playerMoreDescAiTranscript.
  ///
  /// In en, this message translates to:
  /// **'Generate or regenerate subtitles with local speech recognition; old videos get the latest timing calibration by re-transcribing'**
  String get playerMoreDescAiTranscript;

  /// No description provided for @playerMoreDescWordTimings.
  ///
  /// In en, this message translates to:
  /// **'Add word-by-word timing and phonetics, for karaoke-style highlighting and shadowing practice'**
  String get playerMoreDescWordTimings;

  /// No description provided for @playerMoreDescRefreshFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Re-fetch transcripts from the cloud (YouTube official captions, or subtitles synced while signed in)'**
  String get playerMoreDescRefreshFromCloud;

  /// No description provided for @playerMoreDescDownloadTranscript.
  ///
  /// In en, this message translates to:
  /// **'Export the current transcript as a .srt subtitle file on your computer'**
  String get playerMoreDescDownloadTranscript;

  /// No description provided for @playerMoreDescEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit the title, cover and other details of this video'**
  String get playerMoreDescEditDetails;

  /// No description provided for @playerMoreDescExportLoopClip.
  ///
  /// In en, this message translates to:
  /// **'Save the active Echo loop as a separate video clip (enabled while a loop is active)'**
  String get playerMoreDescExportLoopClip;

  /// Section heading in the player's More menu and the phone Subtitles sheet.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get playerMoreTranscriptSection;

  /// More menu: import a subtitle file for this media.
  ///
  /// In en, this message translates to:
  /// **'Add a subtitle file…'**
  String get playerMoreAddSubtitleFile;

  /// More menu: extract subtitle tracks embedded in the video file.
  ///
  /// In en, this message translates to:
  /// **'Use embedded subtitles…'**
  String get playerMoreUseEmbeddedSubtitles;

  /// More menu: start AI transcription when no AI track exists.
  ///
  /// In en, this message translates to:
  /// **'Create an AI transcript…'**
  String get playerMoreCreateAiTranscript;

  /// More menu: run AI transcription again.
  ///
  /// In en, this message translates to:
  /// **'Transcribe again…'**
  String get playerMoreTranscribeAgain;

  /// More menu: generate word timings and pronunciation for a local file.
  ///
  /// In en, this message translates to:
  /// **'Add word timings & IPA'**
  String get playerMoreAddWordTimings;

  /// More menu: generate pronunciation for a streamed item (no word timings).
  ///
  /// In en, this message translates to:
  /// **'Add pronunciation (IPA)'**
  String get playerMoreAddIpa;

  /// More menu: fetch transcripts from the cloud again.
  ///
  /// In en, this message translates to:
  /// **'Refresh from cloud'**
  String get playerMoreRefreshFromCloud;

  /// More menu: open the transcript editor for the active transcript.
  ///
  /// In en, this message translates to:
  /// **'Edit transcript'**
  String get playerMoreEditTranscript;

  /// Title of the transcript editor page.
  ///
  /// In en, this message translates to:
  /// **'Edit transcript'**
  String get transcriptEditorTitle;

  /// Transcript editor: save the edited lines.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transcriptEditorSave;

  /// Notice after the transcript editor saved.
  ///
  /// In en, this message translates to:
  /// **'Transcript updated'**
  String get transcriptEditorSaved;

  /// Notice when the transcript editor could not save.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the transcript. Please try again.'**
  String get transcriptEditorSaveFailed;

  /// Transcript editor: a timing field is not a valid seconds value.
  ///
  /// In en, this message translates to:
  /// **'Start and duration must be times in seconds, like 1.25.'**
  String get transcriptEditorInvalidTiming;

  /// Transcript editor: shown when the media has no transcript row.
  ///
  /// In en, this message translates to:
  /// **'This media has no transcript to edit.'**
  String get transcriptEditorEmpty;

  /// Transcript editor: shown when the transcript row exists but has no cue lines.
  ///
  /// In en, this message translates to:
  /// **'This transcript has no lines to edit.'**
  String get transcriptEditorNoCues;

  /// Transcript editor: title of the confirm dialog when leaving with unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved edits?'**
  String get transcriptEditorDiscardTitle;

  /// Transcript editor: body of the confirm dialog when leaving with unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this transcript have not been saved.'**
  String get transcriptEditorDiscardMessage;

  /// Transcript editor: confirm button of the discard dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get transcriptEditorDiscardConfirm;

  /// Transcript editor: per-line heading with the cue number.
  ///
  /// In en, this message translates to:
  /// **'Line {index}'**
  String transcriptEditorLineLabel(int index);

  /// Transcript editor: line start time field.
  ///
  /// In en, this message translates to:
  /// **'Start (seconds)'**
  String get transcriptEditorFieldStart;

  /// Transcript editor: line duration field.
  ///
  /// In en, this message translates to:
  /// **'Duration (seconds)'**
  String get transcriptEditorFieldDuration;

  /// More menu: save the active transcript as an SRT or VTT subtitle file.
  ///
  /// In en, this message translates to:
  /// **'Download transcript…'**
  String get playerMoreDownloadTranscript;

  /// More menu: translate every line of the active transcript in merged batches (ADR-0106).
  ///
  /// In en, this message translates to:
  /// **'Translate full video'**
  String get playerMoreTranslateAll;

  /// Translation banner call-to-action when nothing is translated yet.
  ///
  /// In en, this message translates to:
  /// **'Translate full video'**
  String get fullTranslateBannerCta;

  /// Translation banner resume action after a stop or failure.
  ///
  /// In en, this message translates to:
  /// **'Continue translation'**
  String get fullTranslateBannerContinue;

  /// Translation banner title while batches are in flight.
  ///
  /// In en, this message translates to:
  /// **'Translating {translated} / {total} lines'**
  String fullTranslateBannerRunningTitle(int translated, int total);

  /// Translation banner idle readout of persisted translations.
  ///
  /// In en, this message translates to:
  /// **'Cached {translated} / {total} lines'**
  String fullTranslateBannerCachedProgress(int translated, int total);

  /// Translation banner meta: furthest translated playback minute.
  ///
  /// In en, this message translates to:
  /// **'translated up to minute {minutes}'**
  String fullTranslateBannerReachedMinute(int minutes);

  /// Translation banner message when some batches failed.
  ///
  /// In en, this message translates to:
  /// **'{failed} lines failed — continue translation to retry'**
  String fullTranslateBannerPausedFailure(int failed);

  /// Translation banner message after a manual stop.
  ///
  /// In en, this message translates to:
  /// **'Stopped — continue translation to resume'**
  String get fullTranslateBannerPausedStopped;

  /// Translation banner blocked message for guard failures (no native language, no primary track, same language, signed out).
  ///
  /// In en, this message translates to:
  /// **'Cannot start translation — check the transcript and language settings'**
  String get fullTranslateBannerErrorGeneric;

  /// Translation banner blocked message when no LLM is configured.
  ///
  /// In en, this message translates to:
  /// **'Configure a language model in Settings → AI first'**
  String get fullTranslateBannerErrorConfig;

  /// Export gate: bilingual SRT export requires the full-video translation to be complete.
  ///
  /// In en, this message translates to:
  /// **'{remaining} lines are not translated yet — run \'Translate full video\' first'**
  String fullTranslateExportIncomplete(int remaining);

  /// Media section heading in the player's More menu.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get playerMoreMediaSection;

  /// More menu Media: open the Edit details dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get playerMoreEditDetails;

  /// More menu: save the active Echo loop's audio/video range as a media file.
  ///
  /// In en, this message translates to:
  /// **'Export the loop as a clip…'**
  String get playerMoreExportLoopClip;

  /// Notice after the Echo loop clip was saved or shared.
  ///
  /// In en, this message translates to:
  /// **'Loop clip exported'**
  String get playerMoreExportLoopClipSuccess;

  /// Notice when the Echo loop clip export failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the loop clip'**
  String get playerMoreExportLoopClipFailed;

  /// Notice when clip export cannot run because no FFmpeg runtime was found.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg isn\'t available on this device'**
  String get playerMoreExportLoopClipFfmpegMissing;

  /// More menu: open the keyboard shortcuts cheatsheet.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get playerMoreKeyboardShortcuts;

  /// Title of the Subtitles & display panel.
  ///
  /// In en, this message translates to:
  /// **'Subtitles & display'**
  String get subtitlesPanelTitle;

  /// Section heading for the track rows in the Subtitles & display panel.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitlesSectionSubtitles;

  /// Section heading for the display options in the Subtitles & display panel.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get subtitlesSectionDisplay;

  /// Accessible label for the Book / Clean typeface choice.
  ///
  /// In en, this message translates to:
  /// **'Transcript type'**
  String get transcriptTypefaceLabel;

  /// Serif transcript typeface option.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get transcriptTypefaceBook;

  /// Sans-serif transcript typeface option.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get transcriptTypefaceClean;

  /// Display switch: underline the word being spoken.
  ///
  /// In en, this message translates to:
  /// **'Highlight the spoken word'**
  String get subtitlesHighlightSpokenWord;

  /// Hint under the highlight switch when available.
  ///
  /// In en, this message translates to:
  /// **'Underline each word as it is said.'**
  String get subtitlesHighlightSpokenWordHint;

  /// Display switch: show IPA under each word.
  ///
  /// In en, this message translates to:
  /// **'IPA under words'**
  String get subtitlesIpaUnderWords;

  /// Label for the on-video caption overlay display-mode picker.
  ///
  /// In en, this message translates to:
  /// **'Caption below video'**
  String get subtitlesCaptionOverlay;

  /// Explanation of the on-video caption overlay.
  ///
  /// In en, this message translates to:
  /// **'Show the active line over the bottom of the video, transparent background.'**
  String get subtitlesCaptionOverlayHint;

  /// Caption overlay mode: hidden.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get subtitlesCaptionModeOff;

  /// Caption overlay mode: original text only.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get subtitlesCaptionModeOriginal;

  /// Caption overlay mode: translation only.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get subtitlesCaptionModeTranslation;

  /// Caption overlay mode: original + translation.
  ///
  /// In en, this message translates to:
  /// **'Bilingual'**
  String get subtitlesCaptionModeBoth;

  /// Hint under the IPA switch when available.
  ///
  /// In en, this message translates to:
  /// **'Tap a word to hear it.'**
  String get subtitlesIpaUnderWordsHint;

  /// Hint under a disabled display switch on desktop.
  ///
  /// In en, this message translates to:
  /// **'Add word timings & IPA first (··· More).'**
  String get subtitlesNeedsWordTimingsMore;

  /// Hint under a disabled display switch in the phone sheet.
  ///
  /// In en, this message translates to:
  /// **'Add word timings & IPA first (below).'**
  String get subtitlesNeedsWordTimingsBelow;

  /// Footer of the desktop Subtitles & display panel.
  ///
  /// In en, this message translates to:
  /// **'Add or replace the transcript from ··· More.'**
  String get subtitlesManageFromMore;

  /// Progress card title while word timings generate.
  ///
  /// In en, this message translates to:
  /// **'Generating word timings and pronunciation'**
  String get transcriptEnrichRunningOwned;

  /// Progress card title while pronunciation generates for a streamed item.
  ///
  /// In en, this message translates to:
  /// **'Generating pronunciation'**
  String get transcriptEnrichRunningYoutube;

  /// Top-bar lens segment: listen with the transcript hidden (H).
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get playerDictateShort;

  /// Hint pill over the transcript in the Dictate lens (pointer devices).
  ///
  /// In en, this message translates to:
  /// **'Dictate · listen, then hover a line to peek'**
  String get playerDictateHintHover;

  /// Hint pill over the transcript in the Dictate lens (touch).
  ///
  /// In en, this message translates to:
  /// **'Press and hold to show'**
  String get playerDictateHintHold;

  /// Dock readout under the line position in Listen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No lines practised yet} =1{1 line practised} other{{count} lines practised}}'**
  String playerDockPractisedLines(int count);

  /// Dock readout in Echo with a one-line loop.
  ///
  /// In en, this message translates to:
  /// **'Looping line {line}'**
  String playerDockLoopingLine(int line);

  /// Dock readout in Echo with a multi-line loop.
  ///
  /// In en, this message translates to:
  /// **'Looping lines {start}–{end}'**
  String playerDockLoopingLines(int start, int end);

  /// Dock hint under the Echo readout; seconds is the loop length.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s · + adds a line, − drops one'**
  String playerDockLoopHint(String seconds);

  /// Dock hint while a take records.
  ///
  /// In en, this message translates to:
  /// **'Recording · {elapsed}s of {total}s'**
  String playerDockRecordingProgress(String elapsed, String total);

  /// Dock readout in the Dictate lens.
  ///
  /// In en, this message translates to:
  /// **'Dictating line {line}'**
  String playerDockDictatingLine(int line);

  /// Dock hint in the Dictate lens (pointer devices).
  ///
  /// In en, this message translates to:
  /// **'Hover a line to peek'**
  String get playerDockDictateHover;

  /// Dock hint in the Dictate lens (touch).
  ///
  /// In en, this message translates to:
  /// **'Hold to show'**
  String get playerDockDictateHold;

  /// Repeat button tooltip when repeat is off.
  ///
  /// In en, this message translates to:
  /// **'Repeat: off'**
  String get playerRepeatOff;

  /// Repeat button tooltip when the whole item repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeat this item'**
  String get playerRepeatItem;

  /// Repeat button tooltip when the echo segment repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeat the echo loop'**
  String get playerRepeatLoop;

  /// Tooltip on the player margin's close button.
  ///
  /// In en, this message translates to:
  /// **'{close} · Esc'**
  String playerMarginCloseTooltip(String close);

  /// A take's name in the takes row and list.
  ///
  /// In en, this message translates to:
  /// **'Take {number}'**
  String takeNumbered(int number);

  /// Opens the list of takes for the loop.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 take} other{{count} takes}}'**
  String takesCount(int count);

  /// Under an unscored take (pointer devices).
  ///
  /// In en, this message translates to:
  /// **'Not scored yet · click to score'**
  String get takeNotScoredClick;

  /// Under an unscored take (touch).
  ///
  /// In en, this message translates to:
  /// **'Not scored yet · tap to score'**
  String get takeNotScoredTap;

  /// Heading of the takes list (pointer devices).
  ///
  /// In en, this message translates to:
  /// **'Your takes · click to play'**
  String get takesMarginTitleClick;

  /// Heading of the takes list (touch).
  ///
  /// In en, this message translates to:
  /// **'Your takes · tap to play'**
  String get takesMarginTitleTap;

  /// Takes list toggle for the pitch contour (P).
  ///
  /// In en, this message translates to:
  /// **'Pitch contour on the loop'**
  String get takesPitchOnLoop;

  /// Context block in the lookup sheet: the line the word came from (audio).
  ///
  /// In en, this message translates to:
  /// **'In this audio · {time}'**
  String lookupInThisAudio(String time);

  /// Context block in the lookup sheet: the line the word came from (video).
  ///
  /// In en, this message translates to:
  /// **'In this video · {time}'**
  String lookupInThisVideo(String time);

  /// Assessment margin heading for a numbered take.
  ///
  /// In en, this message translates to:
  /// **'Take {number} · Assessment'**
  String takeAssessmentTitle(int number);

  /// No description provided for @settingsSectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsSectionNetwork;

  /// No description provided for @settingsSectionNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'Proxy and VPN routing'**
  String get settingsSectionNetworkHint;

  /// No description provided for @settingsNetworkProxyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy mode'**
  String get settingsNetworkProxyModeTitle;

  /// No description provided for @settingsNetworkProxyModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsNetworkProxyModeSystem;

  /// No description provided for @settingsNetworkProxyModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get settingsNetworkProxyModeManual;

  /// No description provided for @settingsNetworkProxyModeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get settingsNetworkProxyModeDirect;

  /// No description provided for @settingsNetworkProxyModeHint.
  ///
  /// In en, this message translates to:
  /// **'System follows your OS proxy (Clash, sing-box and similar). Manual uses the address below. Direct bypasses every proxy.'**
  String get settingsNetworkProxyModeHint;

  /// No description provided for @settingsNetworkProxyUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Proxy address'**
  String get settingsNetworkProxyUrlLabel;

  /// No description provided for @settingsNetworkProxyUrlHint.
  ///
  /// In en, this message translates to:
  /// **'127.0.0.1:7890 or http://host:port'**
  String get settingsNetworkProxyUrlHint;

  /// No description provided for @settingsNetworkProxyUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an HTTP proxy as host:port. SOCKS proxies are not supported.'**
  String get settingsNetworkProxyUrlInvalid;

  /// No description provided for @settingsNetworkProxySave.
  ///
  /// In en, this message translates to:
  /// **'Save proxy'**
  String get settingsNetworkProxySave;

  /// No description provided for @settingsNetworkProxySaved.
  ///
  /// In en, this message translates to:
  /// **'Proxy settings saved.'**
  String get settingsNetworkProxySaved;

  /// No description provided for @settingsNetworkEffectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Effective proxy'**
  String get settingsNetworkEffectiveTitle;

  /// No description provided for @settingsNetworkEffectiveDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct (no proxy)'**
  String get settingsNetworkEffectiveDirect;

  /// No description provided for @settingsNetworkEffectiveProxy.
  ///
  /// In en, this message translates to:
  /// **'{endpoint} ({source})'**
  String settingsNetworkEffectiveProxy(String endpoint, String source);

  /// No description provided for @settingsNetworkTestButton.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsNetworkTestButton;

  /// No description provided for @settingsNetworkTestRunning.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get settingsNetworkTestRunning;

  /// No description provided for @settingsNetworkTestYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get settingsNetworkTestYoutube;

  /// No description provided for @settingsNetworkTestOk.
  ///
  /// In en, this message translates to:
  /// **'{label}: reachable in {ms} ms via {route}'**
  String settingsNetworkTestOk(String label, int ms, String route);

  /// No description provided for @settingsNetworkTestFail.
  ///
  /// In en, this message translates to:
  /// **'{label}: failed via {route} ({error})'**
  String settingsNetworkTestFail(String label, String route, String error);

  /// No description provided for @playerDictationVoiceMode.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get playerDictationVoiceMode;

  /// No description provided for @playerDictationTextMode.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get playerDictationTextMode;

  /// Voice-mode hint in the Dictation panel (touch platforms have no keyboard shortcuts).
  ///
  /// In en, this message translates to:
  /// **'Listen and retell by voice. Tap Record when ready.'**
  String get playerDictationVoiceHint;

  /// Voice-mode hint in the Dictation panel on desktop, where the R hotkey works.
  ///
  /// In en, this message translates to:
  /// **'Listen and retell by voice. Tap Record or press R when ready.'**
  String get playerDictationVoiceHintHotkey;

  /// No description provided for @playerDictationTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type what you hear...'**
  String get playerDictationTextPlaceholder;

  /// No description provided for @playerDictationWordCountProgress.
  ///
  /// In en, this message translates to:
  /// **'{typed} of about {total} words'**
  String playerDictationWordCountProgress(int typed, int total);

  /// No description provided for @playerDictationCheckAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get playerDictationCheckAnswer;

  /// No description provided for @playerDictationCheckingVoice.
  ///
  /// In en, this message translates to:
  /// **'Transcribing speech...'**
  String get playerDictationCheckingVoice;

  /// No description provided for @playerDictationTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get playerDictationTryAgain;

  /// No description provided for @playerDictationNextLine.
  ///
  /// In en, this message translates to:
  /// **'Next line'**
  String get playerDictationNextLine;

  /// No description provided for @playerDictationRetryTranscription.
  ///
  /// In en, this message translates to:
  /// **'Retry transcription'**
  String get playerDictationRetryTranscription;

  /// No description provided for @playerDictationLegendCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get playerDictationLegendCorrect;

  /// No description provided for @playerDictationLegendMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get playerDictationLegendMissed;

  /// No description provided for @playerDictationLegendExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get playerDictationLegendExtra;

  /// No description provided for @playerDictationStatsCorrect.
  ///
  /// In en, this message translates to:
  /// **'{count} correct'**
  String playerDictationStatsCorrect(int count);

  /// No description provided for @playerDictationStatsMissed.
  ///
  /// In en, this message translates to:
  /// **'{count} missed'**
  String playerDictationStatsMissed(int count);

  /// No description provided for @playerDictationStatsExtra.
  ///
  /// In en, this message translates to:
  /// **'{count} extra'**
  String playerDictationStatsExtra(int count);

  /// No description provided for @playerDictationPreviousAttempts.
  ///
  /// In en, this message translates to:
  /// **'Previous dictations ({count})'**
  String playerDictationPreviousAttempts(int count);

  /// No description provided for @playerDictationAttemptAccuracy.
  ///
  /// In en, this message translates to:
  /// **'{accuracy}% accuracy'**
  String playerDictationAttemptAccuracy(int accuracy);

  /// No description provided for @playerDictationRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get playerDictationRecordAgain;

  /// Voice-mode CTA in the Dictation panel (touch platforms have no keyboard shortcuts).
  ///
  /// In en, this message translates to:
  /// **'Record retelling'**
  String get playerDictationRecordRetelling;

  /// Voice-mode CTA in the Dictation panel on desktop, where the R hotkey works.
  ///
  /// In en, this message translates to:
  /// **'Record retelling (R)'**
  String get playerDictationRecordRetellingHotkey;

  /// No description provided for @playerDictationHeaderListen.
  ///
  /// In en, this message translates to:
  /// **'DICTATION — LISTEN & RETELL'**
  String get playerDictationHeaderListen;

  /// No description provided for @playerDictationHeaderChecked.
  ///
  /// In en, this message translates to:
  /// **'DICTATION — CHECKED'**
  String get playerDictationHeaderChecked;

  /// No description provided for @settingsSectionLocalComponents.
  ///
  /// In en, this message translates to:
  /// **'Local components'**
  String get settingsSectionLocalComponents;

  /// No description provided for @settingsSectionLocalComponentsHint.
  ///
  /// In en, this message translates to:
  /// **'Manage offline transcription / translation model components.'**
  String get settingsSectionLocalComponentsHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
