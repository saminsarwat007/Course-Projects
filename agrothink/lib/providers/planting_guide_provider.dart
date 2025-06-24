import 'dart:convert';
import 'package:agrothink/models/structured_guide_model.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:agrothink/models/saved_guide_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

enum PlantingGuideStatus { initial, loading, success, error }

class PlantingGuideProvider extends ChangeNotifier {
  PlantingGuideStatus _status = PlantingGuideStatus.initial;
  String? _guide; // Keep for backward compatibility or simple view
  StructuredPlantingGuide? _structuredGuide;
  String? _errorMessage;
  File? _image;
  final AuthProvider? _authProvider;

  final _gemini = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyC1iVm3TcG4Hva7kgVBIDO36NYxKIBFy0w', // Same key as chatbot
  );

  // Getters
  PlantingGuideStatus get status => _status;
  String? get guide => _guide;
  StructuredPlantingGuide? get structuredGuide => _structuredGuide;
  String? get errorMessage => _errorMessage;
  File? get image => _image;

  PlantingGuideProvider(this._authProvider);

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      _status = PlantingGuideStatus.error;
      notifyListeners();
    }
  }

  void clearImage() {
    _image = null;
    notifyListeners();
  }

  Future<void> generateGuide(
      {String? seedName, Position? location}) async {
    if ((seedName == null || seedName.trim().isEmpty) && _image == null) {
      _errorMessage = 'Please provide a seed name or an image.';
      _status = PlantingGuideStatus.error;
      notifyListeners();
      return;
    }

    if (location == null) {
      _errorMessage = 'Location is required to generate a guide.';
      _status = PlantingGuideStatus.error;
      notifyListeners();
      return;
    }

    _status = PlantingGuideStatus.loading;
    _guide = null;
    _structuredGuide = null;
    _errorMessage = null;
    notifyListeners();

    try {
      String prompt;
      GenerateContentResponse response;

      final locationString =
          'Latitude: ${location.latitude}, Longitude: ${location.longitude}';
      final promptSuffix =
          'Generate a detailed planting guide for the location: $locationString. Respond ONLY in JSON format. The root object must have these keys: "seed_name" (string), "region" (string), "timeline" (object with "duration" (string) and "best_time_to_plant" (string)), "pre_planting_tasks" (array of objects, each with "task" (string) and "description" (string)), "planting_tasks" (array of objects, each with "task" (string) and "description" (string)), "post_planting_tasks" (array of objects, each with "task" (string) and "description" (string)), and "summary" (string). Ensure all string values are properly quoted and there is no text outside the JSON object.';

      if (_image != null) {
        final imageBytes = await _image!.readAsBytes();
        final imagePart = DataPart('image/jpeg', imageBytes);
        prompt = 'Identify the seed in the image. $promptSuffix';
        response = await _gemini
            .generateContent([Content.multi([TextPart(prompt), imagePart])]);
      } else {
        prompt = 'Seed name: "$seedName". $promptSuffix';
        response = await _gemini.generateContent([Content.text(prompt)]);
      }

      final guideText = response.text;
      if (guideText == null) {
        _errorMessage = 'Received no response from AI.';
        _status = PlantingGuideStatus.error;
      } else {
        // Clean the response from markdown backticks if present
        final cleanedJson =
            guideText.replaceAll('```json', '').replaceAll('```', '').trim();
        _structuredGuide =
            StructuredPlantingGuide.fromJson(jsonDecode(cleanedJson));
        _guide =
            guideText; // Store raw text for saving or simple display if needed
        _status = PlantingGuideStatus.success;
      }
    } catch (e) {
      _errorMessage = 'Failed to generate guide: ${e.toString()}';
      _status = PlantingGuideStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveGuide(
      {required String userId, required String seedName}) async {
    if (_guide == null) return;

    try {
      final newGuide = SavedGuideModel(
        userId: userId,
        seedName: seedName,
        guide: _guide!, // Save the raw JSON string
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('saved_guides')
          .add(newGuide.toMap());
    } catch (e) {
      // Optionally handle save error
      print('Error saving guide: $e');
    }
  }

  Future<void> deleteGuide(String guideId) async {
    try {
      await FirebaseFirestore.instance
          .collection('saved_guides')
          .doc(guideId)
          .delete();
    } catch (e) {
      print('Error deleting guide: $e');
      // Optionally notify listeners of an error
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == PlantingGuideStatus.error) {
      _status = PlantingGuideStatus.initial;
    }
    notifyListeners();
  }
} 