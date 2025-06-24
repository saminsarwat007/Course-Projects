import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeatureToggleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _docPath = 'app_settings/feature_toggles';

  Map<String, bool> _featureToggles = {
    'plantingGuide': true,
    'diseaseDetection': true,
  };
  Map<String, bool> get featureToggles => _featureToggles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FeatureToggleProvider() {
    fetchFeatureToggles();
  }

  Future<void> fetchFeatureToggles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.doc(_docPath).get();
      if (doc.exists && doc.data() != null) {
        _featureToggles = Map<String, bool>.from(doc.data()!);
      }
    } catch (e) {
      print('Error fetching feature toggles: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateToggle(String featureName, bool isEnabled) async {
    _featureToggles[featureName] = isEnabled;
    notifyListeners();

    try {
      await _firestore.doc(_docPath).set(
        {featureName: isEnabled},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating toggle for $featureName: $e');
      // Optionally revert the change on error
      _featureToggles[featureName] = !isEnabled;
      notifyListeners();
    }
  }
} 