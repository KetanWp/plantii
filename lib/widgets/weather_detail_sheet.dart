import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// Modal bottom sheet displaying live Open-Meteo agricultural weather,
/// 3-day forecast, disease risk advisory, and city picker.
class WeatherDetailSheet extends StatefulWidget {
  final WeatherService? weatherService;

  const WeatherDetailSheet({super.key, this.weatherService});

  static Future<void> show(BuildContext context, {WeatherService? weatherService}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.creamBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => WeatherDetailSheet(weatherService: weatherService),
    );
  }

  @override
  State<WeatherDetailSheet> createState() => _WeatherDetailSheetState();
}

class _WeatherDetailSheetState extends State<WeatherDetailSheet> {
  late final WeatherService _weatherService;
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _weatherService = widget.weatherService ?? WeatherService();
    _loadWeather();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _weatherService.fetchWeather(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      }
    } on WeatherException catch (e) {
      if (mounted) {
        final isHindi = Localizations.localeOf(context).languageCode == 'hi';
        setState(() {
          _errorMessage = e.getLocalizedMessage(isHindi ? 'hi' : 'en');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isHindi = Localizations.localeOf(context).languageCode == 'hi';
        setState(() {
          _errorMessage = isHindi
              ? 'मौसम लोड करने में असमर्थ। कृपया पुनः प्रयास करें।'
              : 'Unable to load weather. Please check connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Request location with a friendly explanation dialog before prompting Android permission
  Future<void> _requestGpsLocation() async {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    // 1. Show friendly explanation dialog first
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppTheme.forestGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isHindi ? 'स्थान की अनुमति' : 'Location Permission',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isHindi
              ? 'आपके स्थानीय खेत का सटीक मौसम और फसल रोग जोखिम पूर्वानुमान प्राप्त करने के लिए स्थान की आवश्यकता है।'
              : 'Your location is used to fetch accurate local farm weather and crop disease risk forecasts.',
          style: const TextStyle(fontSize: 15, height: 1.45, color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isHindi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isHindi ? 'अनुमति दें' : 'Allow'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // 2. Request permission via geolocator
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _promptManualCitySearch(
          isHindi
              ? 'स्थान सेवा (GPS) बंद है। कृपया अपना शहर या जिला चुनें।'
              : 'GPS is disabled. Please select your district or city manually.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _promptManualCitySearch(
            isHindi
                ? 'स्थान अनुमति अस्वीकार कर दी गई। कृपया अपना जिला चुनें।'
                : 'Location permission denied. Please choose your city/district manually.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _promptManualCitySearch(
          isHindi
              ? 'स्थान अनुमति स्थायी रूप से बंद है। कृपया अपना जिला चुनें।'
              : 'Location permission permanently denied. Please choose your city manually.',
        );
        return;
      }

      // 3. Obtain GPS position with 10s timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final gpsPlaceName = isHindi ? 'स्थानीय खेत (GPS)' : 'Local Farm (GPS)';
      await _weatherService.saveManualLocation(
        CityLocation(
          name: gpsPlaceName,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );

      _loadWeather(forceRefresh: true);
    } catch (e) {
      debugPrint('Geolocator error: $e');
      if (mounted) {
        _promptManualCitySearch(
          isHindi
              ? 'स्थान प्राप्त करने में समस्या आई। कृपया अपना शहर चुनें।'
              : 'Could not fetch GPS location. Please select your district manually.',
        );
      }
    }
  }

  /// Dialog allowing user to type or pick district/city with Open-Meteo geocoding
  Future<void> _promptManualCitySearch([String? hintMessage]) async {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final TextEditingController searchController = TextEditingController();
    List<CityLocation> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.forestGreen, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHindi ? 'शहर / जिला चुनें' : 'Select City / District',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hintMessage != null) ...[
                    Text(
                      hintMessage,
                      style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isHindi ? 'उदा. लखनऊ, पटना, जयपुर...' : 'e.g. Lucknow, Patna, Jaipur...',
                      prefixIcon: const Icon(Icons.location_city, color: AppTheme.forestGreen),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.forestGreen),
                        onPressed: () async {
                          if (searchController.text.trim().isEmpty) return;
                          setDialogState(() => isSearching = true);
                          final results = await _weatherService.searchCities(searchController.text);
                          setDialogState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onSubmitted: (val) async {
                      if (val.trim().isEmpty) return;
                      setDialogState(() => isSearching = true);
                      final results = await _weatherService.searchCities(val);
                      setDialogState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.forestGreen)),
                    )
                  else if (searchResults.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final city = searchResults[idx];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: AppTheme.forestGreen),
                            title: Text(city.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: city.country != null ? Text(city.country!) : null,
                            onTap: () async {
                              await _weatherService.saveManualLocation(city);
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                              _loadWeather(forceRefresh: true);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(isHindi ? 'बंद करें' : 'Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.only(top: 14, left: 20, right: 20, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Title & Action icons
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.leafGreenSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: AppTheme.forestGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'मौसम एवं फसल रोग पूर्वानुमान' : 'Weather & Crop Advisory',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (_weatherData != null)
                      Text(
                        _weatherData!.placeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isHindi ? 'स्थान खोजें' : 'Change City',
                icon: const Icon(Icons.edit_location_alt_rounded, color: AppTheme.forestGreen),
                onPressed: () => _promptManualCitySearch(),
              ),
              IconButton(
                tooltip: isHindi ? 'GPS स्थान' : 'Use GPS',
                icon: const Icon(Icons.my_location_rounded, color: AppTheme.forestGreen),
                onPressed: _requestGpsLocation,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main body content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.forestGreen))
                : _errorMessage != null
                    ? _buildErrorView(isHindi)
                    : _buildWeatherContentView(isHindi),
          ),
        ],
      ),
    );
  }

  /// Error view with friendly message and retry button
  Widget _buildErrorView(bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: AppTheme.severitySevere),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                isHindi ? 'पुनः प्रयास करें' : 'Retry',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => _loadWeather(forceRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  /// Full weather content view
  Widget _buildWeatherContentView(bool isHindi) {
    final w = _weatherData!;
    final timeStr = DateFormat('hh:mm a').format(w.updatedAt);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cached / Offline warning badge
          if (w.isCached)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.severityMedium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, color: AppTheme.severityMedium, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'ऑफ़लाइन पुराना डेटा (अपडेट: $timeStr)'
                          : 'Old cached data (Updated at $timeStr)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.severityMedium,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '${isHindi ? "अपडेट समय" : "Updated at"} $timeStr',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ),

          // Primary weather metrics card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.forestHeaderGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${w.temperature.round()}°C',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getWeatherConditionName(w.weatherCode, isHindi),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getWeatherEmoji(w.weatherCode),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      Icons.water_drop_outlined,
                      '${w.humidity}%',
                      isHindi ? 'नमी (Humidity)' : 'Humidity',
                    ),
                    _buildMetricItem(
                      Icons.grain_rounded,
                      '${w.rainChance}%',
                      isHindi ? 'बारिश (Rain)' : 'Rain Chance',
                    ),
                    _buildMetricItem(
                      Icons.air_rounded,
                      '${w.windSpeed.round()} km/h',
                      isHindi ? 'हवा (Wind)' : 'Wind',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disease Risk Hint Card
          _buildDiseaseRiskCard(w, isHindi),
          const SizedBox(height: 16),

          // 3-Day Forecast Section
          Text(
            isHindi ? 'आगामी 3 दिनों का पूर्वानुमान' : '3-Day Agricultural Forecast',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          ...w.forecast.map((f) => _buildForecastRow(f, isHindi)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textLightMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDiseaseRiskCard(WeatherData w, bool isHindi) {
    final (Color cardBg, Color borderColor, IconData icon) = switch (w.diseaseRiskLevel) {
      'high' => (const Color(0xFFFFEBEE), AppTheme.severitySevere, Icons.warning_rounded),
      'moderate' => (const Color(0xFFFFF8E1), AppTheme.severityMedium, Icons.info_rounded),
      _ => (const Color(0xFFE8F5E9), AppTheme.forestGreen, Icons.shield_rounded),
    };

    final hintText = isHindi ? w.diseaseRiskHintHi : w.diseaseRiskHintEn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'फसल रोग जोखिम संकेत' : 'Crop Disease Risk Advisory',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hintText,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(DayForecast f, bool isHindi) {
    final dayName = DateFormat('EEE, d MMM').format(f.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
            ),
          ),
          Text(
            _getWeatherEmoji(f.weatherCode),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.grain_rounded, size: 16, color: Color(0xFF1976D2)),
                const SizedBox(width: 4),
                Text(
                  '${f.rainChance}%',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${f.maxTemp.round()}° / ${f.minTemp.round()}°C',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherConditionName(int code, bool isHindi) {
    if (code == 0) return isHindi ? 'साफ आसमान' : 'Clear Sky';
    if (code <= 3) return isHindi ? 'हल्के बादल' : 'Partly Cloudy';
    if (code <= 48) return isHindi ? 'कोहरा' : 'Fog';
    if (code <= 67) return isHindi ? 'बारिश' : 'Rain';
    if (code <= 82) return isHindi ? 'वर्षा की बौछारें' : 'Rain Showers';
    if (code >= 95) return isHindi ? 'गरज के साथ बारिश' : 'Thunderstorm';
    return isHindi ? 'मौसम सामान्य' : 'Fair';
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 82) return '🌦️';
    if (code >= 95) return '⛈️';
    return '🌤️';
  }
}
