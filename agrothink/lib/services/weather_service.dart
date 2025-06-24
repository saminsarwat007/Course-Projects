import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey;
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  WeatherService(this.apiKey);

  Future<Map<String, dynamic>> getWeather(String city) async {
    final url = '$_baseUrl?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
