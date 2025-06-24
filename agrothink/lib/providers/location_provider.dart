import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agrothink/services/location_service.dart';

enum LocationStatus { initial, loading, success, error }

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  LocationStatus _status = LocationStatus.initial;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  LocationStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLocation() async {
    _status = LocationStatus.loading;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      _status = LocationStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = LocationStatus.error;
    } finally {
      notifyListeners();
    }
  }
} 