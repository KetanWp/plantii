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
}
