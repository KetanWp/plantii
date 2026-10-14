// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Plantii (प्लांटी)';

  @override
  String get languageTitle => 'भाषा चुनें';

  @override
  String get homeTitle => 'होम';

  @override
  String get cropSelectionTitle => 'फसल चुनें';

  @override
  String get selectCropPrompt => 'आप किस फसल की जांच करना चाहते हैं?';

  @override
  String get cameraTitle => 'पत्ती स्कैन करें';

  @override
  String get loadingTitle => 'पौधे की जांच';

  @override
  String get resultTitle => 'जांच परिणाम';

  @override
  String get historyTitle => 'पुराने स्कैन';

  @override
  String get scanPlantButton => 'पौधा स्कैन करें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get historyNav => 'इतिहास';

  @override
  String get weatherNav => 'मौसम';

  @override
  String get helpNav => 'मदद';

  @override
  String get checkingPlant => 'पौधे की जांच की जा रही है...';

  @override
  String get tomato => 'टमाटर';

  @override
  String get potato => 'आलू';

  @override
  String get rice => 'धान (चावल)';

  @override
  String get wheat => 'गेहूं';

  @override
  String get maize => 'मक्का';

  @override
  String get cameraTipMoveCloser => 'पत्ती के पास जाएं और छाया से बचें';

  @override
  String get cameraTipFrameLeaf => 'रोगग्रस्त पत्ती को चौखट के अंदर रखें';

  @override
  String get takePhoto => 'फोटो खींचें';

  @override
  String get photoNotClear => 'फोटो साफ नहीं है, कृपया दोबारा प्रयास करें';

  @override
  String get cameraPermissionDenied =>
      'फसल स्कैन करने के लिए कैमरा अनुमति चाहिए';

  @override
  String get cameraPermissionDeniedHelp =>
      'कृपया सेटिंग्स में कैमरा चालू करें, या अपनी गैलरी से फोटो चुनें।';

  @override
  String get openGallery => 'गैलरी से फोटो लें';

  @override
  String get retry => 'दोबारा कोशिश करें';

  @override
  String selectedCrop(String crop) {
    return 'फसल: $crop';
  }

  @override
  String get processingImage => 'फोटो तैयार हो रही है...';

  @override
  String get analyzingLeafAi => 'एआई पत्ती के लक्षणों का विश्लेषण कर रहा है...';

  @override
  String get whatItIs => 'यह क्या है';

  @override
  String get whatToDoNow => 'अभी क्या करें';

  @override
  String get organicTreatment => 'जैविक उपचार';

  @override
  String get chemicalTreatment => 'रासायनिक उपचार';

  @override
  String get safetyNote => 'सुरक्षा निर्देश';

  @override
  String get preventionTips => 'बचाव के उपाय';

  @override
  String get askAnExpert => 'विशेषज्ञ से पूछें';

  @override
  String get listen => 'सुनें';

  @override
  String get wasThisHelpful => 'क्या यह जानकारी उपयोगी थी?';

  @override
  String get feedbackThanks => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';

  @override
  String get severityMild => 'हल्का';

  @override
  String get severityModerate => 'मध्यम';

  @override
  String get severitySevere => 'गंभीर';

  @override
  String get expertModalTitle => 'किसान कॉल सेंटर';

  @override
  String get expertModalDesc =>
      'किसानों के लिए निःशुल्क हेल्पलाइन:\n📞 1800-180-1551 (प्रातः 6 से रात्रि 10 बजे तक)';

  @override
  String get close => 'बंद करें';

  @override
  String get noScansYet => 'कोई पुराना स्कैन नहीं मिला';

  @override
  String get noScansYetPrompt =>
      'आपने अभी तक किसी पौधे को स्कैन नहीं किया है। रोग की पहचान के लिए पत्ती की फोटो लें।';

  @override
  String get startFirstScan => 'पौधा स्कैन करें';

  @override
  String get deleteRecord => 'हटाएं';

  @override
  String scannedOn(String date) {
    return 'दिनांक: $date';
  }

  @override
  String get diseaseNameLabel => 'रोग का नाम';

  @override
  String get severityLabel => 'गंभीरता';

  @override
  String get treatmentLabel => 'उपचार';

  @override
  String get stopAudio => 'रोकें';

  @override
  String get readingAloud => 'रोग की जानकारी सुनाई जा रही है...';

  @override
  String get voiceNotInstalledTitle => 'हिंदी आवाज उपलब्ध नहीं है';

  @override
  String get voiceNotInstalledDesc =>
      'आपके फोन में हिंदी में बोलने वाली आवाज (Text-to-Speech) इंस्टॉल नहीं है। इसे चालू करने के लिए निम्न कदम उठाएं:\n\n1. अपने फोन की \'सेटिंग्स\' (Settings) खोलें।\n2. \'पहुंच\' (Accessibility) या \'सिस्टम\' में \'टेक्स्ट-टू-स्पीच\' (Text-to-speech) चुनें।\n3. \'पसंदीदा इंजन\' (Preferred engine) में Google Speech Services चुनें।\n4. सेटिंग्स आइकन (⚙️) दबाकर \'आवाज डेटा इंस्टॉल करें\' में जाएं और \'हिंदी\' डाउनलोड करें।';

  @override
  String get voiceNotInstalledDismiss => 'समझ गया';

  @override
  String get greetingFarmer => 'स्वागत है, किसान मित्र';

  @override
  String get homeSubtitle => 'अपने पौधों के स्वास्थ्य की तुरंत जांच करें';

  @override
  String get weatherChipSunny => '28°C • धूप व साफ मौसम';

  @override
  String get weatherChipAdvisory =>
      'खेत निरीक्षण और छिड़काव के लिए अनुकूल मौसम';

  @override
  String get tapToScanLeaf => 'पत्ती स्कैन करें';

  @override
  String get quickActionsTitle => 'त्वरित सेवाएं';

  @override
  String get actionGalleryTitle => 'गैलरी से फोटो लें';

  @override
  String get actionGallerySubtitle => 'सहेजी गई फसल की फोटो जांचें';

  @override
  String get actionHistoryTitle => 'पुराने स्कैन देखें';

  @override
  String get actionHistorySubtitle => 'पुराने उपचार व परिणाम देखें';

  @override
  String get actionExpertTitle => 'किसान हेल्पलाइन';

  @override
  String get actionExpertSubtitle => 'कृषि वैज्ञानिकों से निःशुल्क सलाह';

  @override
  String get profileNav => 'प्रोफ़ाइल';

  @override
  String get profileTitle => 'किसान प्रोफ़ाइल';

  @override
  String get profileLanguage => 'ऐप की भाषा';

  @override
  String get profileHelpline => 'किसान हेल्पलाइन: 1800-180-1551';

  @override
  String get profileVersion => 'Plantii v1.0.0';

  @override
  String get errorNoInternet =>
      'इंटरनेट कनेक्शन नहीं है। कृपया अपना नेटवर्क जांचें और पुनः प्रयास करें।';

  @override
  String get errorTimeout =>
      'अनुरोध का समय समाप्त हो गया (60 सेकंड)। कृपया पुनः प्रयास करें।';

  @override
  String get errorRateLimited =>
      'दैनिक स्कैन सीमा समाप्त हो गई है (अधिकतम 10 स्कैन प्रतिदिन)। कृपया कल पुनः प्रयास करें।';

  @override
  String get errorBadImage =>
      'पत्ती की फोटो स्पष्ट नहीं है या अमान्य है। कृपया स्पष्ट फोटो दोबारा लें।';

  @override
  String get errorAiFailed =>
      'पौधे की जांच करने में समस्या आई। कृपया स्पष्ट फोटो के साथ पुनः प्रयास करें।';

  @override
  String get retakePhoto => 'फोटो दोबारा लें';

  @override
  String get backToHome => 'होम पर जाएं';

  @override
  String get submittingFeedback => 'प्रतिक्रिया भेजी जा रही है...';

  @override
  String get feedbackSuccess => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';

  @override
  String get feedbackError => 'प्रतिक्रिया भेजने में समस्या आई।';

  @override
  String get consentTitle => 'महत्वपूर्ण गोपनीयता और एआई सूचना';

  @override
  String get consentSubtitle =>
      'स्कैन करने से पहले कृपया समझें कि प्लांटी आपके पौधे की फोटो और डेटा का उपयोग कैसे करता है।';

  @override
  String get consentLine1 =>
      'पौधे की समस्या पहचानने के लिए पत्ती की फोटो सुरक्षित एआई सेवा (गूगल जेमिनी) को भेजी जाती है';

  @override
  String get consentLine2 =>
      'हम आपके स्कैन परिणाम को आपके अज्ञात खाते में सहेजते हैं ताकि आप पुराना इतिहास देख सकें';

  @override
  String get consentLine3 =>
      'हम आपका डेटा कभी किसी को नहीं बेचते और न ही विज्ञापनों में उपयोग करते हैं';

  @override
  String get consentLine4 =>
      'एआई सलाह केवल मार्गदर्शन है, गारंटी नहीं। गंभीर समस्या होने पर कृषि विशेषज्ञ से सलाह लें।';

  @override
  String get consentLine5 =>
      'आप सेटिंग्स में जाकर किसी भी समय अपना पूरा डेटा मिटा सकते हैं';

  @override
  String get readFullPrivacyPolicy => 'पूरी गोपनीयता नीति पढ़ें';

  @override
  String get consentAgree => 'स्वीकार करें';

  @override
  String get consentDecline => 'अभी नहीं';

  @override
  String get consentRequiredTitle => 'स्कैन करने के लिए सहमति आवश्यक है';

  @override
  String get consentRequiredDesc =>
      'प्लांटी पत्तियों की फोटो जांचने के लिए एआई तकनीक का उपयोग करता है। बिना सहमति के स्कैनिंग सुविधा बंद रहेगी। आप ऐप देख सकते हैं और तैयार होने पर कभी भी सहमति दे सकते हैं।';

  @override
  String get consentGoBack => 'वापस जाएं';

  @override
  String get consentReview => 'सहमति देखें';

  @override
  String get settingsTitle => 'सेटिंग्स और गोपनीयता';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsPrivacyPolicyDesc =>
      'पूरी गोपनीयता नीति और डेटा नियम पढ़ें';

  @override
  String get settingsDeleteData => 'मेरा डेटा हटाएं';

  @override
  String get settingsDeleteDataDesc =>
      'अपने सभी स्कैन, फीडबैक और खाता हमेशा के लिए मिटाएं';

  @override
  String get settingsWithdrawConsent => 'सहमति वापस लें';

  @override
  String get settingsWithdrawConsentDesc =>
      'एआई फोटो विश्लेषण रोकें और स्कैनिंग बंद करें';

  @override
  String get settingsContactSupport => 'सहायता से संपर्क करें';

  @override
  String get settingsContactSupportDesc => 'info@prakruty.com';

  @override
  String get settingsAppVersion => 'ऐप संस्करण';

  @override
  String get deleteConfirmTitle => 'क्या आप सारा डेटा मिटाना चाहते हैं?';

  @override
  String get deleteConfirmDesc =>
      'यह आपके खाते, सभी पुराने स्कैन, सहेजी गई फोटो और फीडबैक को सर्वर व इस फोन से हमेशा के लिए मिटा देगा। यह क्रिया वापस नहीं ली जा सकती।';

  @override
  String get deleteConfirmButton => 'सब कुछ हटाएं';

  @override
  String get deletingDataProgress => 'डेटा स्थायी रूप से हटाया जा रहा है...';

  @override
  String get deleteDataSuccess =>
      'आपका डेटा और खाता सफलतापूर्वक मिटा दिया गया है।';

  @override
  String get deleteDataError =>
      'खाता हटाने में समस्या आई। कृपया इंटरनेट जांचें और पुनः प्रयास करें।';

  @override
  String get withdrawConfirmTitle => 'सहमति वापस लेना चाहते हैं?';

  @override
  String get withdrawConfirmDesc =>
      'सहमति वापस लेने पर स्कैनिंग और एआई जांच सुविधा तब तक बंद रहेगी जब तक आप पुनः सहमति नहीं देते।';

  @override
  String get withdrawConfirmButton => 'सहमति वापस लें';

  @override
  String get withdrawSuccess =>
      'सहमति वापस ले ली गई है। स्कैनिंग सुविधा बंद कर दी गई है।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get aiDisclaimer => 'एआई सलाह केवल मार्गदर्शन है, गारंटी नहीं।';
}
