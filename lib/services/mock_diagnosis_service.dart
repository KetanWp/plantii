import '../models/diagnosis.dart';

/// Provides realistic mock disease diagnosis data in both English and Hindi.
/// Can be replaced with a live API client without impacting screen code.
class MockDiagnosisService {
  const MockDiagnosisService();

  /// Fetches diagnosis by cropId and languageCode ('en' or 'hi')
  Future<Diagnosis> getDiagnosis({
    required String cropId,
    required String languageCode,
  }) async {
    final bool isHindi = languageCode == 'hi';

    switch (cropId.toLowerCase()) {
      case 'potato':
        return _getPotatoLateBlight(isHindi);
      case 'rice':
        return _getRiceBlast(isHindi);
      case 'tomato':
      default:
        return _getTomatoEarlyBlight(isHindi);
    }
  }

  // --- Disease 1: Tomato Early Blight (Moderate) ---
  Diagnosis _getTomatoEarlyBlight(bool isHindi) {
    if (isHindi) {
      return const Diagnosis(
        id: 'tomato_early_blight',
        cropId: 'tomato',
        diseaseName: 'टमाटर का अगेती झुलसा',
        scientificName: 'Alternaria solani',
        severity: DiagnosisSeverity.moderate,
        confidenceLevel: 'अत्यधिक संभावित (95%)',
        description:
            'यह फफूंद जनित रोग है। पत्तियों पर भूरे-काले गोल छल्ले (टारगेट बोर्ड जैसे) बनते हैं और पत्तियां पीली होकर सूखने लगती हैं।',
        immediateActions: [
          'रोगग्रस्त निचली पत्तियों को तुरंत तोड़कर खेत से दूर जलाएं या गहरा दबाएं।',
          'फव्वारा सिंचाई बंद करें, पानी सिर्फ पौधों की जड़ों में दें ताकि पत्तियां सूखी रहें।',
        ],
        organicTreatments: [
          'नीम का तेल (5 मि.ली. प्रति लीटर पानी) में थोड़ा साबुन घोलकर हर 7 दिन पर छिड़कें।',
          'ट्राइकोडर्मा विरिडी (5 ग्राम प्रति लीटर) फफूंदनाशक का पत्तियों पर छिड़काव करें।',
        ],
        chemicalTreatments: [
          'मैनकोजेब 75% WP (2.5 ग्राम प्रति लीटर पानी) का 10 दिन के अंतराल पर छिड़काव करें।',
          'रोग अधिक होने पर एजोक्सीस्ट्रोबिन 23% SC (1 मि.ली. प्रति लीटर) का प्रयोग करें।',
        ],
        safetyNote:
            'दवा छिड़कते समय चेहरे पर मास्क और हाथों में दस्ताने जरूर पहनें। छिड़काव के 24 घंटे तक पशुओं को खेत में न जाने दें।',
        preventionTips: [
          'टमाटर के बाद आलू या बैंगन की फसल न लगाएं, 3 साल का फसल चक्र अपनाएं।',
          'पौधों के बीच 60 सेमी की दूरी रखें ताकि हवा और धूप अच्छी तरह लगे।',
          'जड़ों के आसपास सूखी घास की मल्चिंग करें जिससे मिट्टी के कीटाणु पत्तियों पर न उछलें।',
        ],
      );
    }

    return const Diagnosis(
      id: 'tomato_early_blight',
      cropId: 'tomato',
      diseaseName: 'Tomato Early Blight',
      scientificName: 'Alternaria solani',
      severity: DiagnosisSeverity.moderate,
      confidenceLevel: 'Very likely (95%)',
      description:
          'A fungal disease creating dark concentric rings ("target spots") on older foliage. Causes yellowing and premature leaf drop.',
      immediateActions: [
        'Prune and destroy infected lower leaves immediately to stop spores.',
        'Avoid overhead watering; irrigate strictly at the base to keep foliage dry.',
      ],
      organicTreatments: [
        'Spray cold-pressed Neem oil (5ml per litre with mild soap) every 7 days.',
        'Apply Trichoderma viride bio-fungicide (5g per litre) on foliage.',
      ],
      chemicalTreatments: [
        'Apply Mancozeb 75% WP (2.5g per litre) at 10-day intervals.',
        'For stubborn outbreaks, apply Azoxystrobin 23% SC (1ml per litre).',
      ],
      safetyNote:
          'Wear protective mask and gloves while spraying. Keep livestock and children away from treated fields for 24 hours.',
      preventionTips: [
        'Rotate crops for 3 years; avoid planting after potatoes or eggplants.',
        'Ensure 60cm spacing between plants for adequate ventilation.',
        'Mulch soil around base to prevent fungal spores splashing from soil.',
      ],
    );
  }

  // --- Disease 2: Potato Late Blight (Severe) ---
  Diagnosis _getPotatoLateBlight(bool isHindi) {
    if (isHindi) {
      return const Diagnosis(
        id: 'potato_late_blight',
        cropId: 'potato',
        diseaseName: 'आलू का पछेती झुलसा',
        scientificName: 'Phytophthora infestans',
        severity: DiagnosisSeverity.severe,
        confidenceLevel: 'अत्यधिक संभावित (92%)',
        description:
            'यह आलू का सबसे घातक फफूंद रोग है। पत्तियों के किनारों पर काले-भूरे गीले धब्बे बनते हैं और ठंडे नम मौसम में पूरी फसल 3-4 दिन में नष्ट हो सकती है।',
        immediateActions: [
          'खेत में रोगग्रस्त पौधों को तुरंत उखाड़कर नष्ट करें ताकि पूरे खेत में न फैले।',
          'खेत में अतिरिक्त पानी का निकास तुरंत सुनिश्चित करें।',
        ],
        organicTreatments: [
          'कॉपर ऑक्सीक्लोराइड 50% WP (3 ग्राम प्रति लीटर पानी) का त्वरित छिड़काव करें।',
          'स्यूडोमोनास फ्लोरोसेंट (10 ग्राम प्रति लीटर) से पौधों को तर-बतर करें।',
        ],
        chemicalTreatments: [
          'रिडोमिल एमजेड (मेटालैक्सिल 8% + मैनकोजेब 64% WP) 2.5 ग्राम प्रति लीटर छिड़कें।',
          'रोग तेजी से फैलने पर साइमोक्सानिल + मैनकोजेब (2 ग्राम प्रति लीटर) का छिड़काव करें।',
        ],
        safetyNote:
            'छिड़काव शांत सुबह के समय करें ताकि दवा हवा से न उड़े। छिड़काव के बाद हाथ-मुंह साबुन से अच्छी तरह धोएं।',
        preventionTips: [
          'केवल प्रमाणित एवं रोगमुक्त बीज कंदों का ही उपयोग करें।',
          'यूरिया (नाइट्रोजन) की अधिक मात्रा से बचें, संतुलित खाद दें।',
          'आलू की मिट्टी चढ़ाते समय पौधों को उचित ऊंचाई दें।',
        ],
      );
    }

    return const Diagnosis(
      id: 'potato_late_blight',
      cropId: 'potato',
      diseaseName: 'Potato Late Blight',
      scientificName: 'Phytophthora infestans',
      severity: DiagnosisSeverity.severe,
      confidenceLevel: 'Very likely (92%)',
      description:
          'A rapid destructive water-mold disease causing dark, water-soaked lesions that rot leaves and stems in cool, humid weather.',
      immediateActions: [
        'Isolate infected crop patches immediately to stop windborne airborne spread.',
        'Ensure proper furrow drainage to eliminate standing moisture.',
      ],
      organicTreatments: [
        'Spray Copper Oxychloride 50% WP (3g per litre of water).',
        'Drench with Pseudomonas fluorescens bio-agent solution.',
      ],
      chemicalTreatments: [
        'Spray Metalaxyl 8% + Mancozeb 64% WP (Ridomil MZ) at 2.5g per litre.',
        'Apply Cymoxanil + Mancozeb (2g per litre) within 48 hours of symptoms.',
      ],
      safetyNote:
          'Spray in calm morning weather to avoid drift. Wash face and hands thoroughly with soap after handling.',
      preventionTips: [
        'Plant only certified disease-free certified seed tubers.',
        'Avoid excess nitrogen fertilizer which causes dense, humid leaf canopy.',
        'Ensure high earthen hilling around potato bases to protect tubers.',
      ],
    );
  }

  // --- Disease 3: Rice Blast (Mild) ---
  Diagnosis _getRiceBlast(bool isHindi) {
    if (isHindi) {
      return const Diagnosis(
        id: 'rice_blast',
        cropId: 'rice',
        diseaseName: 'धान का झोंका रोग (ब्लास्ट)',
        scientificName: 'Magnaporthe oryzae',
        severity: DiagnosisSeverity.mild,
        confidenceLevel: 'संभावित (88%)',
        description:
            'पत्तियों पर आंख या नाव के आकार के भूरे धब्बे बनते हैं जिनका केंद्र भूरा या सफेद होता है। शुरुआती चरण में नियंत्रित करना आसान होता है।',
        immediateActions: [
          'खेत से पानी 2-3 दिन के लिए निकाल दें ताकि नमी का स्तर कम हो सके।',
          'रोग ठीक होने तक यूरिया की टॉप-ड्रेसिंग बिल्कुल रोक दें।',
        ],
        organicTreatments: [
          'खट्टी छाछ (50 मि.ली. प्रति लीटर पानी) मिलाकर पौधों पर छिड़कें।',
          'स्यूडोमोनास फ्लोरोसेंस पाउडर (10 ग्राम प्रति लीटर) का घोल बनाकर छिड़कें।',
        ],
        chemicalTreatments: [
          'ट्राइसाइक्लाजोल 75% WP (0.6 ग्राम प्रति लीटर पानी) का तत्काल छिड़काव करें।',
          'आइसोप्रोथियोलेन 40% EC (1.5 मि.ली. प्रति लीटर) का 12 दिन बाद दूसरा छिड़काव करें।',
        ],
        safetyNote:
            'दवा का अवशेष पास के मछली तालाब या नहर के पानी में न जाने दें। कीटनाशक डिब्बे बच्चों की पहुंच से दूर रखें।',
        preventionTips: [
          'बुवाई से पहले कार्बेन्डाजिम (2 ग्राम प्रति किलो बीज) से बीज उपचार करें।',
          'पोटाश खाद का संतुलित उपयोग करें जिससे पत्तियां मजबूत रहें।',
          'क्षेत्रीय कृषि विज्ञान केंद्र द्वारा अनुशंसित प्रतिरोधी धान की किस्में लगाएं।',
        ],
      );
    }

    return const Diagnosis(
      id: 'rice_blast',
      cropId: 'rice',
      diseaseName: 'Rice Leaf Blast',
      scientificName: 'Magnaporthe oryzae',
      severity: DiagnosisSeverity.mild,
      confidenceLevel: 'Possibly (88%)',
      description:
          'Spindle-shaped or eye-shaped lesions with ash-grey centers and brown borders on leaves. Controllable if caught early.',
      immediateActions: [
        'Drain standing paddy water temporarily to drop canopy humidity.',
        'Halt nitrogen (Urea) top-dressing immediately until crop recovers.',
      ],
      organicTreatments: [
        'Foliar spray with fermented sour buttermilk (50ml per litre).',
        'Apply Pseudomonas fluorescens (10g per litre) biopesticide.',
      ],
      chemicalTreatments: [
        'Spray Tricyclazole 75% WP (0.6g per litre of water) at first appearance.',
        'Apply Isoprothiolane 40% EC (1.5ml per litre) 12 days later if needed.',
      ],
      safetyNote:
          'Keep spray run-off away from fish ponds or streams. Store chemical bottles locked safely away from children.',
      preventionTips: [
        'Treat seed paddy with Carbendazim (2g per kg seed) before sowing.',
        'Maintain balanced Potash fertilization to strengthen plant cell walls.',
        'Plant certified blast-resistant regional paddy cultivars.',
      ],
    );
  }
}
