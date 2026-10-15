import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantii/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const sampleForecastJson = '''
{
  "latitude": 28.6139,
  "longitude": 77.2090,
  "current": {
    "temperature_2m": 29.5,
    "relative_humidity_2m": 82,
    "precipitation_probability": 65,
    "wind_speed_10m": 14.2,
    "weather_code": 61
  },
  "daily": {
    "time": ["2026-10-14", "2026-10-15", "2026-10-16", "2026-10-17"],
    "temperature_2m_max": [31.0, 30.5, 28.0, 29.0],
    "temperature_2m_min": [24.0, 23.5, 21.0, 22.0],
    "precipitation_probability_max": [70, 60, 45, 10],
    "weather_code": [61, 63, 3, 1]
  }
}
''';

  const dryForecastJson = '''
{
  "latitude": 28.6139,
  "longitude": 77.2090,
  "current": {
    "temperature_2m": 33.0,
    "relative_humidity_2m": 42,
    "precipitation_probability": 5,
    "wind_speed_10m": 8.0,
    "weather_code": 0
  },
  "daily": {
    "time": ["2026-10-14", "2026-10-15", "2026-10-16", "2026-10-17"],
    "temperature_2m_max": [34.0, 35.0, 34.5, 33.0],
    "temperature_2m_min": [22.0, 23.0, 22.5, 21.0],
    "precipitation_probability_max": [10, 5, 0, 0],
    "weather_code": [0, 0, 1, 0]
  }
}
''';

  const sampleGeocodingJson = '''
{
  "results": [
    {
      "name": "Pune",
      "latitude": 18.5204,
      "longitude": 73.8567,
      "admin1": "Maharashtra",
      "country": "India"
    },
    {
      "name": "Nashik",
      "latitude": 19.9975,
      "longitude": 73.7898,
      "admin1": "Maharashtra",
      "country": "India"
    }
  ]
}
''';

  group('WeatherService Unit Tests with Mocked API Responses', () {
    test('parses live forecast, temperature, humidity, wind, and 3-day forecast accurately', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        expect(request.url.host, 'api.open-meteo.com');
        return http.Response(sampleForecastJson, 200, headers: {'content-type': 'application/json'});
      });

      final weatherService = WeatherService(httpClient: mockClient);
      final data = await weatherService.fetchWeather(
        latitude: 28.6139,
        longitude: 77.2090,
        placeName: 'Delhi Central',
      );

      expect(requestCount, 1);
      expect(data.placeName, 'Delhi Central');
      expect(data.temperature, 29.5);
      expect(data.humidity, 82);
      expect(data.rainChance, 65);
      expect(data.windSpeed, 14.2);
      expect(data.weatherCode, 61);
      expect(data.isCached, false);

      // Verify 3-day forecast
      expect(data.forecast.length, 3);
      expect(data.forecast[0].maxTemp, 30.5);
      expect(data.forecast[0].minTemp, 23.5);
      expect(data.forecast[0].rainChance, 60);

      // Verify high disease risk hint due to 82% humidity + 65% rain
      expect(data.diseaseRiskLevel, 'high');
      expect(data.diseaseRiskHintEn, contains('High fungal disease risk'));
      expect(data.diseaseRiskHintHi, contains('फफूंद जनित रोगों'));
    });

    test('calculates low disease risk for dry conditions', () async {
      final mockClient = MockClient((request) async {
        return http.Response(dryForecastJson, 200, headers: {'content-type': 'application/json'});
      });

      final weatherService = WeatherService(httpClient: mockClient);
      final data = await weatherService.fetchWeather(
        latitude: 28.6139,
        longitude: 77.2090,
        placeName: 'Dry Farm',
      );

      expect(data.humidity, 42);
      expect(data.rainChance, 5);
      expect(data.diseaseRiskLevel, 'low');
      expect(data.diseaseRiskHintEn, contains('Low fungal disease risk'));
      expect(data.diseaseRiskHintHi, contains('फफूंद रोगों का जोखिम कम'));
    });

    test('caches result for 30 minutes and serves fresh cache without new HTTP call', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(sampleForecastJson, 200, headers: {'content-type': 'application/json'});
      });

      final weatherService = WeatherService(httpClient: mockClient);

      // First call -> hits API
      final firstResult = await weatherService.fetchWeather(placeName: 'Test Field');
      expect(requestCount, 1);
      expect(firstResult.isCached, false);

      // Second call immediately after -> served from cache
      final secondResult = await weatherService.fetchWeather(placeName: 'Test Field');
      expect(requestCount, 1); // No new request made
      expect(secondResult.temperature, 29.5);

      // Third call with forceRefresh: true -> makes new HTTP call
      final thirdResult = await weatherService.fetchWeather(placeName: 'Test Field', forceRefresh: true);
      expect(requestCount, 2);
      expect(thirdResult.isCached, false);
    });

    test('returns cached copy marked isCached when network fails (offline)', () async {
      bool shouldFail = false;
      final mockClient = MockClient((request) async {
        if (shouldFail) {
          throw http.ClientException('No Internet Connection');
        }
        return http.Response(sampleForecastJson, 200, headers: {'content-type': 'application/json'});
      });

      final weatherService = WeatherService(httpClient: mockClient);

      // Populate initial cache
      await weatherService.fetchWeather(placeName: 'Agri Farm');

      // Now simulate network failure
      shouldFail = true;
      final offlineResult = await weatherService.fetchWeather(placeName: 'Agri Farm', forceRefresh: true);

      expect(offlineResult.isCached, true);
      expect(offlineResult.placeName, 'Agri Farm');
      expect(offlineResult.temperature, 29.5);
    });

    test('never invents values: throws WeatherException when no cache and network fails', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final weatherService = WeatherService(httpClient: mockClient);

      expect(
        () => weatherService.fetchWeather(placeName: 'Uncached Place'),
        throwsA(isA<WeatherException>()),
      );
    });

    test('searches cities using Open-Meteo geocoding API', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'geocoding-api.open-meteo.com');
        expect(request.url.queryParameters['name'], 'Pune');
        return http.Response(sampleGeocodingJson, 200, headers: {'content-type': 'application/json'});
      });

      final weatherService = WeatherService(httpClient: mockClient);
      final cities = await weatherService.searchCities('Pune');

      expect(cities.length, 2);
      expect(cities[0].name, 'Pune');
      expect(cities[0].state, 'Maharashtra');
      expect(cities[0].displayName, 'Pune, Maharashtra');
      expect(cities[0].latitude, 18.5204);
      expect(cities[0].longitude, 73.8567);
    });

    test('saves and retrieves manual location in SharedPreferences', () async {
      final weatherService = WeatherService();
      const city = CityLocation(
        name: 'Nashik',
        state: 'Maharashtra',
        country: 'India',
        latitude: 19.9975,
        longitude: 73.7898,
      );

      expect(await weatherService.getSavedLocation(), isNull);

      await weatherService.saveManualLocation(city);
      final saved = await weatherService.getSavedLocation();

      expect(saved, isNotNull);
      expect(saved!.name, 'Nashik');
      expect(saved.latitude, 19.9975);
      expect(saved.longitude, 73.7898);
    });
  });
}
