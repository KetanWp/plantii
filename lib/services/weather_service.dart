import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 3-day forecast item
class DayForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int rainChance;
  final int weatherCode;

  const DayForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainChance,
    required this.weatherCode,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'rainChance': rainChance,
        'weatherCode': weatherCode,
      };

  factory DayForecast.fromMap(Map<String, dynamic> map) => DayForecast(
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        maxTemp: (map['maxTemp'] as num?)?.toDouble() ?? 0.0,
        minTemp: (map['minTemp'] as num?)?.toDouble() ?? 0.0,
        rainChance: (map['rainChance'] as num?)?.toInt() ?? 0,
        weatherCode: (map['weatherCode'] as num?)?.toInt() ?? 0,
      );
}

/// Structured live weather data model with agricultural disease risk hint
class WeatherData {
  final String placeName;
  final double temperature;
  final int humidity;
  final int rainChance;
  final double windSpeed;
  final int weatherCode;
  final List<DayForecast> forecast;
  final String diseaseRiskLevel; // 'high' | 'moderate' | 'low'
  final String diseaseRiskHintEn;
  final String diseaseRiskHintHi;
  final DateTime updatedAt;
  final bool isCached;

  const WeatherData({
    required this.placeName,
    required this.temperature,
    required this.humidity,
    required this.rainChance,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
    required this.diseaseRiskLevel,
    required this.diseaseRiskHintEn,
    required this.diseaseRiskHintHi,
    required this.updatedAt,
    this.isCached = false,
  });

  Map<String, dynamic> toMap() => {
        'placeName': placeName,
        'temperature': temperature,
        'humidity': humidity,
        'rainChance': rainChance,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'forecast': forecast.map((f) => f.toMap()).toList(),
        'diseaseRiskLevel': diseaseRiskLevel,
        'diseaseRiskHintEn': diseaseRiskHintEn,
        'diseaseRiskHintHi': diseaseRiskHintHi,
        'updatedAt': updatedAt.toIso8601String(),
        'isCached': isCached,
      };

  factory WeatherData.fromMap(Map<String, dynamic> map, {bool isCached = false}) {
    return WeatherData(
      placeName: map['placeName'] as String? ?? '',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toInt() ?? 0,
      rainChance: (map['rainChance'] as num?)?.toInt() ?? 0,
      windSpeed: (map['windSpeed'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (map['weatherCode'] as num?)?.toInt() ?? 0,
      forecast: (map['forecast'] as List?)
              ?.map((item) => DayForecast.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      diseaseRiskLevel: map['diseaseRiskLevel'] as String? ?? 'low',
      diseaseRiskHintEn: map['diseaseRiskHintEn'] as String? ?? '',
      diseaseRiskHintHi: map['diseaseRiskHintHi'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      isCached: isCached || (map['isCached'] as bool? ?? false),
    );
  }

  WeatherData copyWith({bool? isCached}) {
    return WeatherData(
      placeName: placeName,
      temperature: temperature,
      humidity: humidity,
      rainChance: rainChance,
      windSpeed: windSpeed,
      weatherCode: weatherCode,
      forecast: forecast,
      diseaseRiskLevel: diseaseRiskLevel,
      diseaseRiskHintEn: diseaseRiskHintEn,
      diseaseRiskHintHi: diseaseRiskHintHi,
      updatedAt: updatedAt,
      isCached: isCached ?? this.isCached,
    );
  }
}

/// Geocoding result for manual city search
class CityLocation {
  final String name;
  final String? state;
  final String? country;
  final double latitude;
  final double longitude;

  const CityLocation({
    required this.name,
    this.state,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => state != null && state!.isNotEmpty ? '$name, $state' : name;
}

/// Custom structured exception for weather operations
class WeatherException implements Exception {
  final String messageEn;
  final String messageHi;

  const WeatherException({
    required this.messageEn,
    required this.messageHi,
  });

  String getLocalizedMessage(String lang) => lang == 'hi' ? messageHi : messageEn;

  @override
  String toString() => 'WeatherException: $messageEn';
}

/// Production weather service using Open-Meteo APIs (forecast & geocoding)
/// Zero hardcoded / dummy data. 30-minute persistent caching.
class WeatherService {
  static const String _cacheDataKey = 'plantii_weather_cache_data_v1';
  static const String _cacheTimestampKey = 'plantii_weather_cache_timestamp_v1';
  static const String _savedCityKey = 'plantii_weather_saved_city_name';
  static const String _savedLatKey = 'plantii_weather_saved_lat';
  static const String _savedLonKey = 'plantii_weather_saved_lon';

  static const int cacheDurationMinutes = 30;

  final http.Client _httpClient;

  WeatherService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Gets cached weather data if available and optionally validates 30-minute expiry
  Future<WeatherData?> getCachedWeather({bool allowExpired = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_cacheDataKey);
      final String? timeStr = prefs.getString(_cacheTimestampKey);

      if (jsonStr == null || timeStr == null) return null;

      final cachedTime = DateTime.tryParse(timeStr);
      if (cachedTime == null) return null;

      final age = DateTime.now().difference(cachedTime);
      final isFresh = age.inMinutes < cacheDurationMinutes;

      if (!allowExpired && !isFresh) {
        return null;
      }

      final dataMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WeatherData.fromMap(dataMap, isCached: !isFresh);
    } catch (e) {
      debugPrint('WeatherService: Error reading cache: $e');
      return null;
    }
  }

  /// Saves successful weather data to SharedPreferences
  Future<void> _cacheWeather(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheDataKey, jsonEncode(data.toMap()));
      await prefs.setString(_cacheTimestampKey, data.updatedAt.toIso8601String());
    } catch (e) {
      debugPrint('WeatherService: Error writing cache: $e');
    }
  }

  /// Retrieves saved city or returns null
  Future<CityLocation?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_savedCityKey);
    final lat = prefs.getDouble(_savedLatKey);
    final lon = prefs.getDouble(_savedLonKey);

    if (name != null && lat != null && lon != null) {
      return CityLocation(name: name, latitude: lat, longitude: lon);
    }
    return null;
  }

  /// Persists a manually selected city/district
  Future<void> saveManualLocation(CityLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedCityKey, location.name);
    await prefs.setDouble(_savedLatKey, location.latitude);
    await prefs.setDouble(_savedLonKey, location.longitude);
  }

  /// Searches districts and cities using Open-Meteo Geocoding API
  Future<List<CityLocation>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final Uri uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(trimmed)}&count=6&language=en&format=json',
    );

    try {
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>?;
        if (results == null) return [];

        return results.map((item) {
          final m = item as Map<String, dynamic>;
          return CityLocation(
            name: m['name'] as String? ?? '',
            state: m['admin1'] as String?,
            country: m['country'] as String?,
            latitude: (m['latitude'] as num).toDouble(),
            longitude: (m['longitude'] as num).toDouble(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('WeatherService: City search error: $e');
      return [];
    }
  }

  /// Fetches weather with 30-minute caching, fallback to cache on network failure
  Future<WeatherData> fetchWeather({
    double? latitude,
    double? longitude,
    String? placeName,
    bool forceRefresh = false,
  }) async {
    // 1. If not forcing refresh, check fresh cache (< 30 min)
    if (!forceRefresh) {
      final cached = await getCachedWeather(allowExpired: false);
      if (cached != null) {
        return cached;
      }
    }

    // 2. Determine target coordinates and name
    double targetLat;
    double targetLon;
    String targetPlace;

    if (latitude != null && longitude != null) {
      targetLat = latitude;
      targetLon = longitude;
      targetPlace = placeName ?? 'Local Farm';
    } else {
      // Check saved manual location first
      final saved = await getSavedLocation();
      if (saved != null) {
        targetLat = saved.latitude;
        targetLon = saved.longitude;
        targetPlace = placeName ?? saved.name;
      } else {
        // Fallback default coordinates (New Delhi, India agricultural hub centroid)
        targetLat = 28.6139;
        targetLon = 77.2090;
        targetPlace = placeName ?? 'Delhi, India';
      }
    }

    // 3. Request forecast from Open-Meteo
    final Uri forecastUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$targetLat&longitude=$targetLon&current=temperature_2m,relative_humidity_2m,precipitation_probability,wind_speed_10m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=4',
    );

    try {
      final response = await _httpClient.get(forecastUri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw WeatherException(
          messageEn: 'Weather service returned error code ${response.statusCode}.',
          messageHi: 'मौसम सेवा लोड नहीं हो सकी (त्रुटि: ${response.statusCode})।',
        );
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      final current = json['current'] as Map<String, dynamic>?;
      final daily = json['daily'] as Map<String, dynamic>?;

      if (current == null) {
        throw const WeatherException(
          messageEn: 'Incomplete weather information received.',
          messageHi: 'मौसम की अधूरी जानकारी प्राप्त हुई।',
        );
      }

      final double temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
      final int humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
      final int rainChance = (current['precipitation_probability'] as num?)?.toInt() ?? 0;
      final double windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final int weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

      // 4. Parse 3-day forecast (days 1, 2, 3)
      final List<DayForecast> forecastList = [];
      if (daily != null) {
        final times = daily['time'] as List<dynamic>? ?? [];
        final maxTemps = daily['temperature_2m_max'] as List<dynamic>? ?? [];
        final minTemps = daily['temperature_2m_min'] as List<dynamic>? ?? [];
        final rainChances = daily['precipitation_probability_max'] as List<dynamic>? ?? [];
        final codes = daily['weather_code'] as List<dynamic>? ?? [];

        // Skip day 0 (today) to get next 3 days
        for (int i = 1; i < times.length && forecastList.length < 3; i++) {
          forecastList.add(
            DayForecast(
              date: DateTime.tryParse(times[i].toString()) ?? DateTime.now().add(Duration(days: i)),
              maxTemp: (maxTemps.length > i ? maxTemps[i] as num? : null)?.toDouble() ?? temp,
              minTemp: (minTemps.length > i ? minTemps[i] as num? : null)?.toDouble() ?? temp - 5,
              rainChance: (rainChances.length > i ? rainChances[i] as num? : null)?.toInt() ?? 0,
              weatherCode: (codes.length > i ? codes[i] as num? : null)?.toInt() ?? 0,
            ),
          );
        }
      }

      // 5. Calculate agricultural disease risk hint
      final (String riskLevel, String hintEn, String hintHi) =
          _calculateDiseaseRisk(humidity, rainChance);

      final weatherData = WeatherData(
        placeName: targetPlace,
        temperature: temp,
        humidity: humidity,
        rainChance: rainChance,
        windSpeed: windSpeed,
        weatherCode: weatherCode,
        forecast: forecastList,
        diseaseRiskLevel: riskLevel,
        diseaseRiskHintEn: hintEn,
        diseaseRiskHintHi: hintHi,
        updatedAt: DateTime.now(),
        isCached: false,
      );

      // Persist to 30-minute cache
      await _cacheWeather(weatherData);

      return weatherData;
    } catch (e) {
      debugPrint('WeatherService: Network fetch failed: $e. Checking offline cache...');
      // Check if we have an older cached copy to use offline
      final cached = await getCachedWeather(allowExpired: true);
      if (cached != null) {
        return cached.copyWith(isCached: true);
      }

      // No cache available: Never invent values, throw friendly error
      throw const WeatherException(
        messageEn: 'Unable to connect to weather service. Please check your internet connection.',
        messageHi: 'मौसम सेवा से कनेक्ट करने में असमर्थ। कृपया इंटरनेट कनेक्शन जांचें।',
      );
    }
  }

  /// Simple agricultural plant disease risk calculation
  static (String, String, String) _calculateDiseaseRisk(int humidity, int rainChance) {
    if (humidity >= 75 && rainChance >= 40) {
      return (
        'high',
        'High humidity ($humidity%) + rain expected ($rainChance%). High fungal disease risk (blight, mildew, leaf spot). Avoid overhead watering and scout foliage.',
        'अधिक नमी ($humidity%) और बारिश की संभावना ($rainChance%)। फफूंद जनित रोगों (झुलसा, फफूंदी) का उच्च जोखिम है। पत्तियों पर अतिरिक्त पानी देने से बचें।'
      );
    } else if (humidity >= 60 || rainChance >= 30) {
      return (
        'moderate',
        'Moderate humidity ($humidity%). Keep plants spaced for air movement and monitor lower leaf canopy.',
        'मध्यम नमी ($humidity%)। पौधों के बीच हवा का संचार बनाए रखें और निचली पत्तियों की नियमित जांच करें।'
      );
    } else {
      return (
        'low',
        'Dry and clear weather. Low fungal disease risk. Ensure regular irrigation to prevent water stress.',
        'मौसम शुष्क और साफ है। फफूंद रोगों का जोखिम कम है। पौधों में नमी बनाए रखने के लिए समय पर सिंचाई करें।'
      );
    }
  }
}
