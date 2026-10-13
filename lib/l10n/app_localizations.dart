import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Plantii'**
  String get appTitle;

  /// Title for language selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageTitle;

  /// Title for home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Title for crop selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Crop'**
  String get cropSelectionTitle;

  /// Instruction subtitle for crop selection
  ///
  /// In en, this message translates to:
  /// **'Which crop do you want to check?'**
  String get selectCropPrompt;

  /// Title for camera screen
  ///
  /// In en, this message translates to:
  /// **'Scan Leaf'**
  String get cameraTitle;

  /// Title for loading screen
  ///
  /// In en, this message translates to:
  /// **'Diagnosing Plant'**
  String get loadingTitle;

  /// Title for result screen
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Result'**
  String get resultTitle;

  /// Title for history screen
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get historyTitle;

  /// Main scan button text
  ///
  /// In en, this message translates to:
  /// **'Scan Your Plant'**
  String get scanPlantButton;

  /// Button to pick image from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Navigation label for history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyNav;

  /// Navigation label for weather
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherNav;

  /// Navigation label for help
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpNav;

  /// Friendly loading text
  ///
  /// In en, this message translates to:
  /// **'Checking your plant...'**
  String get checkingPlant;

  /// Tomato crop
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get tomato;

  /// Potato crop
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get potato;

  /// Rice crop
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get rice;

  /// Wheat crop
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get wheat;

  /// Maize crop
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get maize;

  /// Tip on camera screen
  ///
  /// In en, this message translates to:
  /// **'Move closer & avoid shadows'**
  String get cameraTipMoveCloser;

  /// Second camera tip
  ///
  /// In en, this message translates to:
  /// **'Fit the diseased leaf inside the frame'**
  String get cameraTipFrameLeaf;

  /// Take photo button
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Error when photo is too small or unclear
  ///
  /// In en, this message translates to:
  /// **'Photo is not clear, please try again'**
  String get photoNotClear;

  /// Title when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan crops'**
  String get cameraPermissionDenied;

  /// Help message when camera access is denied
  ///
  /// In en, this message translates to:
  /// **'Please allow camera access in settings, or pick a photo from your gallery.'**
  String get cameraPermissionDeniedHelp;

  /// Gallery button
  ///
  /// In en, this message translates to:
  /// **'Open Gallery'**
  String get openGallery;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// Shows which crop is currently being scanned
  ///
  /// In en, this message translates to:
  /// **'Crop: {crop}'**
  String selectedCrop(String crop);

  /// Notice shown while validating and compressing photo
  ///
  /// In en, this message translates to:
  /// **'Optimizing image...'**
  String get processingImage;

  /// Detailed text during 2 second AI diagnosis loading
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing leaf patterns & symptoms...'**
  String get analyzingLeafAi;

  /// Diagnosis description section header
  ///
  /// In en, this message translates to:
  /// **'What it is'**
  String get whatItIs;

  /// Immediate actions section header
  ///
  /// In en, this message translates to:
  /// **'What to do now'**
  String get whatToDoNow;

  /// Organic treatment section title
  ///
  /// In en, this message translates to:
  /// **'Organic Treatment'**
  String get organicTreatment;

  /// Chemical treatment section title
  ///
  /// In en, this message translates to:
  /// **'Chemical Treatment'**
  String get chemicalTreatment;

  /// Safety warning note title
  ///
  /// In en, this message translates to:
  /// **'Safety Note'**
  String get safetyNote;

  /// Prevention tips section header
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get preventionTips;

  /// Button to connect with an expert
  ///
  /// In en, this message translates to:
  /// **'Ask an Expert'**
  String get askAnExpert;

  /// Audio read-out button
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// Feedback question
  ///
  /// In en, this message translates to:
  /// **'Was this helpful?'**
  String get wasThisHelpful;

  /// Acknowledgment after thumbs up/down
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackThanks;

  /// Mild disease severity label
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// Moderate disease severity label
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// Severe disease severity label
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;

  /// Expert dialog title
  ///
  /// In en, this message translates to:
  /// **'Kisan Call Center'**
  String get expertModalTitle;

  /// Expert dialog message
  ///
  /// In en, this message translates to:
  /// **'Toll-free agricultural helpline for farmers:\n📞 1800-180-1551 (Available 6 AM - 10 PM)'**
  String get expertModalDesc;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Empty state title for history screen
  ///
  /// In en, this message translates to:
  /// **'No past scans yet'**
  String get noScansYet;

  /// Empty state subtitle for history screen
  ///
  /// In en, this message translates to:
  /// **'You have not scanned any plants yet. Take a photo of a diseased leaf to diagnose it.'**
  String get noScansYetPrompt;

  /// Action button in empty state
  ///
  /// In en, this message translates to:
  /// **'Scan Your First Plant'**
  String get startFirstScan;

  /// Delete history item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteRecord;

  /// Date label for history item
  ///
  /// In en, this message translates to:
  /// **'Scanned: {date}'**
  String scannedOn(String date);

  /// Label for disease name in audio readout
  ///
  /// In en, this message translates to:
  /// **'Disease name'**
  String get diseaseNameLabel;

  /// Label for disease severity in audio readout
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// Label for treatment in audio readout
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatmentLabel;

  /// Button to stop audio readout
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopAudio;

  /// Status text while TTS is speaking
  ///
  /// In en, this message translates to:
  /// **'Reading diagnosis aloud...'**
  String get readingAloud;

  /// Title when Hindi TTS voice is missing
  ///
  /// In en, this message translates to:
  /// **'Hindi Voice Not Installed'**
  String get voiceNotInstalledTitle;

  /// Step by step instructions to install Hindi TTS
  ///
  /// In en, this message translates to:
  /// **'Your phone does not have the Hindi voice pack installed for speech. Follow these steps to install it:\n\n1. Open your phone Settings.\n2. Tap \'Accessibility\' or \'System\' > \'Text-to-speech output\'.\n3. Select \'Speech Services by Google\' as the Preferred engine.\n4. Tap the Settings icon (⚙️) next to it, tap \'Install voice data\', and download \'Hindi\'.'**
  String get voiceNotInstalledDesc;

  /// Dismiss button for voice install dialog
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get voiceNotInstalledDismiss;

  /// Warm greeting on home screen header
  ///
  /// In en, this message translates to:
  /// **'Welcome, Farmer'**
  String get greetingFarmer;

  /// Subtitle below home greeting
  ///
  /// In en, this message translates to:
  /// **'Check your crop health instantly'**
  String get homeSubtitle;

  /// Weather status chip text
  ///
  /// In en, this message translates to:
  /// **'28°C • Clear & Sunny'**
  String get weatherChipSunny;

  /// Weather advisory message on tap
  ///
  /// In en, this message translates to:
  /// **'Good weather for field inspection & spraying'**
  String get weatherChipAdvisory;

  /// Label on circular scan button
  ///
  /// In en, this message translates to:
  /// **'Tap to Scan'**
  String get tapToScanLeaf;

  /// Section header for quick actions on home screen
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// Title of quick action card for gallery
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get actionGalleryTitle;

  /// Subtitle of quick action card for gallery
  ///
  /// In en, this message translates to:
  /// **'Diagnose saved crop photo'**
  String get actionGallerySubtitle;

  /// Title of quick action card for scan history
  ///
  /// In en, this message translates to:
  /// **'Recent Scans'**
  String get actionHistoryTitle;

  /// Subtitle of quick action card for scan history
  ///
  /// In en, this message translates to:
  /// **'Review past diagnoses & treatments'**
  String get actionHistorySubtitle;

  /// Title of quick action card for expert helpline
  ///
  /// In en, this message translates to:
  /// **'Kisan Helpline'**
  String get actionExpertTitle;

  /// Subtitle of quick action card for expert helpline
  ///
  /// In en, this message translates to:
  /// **'Toll-free agricultural expert consultation'**
  String get actionExpertSubtitle;

  /// Bottom navigation label for profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileNav;

  /// Title for profile modal
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile'**
  String get profileTitle;

  /// Language label in profile
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get profileLanguage;

  /// Helpline info in profile
  ///
  /// In en, this message translates to:
  /// **'Farmer Helpline: 1800-180-1551'**
  String get profileHelpline;

  /// Version info in profile
  ///
  /// In en, this message translates to:
  /// **'Plantii v1.0.0'**
  String get profileVersion;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
