// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plantii';

  @override
  String get languageTitle => 'Select Language';

  @override
  String get homeTitle => 'Home';

  @override
  String get cropSelectionTitle => 'Select Crop';

  @override
  String get selectCropPrompt => 'Which crop do you want to check?';

  @override
  String get cameraTitle => 'Scan Leaf';

  @override
  String get loadingTitle => 'Diagnosing Plant';

  @override
  String get resultTitle => 'Diagnosis Result';

  @override
  String get historyTitle => 'Scan History';

  @override
  String get scanPlantButton => 'Scan Your Plant';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get historyNav => 'History';

  @override
  String get weatherNav => 'Weather';

  @override
  String get helpNav => 'Help';

  @override
  String get checkingPlant => 'Checking your plant...';

  @override
  String get tomato => 'Tomato';

  @override
  String get potato => 'Potato';

  @override
  String get rice => 'Rice';

  @override
  String get wheat => 'Wheat';

  @override
  String get maize => 'Maize';

  @override
  String get cameraTipMoveCloser => 'Move closer & avoid shadows';

  @override
  String get cameraTipFrameLeaf => 'Fit the diseased leaf inside the frame';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get photoNotClear => 'Photo is not clear, please try again';

  @override
  String get cameraPermissionDenied => 'Camera access is needed to scan crops';

  @override
  String get cameraPermissionDeniedHelp =>
      'Please allow camera access in settings, or pick a photo from your gallery.';

  @override
  String get openGallery => 'Open Gallery';

  @override
  String get retry => 'Try Again';

  @override
  String selectedCrop(String crop) {
    return 'Crop: $crop';
  }

  @override
  String get processingImage => 'Optimizing image...';

  @override
  String get analyzingLeafAi => 'AI is analyzing leaf patterns & symptoms...';

  @override
  String get whatItIs => 'What it is';

  @override
  String get whatToDoNow => 'What to do now';

  @override
  String get organicTreatment => 'Organic Treatment';

  @override
  String get chemicalTreatment => 'Chemical Treatment';

  @override
  String get safetyNote => 'Safety Note';

  @override
  String get preventionTips => 'Prevention';

  @override
  String get askAnExpert => 'Ask an Expert';

  @override
  String get listen => 'Listen';

  @override
  String get wasThisHelpful => 'Was this helpful?';

  @override
  String get feedbackThanks => 'Thank you for your feedback!';

  @override
  String get severityMild => 'Mild';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';

  @override
  String get expertModalTitle => 'Kisan Call Center';

  @override
  String get expertModalDesc =>
      'Toll-free agricultural helpline for farmers:\n📞 1800-180-1551 (Available 6 AM - 10 PM)';

  @override
  String get close => 'Close';

  @override
  String get noScansYet => 'No past scans yet';

  @override
  String get noScansYetPrompt =>
      'You have not scanned any plants yet. Take a photo of a diseased leaf to diagnose it.';

  @override
  String get startFirstScan => 'Scan Your First Plant';

  @override
  String get deleteRecord => 'Delete';

  @override
  String scannedOn(String date) {
    return 'Scanned: $date';
  }

  @override
  String get diseaseNameLabel => 'Disease name';

  @override
  String get severityLabel => 'Severity';

  @override
  String get treatmentLabel => 'Treatment';

  @override
  String get stopAudio => 'Stop';

  @override
  String get readingAloud => 'Reading diagnosis aloud...';

  @override
  String get voiceNotInstalledTitle => 'Hindi Voice Not Installed';

  @override
  String get voiceNotInstalledDesc =>
      'Your phone does not have the Hindi voice pack installed for speech. Follow these steps to install it:\n\n1. Open your phone Settings.\n2. Tap \'Accessibility\' or \'System\' > \'Text-to-speech output\'.\n3. Select \'Speech Services by Google\' as the Preferred engine.\n4. Tap the Settings icon (⚙️) next to it, tap \'Install voice data\', and download \'Hindi\'.';

  @override
  String get voiceNotInstalledDismiss => 'Got it';

  @override
  String get greetingFarmer => 'Welcome, Farmer';

  @override
  String get homeSubtitle => 'Check your crop health instantly';

  @override
  String get weatherChipSunny => '28°C • Clear & Sunny';

  @override
  String get weatherChipAdvisory =>
      'Good weather for field inspection & spraying';

  @override
  String get tapToScanLeaf => 'Tap to Scan';

  @override
  String get quickActionsTitle => 'Quick Actions';

  @override
  String get actionGalleryTitle => 'Upload from Gallery';

  @override
  String get actionGallerySubtitle => 'Diagnose saved crop photo';

  @override
  String get actionHistoryTitle => 'Recent Scans';

  @override
  String get actionHistorySubtitle => 'Review past diagnoses & treatments';

  @override
  String get actionExpertTitle => 'Kisan Helpline';

  @override
  String get actionExpertSubtitle =>
      'Toll-free agricultural expert consultation';

  @override
  String get profileNav => 'Profile';

  @override
  String get profileTitle => 'Farmer Profile';

  @override
  String get profileLanguage => 'App Language';

  @override
  String get profileHelpline => 'Farmer Helpline: 1800-180-1551';

  @override
  String get profileVersion => 'Plantii v1.0.0';

  @override
  String get errorNoInternet =>
      'No internet connection. Please check your network and try again.';

  @override
  String get errorTimeout =>
      'The diagnosis request timed out after 60 seconds. Please try again.';

  @override
  String get errorRateLimited =>
      'Daily scan limit reached (maximum 10 scans per day). Please try again tomorrow.';

  @override
  String get errorBadImage =>
      'The leaf photo was not clear enough or unsupported. Please retake a clear photo.';

  @override
  String get errorAiFailed =>
      'Failed to analyze crop leaf. Please retry with a clearer photo.';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get submittingFeedback => 'Submitting feedback...';

  @override
  String get feedbackSuccess => 'Thank you for your feedback!';

  @override
  String get feedbackError => 'Could not submit feedback.';

  @override
  String get consentTitle => 'Important Privacy & AI Notice';

  @override
  String get consentSubtitle =>
      'Please review how Plantii handles your plant photos and data before scanning.';

  @override
  String get consentLine1 =>
      'Your plant photo is sent to an AI service (Google Gemini) to diagnose the problem';

  @override
  String get consentLine2 =>
      'We save your scan results to your anonymous account so you can see history';

  @override
  String get consentLine3 => 'We don\'t sell your data or use it for ads';

  @override
  String get consentLine4 =>
      'AI advice is guidance, not a guarantee. For serious problems, ask an expert.';

  @override
  String get consentLine5 => 'You can delete your data anytime in Settings';

  @override
  String get readFullPrivacyPolicy => 'Read Full Privacy Policy';

  @override
  String get consentAgree => 'I Agree';

  @override
  String get consentDecline => 'No Thanks';

  @override
  String get consentRequiredTitle => 'Consent Required to Scan';

  @override
  String get consentRequiredDesc =>
      'Plantii uses AI to analyze plant leaf photos. Without your consent, scanning features remain blocked. You can still browse the app and agree whenever you are ready.';

  @override
  String get consentGoBack => 'Go Back';

  @override
  String get consentReview => 'Review Consent';

  @override
  String get settingsTitle => 'Settings & Privacy';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicyDesc =>
      'Read our full privacy policy and data practices';

  @override
  String get settingsDeleteData => 'Delete My Data';

  @override
  String get settingsDeleteDataDesc =>
      'Permanently erase scans, feedback, and account';

  @override
  String get settingsWithdrawConsent => 'Withdraw Consent';

  @override
  String get settingsWithdrawConsentDesc =>
      'Stop AI image processing and block scanning';

  @override
  String get settingsContactSupport => 'Contact Support';

  @override
  String get settingsContactSupportDesc => 'info@prakruty.com';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get deleteConfirmTitle => 'Permanently Delete Data?';

  @override
  String get deleteConfirmDesc =>
      'This will permanently delete your account, all scan history, saved photos, and feedback from our servers and this phone. This action cannot be undone.';

  @override
  String get deleteConfirmButton => 'Delete Everything';

  @override
  String get deletingDataProgress => 'Deleting your data permanently...';

  @override
  String get deleteDataSuccess =>
      'Your data and account have been deleted successfully.';

  @override
  String get deleteDataError =>
      'Failed to delete account. Please check your connection and try again.';

  @override
  String get withdrawConfirmTitle => 'Withdraw Consent?';

  @override
  String get withdrawConfirmDesc =>
      'Withdrawing consent will block scanning and AI leaf diagnosis until you choose to consent again.';

  @override
  String get withdrawConfirmButton => 'Withdraw Consent';

  @override
  String get withdrawSuccess =>
      'Consent withdrawn. Scanning features are now disabled.';

  @override
  String get cancel => 'Cancel';

  @override
  String get aiDisclaimer => 'AI guidance, not a guarantee.';
}
