import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:agrothink/models/disease_detection_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:agrothink/providers/auth_provider.dart';

enum DiseaseDetectionStatus { initial, loading, analyzing, complete, error }

class DiseaseDetectionProvider extends ChangeNotifier {
  DiseaseDetectionStatus _status = DiseaseDetectionStatus.initial;
  File? _selectedImage;
  DiseaseDetectionModel? _detectionResult;
  List<DiseaseDetectionModel> _pastDetections = [];
  String? _errorMessage;
  final AuthProvider? _authProvider;

  // Gemini Vision Model
  final _geminiVisionModel = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyC1iVm3TcG4Hva7kgVBIDO36NYxKIBFy0w',
    safetySettings: [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    ],
  );

  // Getters
  DiseaseDetectionStatus get status => _status;
  File? get selectedImage => _selectedImage;
  DiseaseDetectionModel? get detectionResult => _detectionResult;
  List<DiseaseDetectionModel> get pastDetections => _pastDetections;
  String? get errorMessage => _errorMessage;

  // Constructor
  DiseaseDetectionProvider(this._authProvider) {
    // _loadPastDetections(); // Past detections will be loaded based on user now.
  }

  // Load past detections (mock data for UI development)
  Future<void> _loadPastDetections() async {
    _pastDetections = DiseaseDetectionModel.getMockData();
    notifyListeners();
  }

  // Set the selected image for analysis
  void setSelectedImage(File image) {
    _selectedImage = image;
    _detectionResult = null;
    _status = DiseaseDetectionStatus.initial;
    notifyListeners();
  }

  // Clear the selected image
  void clearSelectedImage() {
    _selectedImage = null;
    _detectionResult = null;
    _status = DiseaseDetectionStatus.initial;
    notifyListeners();
  }

  // Analyze the selected image for disease detection
  Future<bool> analyzeImage() async {
    if (_selectedImage == null) {
      _errorMessage = 'No image selected';
      _status = DiseaseDetectionStatus.error;
      notifyListeners();
      return false;
    }

    _status = DiseaseDetectionStatus.loading;
    notifyListeners();

    try {
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final prompt = TextPart(
        "Analyze the provided image of a plant. Identify the plant/crop type, the disease (if any), provide a detailed description of the disease symptoms visible, and list 2-3 practical treatment recommendations. Respond ONLY in JSON format with the following keys: \"cropType\" (string), \"diseaseName\" (string), \"description\" (string), \"treatments\" (list of strings). If no disease is detected or the image is not a plant, set \"diseaseName\" to an appropriate value like 'Healthy' or 'Not a plant', and provide a relevant description. Ensure treatments is an empty list if not applicable.",
      );

      _status = DiseaseDetectionStatus.analyzing;
      notifyListeners();

      final response = await _geminiVisionModel.generateContent([
        Content.multi([prompt, imagePart]),
      ]);
      final String? rawJson = response.text;

      if (rawJson == null || rawJson.isEmpty) {
        _errorMessage = 'Received no response or empty response from AI.';
        _status = DiseaseDetectionStatus.error;
        notifyListeners();
        return false;
      }

      // Attempt to parse the JSON response
      Map<String, dynamic> resultData;
      try {
        // Gemini might sometimes wrap its JSON in ```json ... ```, so we clean that.
        String cleanedJson = rawJson.trim();
        if (cleanedJson.startsWith('```json')) {
          cleanedJson = cleanedJson.substring(7);
        }
        if (cleanedJson.endsWith('```')) {
          cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
        }
        resultData = jsonDecode(cleanedJson);
      } catch (e) {
        _errorMessage = 'Failed to parse AI response. Raw: $rawJson';
        _status = DiseaseDetectionStatus.error;
        notifyListeners();
        return false;
      }

      _detectionResult = DiseaseDetectionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: _selectedImage!.path,
        cropType: resultData['cropType'] as String? ?? 'Unknown',
        diseaseName: resultData['diseaseName'] as String? ?? 'Error in parsing',
        description: resultData['description'] as String? ?? 'Error in parsing',
        treatments:
            (resultData['treatments'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .toList(),
        detectedAt: DateTime.now(),
        detectedBy: 'gemini-1.5-flash',
      );

      _pastDetections.insert(0, _detectionResult!);

      _status = DiseaseDetectionStatus.complete;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to analyze image with AI: ${e.toString()}';
      _status = DiseaseDetectionStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Clear any errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
