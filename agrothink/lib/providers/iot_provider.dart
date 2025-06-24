import 'package:flutter/material.dart';
import 'package:agrothink/services/weather_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';
import 'dart:convert';

enum IotStatus {
  initial,
  dataLoading,
  dataLoaded,
  insightsLoading,
  insightsLoaded,
  error,
}

class IotProvider extends ChangeNotifier {
  IotStatus _status = IotStatus.initial;
  String? _rawInsights;
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _sensorData;
  String? _locationName;
  int? _healthScore;
  int? _diseaseOutbreakChance;
  String? _errorMessage;

  final String _geminiApiKey = 'AIzaSyC1iVm3TcG4Hva7kgVBIDO36NYxKIBFy0w';
  final String _weatherApiKey = '7c2e8b471cce4525904413736a6d27a5';

  IotStatus get status => _status;
  String? get rawInsights => _rawInsights;
  Map<String, dynamic>? get weatherData => _weatherData;
  Map<String, dynamic>? get sensorData => _sensorData;
  String? get locationName => _locationName;
  int? get healthScore => _healthScore;
  int? get diseaseOutbreakChance => _diseaseOutbreakChance;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInitialData(
    String cropName, {
    Map<String, dynamic>? manualSensorData,
  }) async {
    _status = IotStatus.dataLoading;
    _healthScore = null;
    _diseaseOutbreakChance = null;
    _rawInsights = null;
    notifyListeners();

    try {
      final weatherService = WeatherService(_weatherApiKey);
      _weatherData = await weatherService.getWeather('Johor Bahru');
      _locationName = _weatherData?['name'];
      _sensorData = manualSensorData ?? _generateMockSensorData();

      _status = IotStatus.dataLoaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch initial data: ${e.toString()}';
      _status = IotStatus.error;
      notifyListeners();
    }
  }

  Future<void> generateInsights(String cropName) async {
    if (_weatherData == null || _sensorData == null) {
      _errorMessage = "Cannot generate insights without data.";
      _status = IotStatus.error;
      notifyListeners();
      return;
    }

    _status = IotStatus.insightsLoading;
    _rawInsights = ""; // Reset for streaming
    notifyListeners();

    try {
      final gemini = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final prompt = _buildPrompt(cropName, _weatherData!, _sensorData!);
      final stream = gemini.generateContentStream([Content.text(prompt)]);

      var accumulatedResponse = StringBuffer();

      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null) {
          accumulatedResponse.write(text);
          _rawInsights = accumulatedResponse.toString();
          notifyListeners();
        }
      }

      // Once streaming is done, parse the complete response for the scores
      _parseGeminiResponse(accumulatedResponse.toString());
      _status = IotStatus.insightsLoaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch insights: ${e.toString()}';
      _status = IotStatus.error;
      notifyListeners();
    }
  }

  void _parseGeminiResponse(String? responseText) {
    if (responseText == null) {
      _rawInsights = "No response from AI.";
      _healthScore = null;
      _diseaseOutbreakChance = null;
      return;
    }

    // Parse Health Score
    final healthScoreRegex = RegExp(
      r'health_score:\s*(\d+)',
      caseSensitive: false,
    );
    final healthMatch = healthScoreRegex.firstMatch(responseText);
    if (healthMatch != null) {
      _healthScore = int.tryParse(healthMatch.group(1) ?? '');
    } else {
      _healthScore = null;
    }

    // Parse Disease Chance
    final diseaseRegex = RegExp(
      r'disease_outbreak_chance:\s*(\d+)',
      caseSensitive: false,
    );
    final diseaseMatch = diseaseRegex.firstMatch(responseText);
    if (diseaseMatch != null) {
      _diseaseOutbreakChance = int.tryParse(diseaseMatch.group(1) ?? '');
    } else {
      _diseaseOutbreakChance = null;
    }

    // Clean the raw text
    _rawInsights =
        responseText
            .replaceAll(healthScoreRegex, '')
            .replaceAll(diseaseRegex, '')
            .trim();
  }

  Map<String, dynamic> _generateMockSensorData() {
    final random = Random();
    return {
      'soil_moisture': (random.nextDouble() * 60 + 20).toStringAsFixed(2), // %
      'temperature': (random.nextDouble() * 15 + 20).toStringAsFixed(
        2,
      ), // Celsius
    };
  }

  String _buildPrompt(
    String cropName,
    Map<String, dynamic> weatherData,
    Map<String, dynamic> sensorData,
  ) {
    final location = _locationName ?? 'Johor Bahru, Malaysia';
    return """
    As an expert agricultural AI, provide a clear and easy-to-read assessment for growing $cropName.

    **Current Conditions:**
    - **Crop:** $cropName
    - **Location:** $location
    - **Weather:** ${weatherData['main']['temp']}°C, ${weatherData['main']['humidity']}% humidity, ${weatherData['weather'][0]['description']}
    - **Sensor Data:** Soil Moisture at ${sensorData['soil_moisture']}%, Soil Temperature at ${sensorData['temperature']}°C

    **Instructions:**
    - **DO NOT** use tables or markdown table format.
    - **DO NOT** include a JSON output.
    - Write your analysis in simple paragraphs with clear headers.
    - Use bold text for headers by using asterisks, like **This is a Header**.
    - At the end of the "Overall Health Assessment" section, you **MUST** include a line with the health score in the exact format: `health_score: [number]`. For example: `health_score: 85`.
    - At the end of the "Future Predictions" section, you **MUST** include a line with the disease chance in the exact format: `disease_outbreak_chance: [number]`. For example: `disease_outbreak_chance: 25`.

    **Please provide the following sections in your analysis:**

    **1. Overall Health Assessment:**
    Give a summary of the crop's current condition and a health score out of 100. Remember to include the `health_score:` line at the end of this section.

    **2. Score Reasoning:**
    Explain exactly why you provided the specific health score in the previous section.

    **3. Key Insights:**
    Analyze the data and explain what the weather and sensor readings mean for the crop.

    **4. Future Predictions:**
    Based on the current data, predict potential outcomes for the crop in the near future (e.g., risk of disease, growth spurt potential). Remember to include the `disease_outbreak_chance:` line at the end of this section.

    **5. Disease Outbreak Reasoning:**
    Explain exactly why you provided the specific disease outbreak chance in the previous section, based on the data.

    **6. Actionable Recommendations:**
    Provide a list of clear, practical steps the farmer should take to improve the crop's health and yield.
    """;
  }
}
