import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraStatus {
  final bool isConnected;
  final bool isConnecting;
  final bool isMonitoring;
  final bool usePhoneCamera;

  CameraStatus({
    this.isConnected = false,
    this.isConnecting = false,
    this.isMonitoring = false,
    this.usePhoneCamera = false,
  });

  CameraStatus copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isMonitoring,
    bool? usePhoneCamera,
  }) {
    return CameraStatus(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      usePhoneCamera: usePhoneCamera ?? this.usePhoneCamera,
    );
  }
}

class CameraStatusNotifier extends StateNotifier<CameraStatus> {
  CameraStatusNotifier() : super(CameraStatus());

  void setConnected(bool connected) {
    state = state.copyWith(isConnected: connected);
  }

  void setConnecting(bool connecting) {
    state = state.copyWith(isConnecting: connecting);
  }

  void setMonitoring(bool monitoring) {
    state = state.copyWith(isMonitoring: monitoring);
  }

  void setUsePhoneCamera(bool usePhone) {
    state = state.copyWith(usePhoneCamera: usePhone);
  }

  void reset() {
    state = CameraStatus();
  }
}

final cameraStatusProvider =
    StateNotifierProvider<CameraStatusNotifier, CameraStatus>((ref) {
  return CameraStatusNotifier();
});

final fatigueLevelProvider = StateProvider<String>((ref) => 'Low');
final drivingDurationProvider = StateProvider<Duration>((ref) => Duration.zero);
