import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../providers/app_providers.dart';
import 'dart:async';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  Timer? _drivingTimer;
  Timer? _fatigueTimer;

  @override
  void initState() {
    super.initState();
    // Start monitoring once connected
    _startMonitoring();
  }

  void _startMonitoring() {
    final cameraStatusNotifier = ref.read(cameraStatusProvider.notifier);
    cameraStatusNotifier.setMonitoring(true);

    // Simulate driving duration
    _drivingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentDuration = ref.read(drivingDurationProvider);
      ref.read(drivingDurationProvider.notifier).state =
          currentDuration + const Duration(seconds: 1);
    });

    // Simulate fatigue level increase
    _fatigueTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final currentFatigue = ref.read(fatigueLevelProvider);
      String newFatigue;
      if (currentFatigue == 'Low') {
        newFatigue = 'Medium';
      } else if (currentFatigue == 'Medium') {
        newFatigue = 'High';
      } else {
        newFatigue = 'High'; // Stay high or implement higher levels
      }
      ref.read(fatigueLevelProvider.notifier).state = newFatigue;

      // Trigger voice alert based on fatigue level (mock)
      if (newFatigue == 'Medium') {
        _showFatigueAlert(context, 'Medium');
      } else if (newFatigue == 'High') {
        _showFatigueAlert(context, 'High');
      }
    });
  }

  void _stopMonitoring() {
    _drivingTimer?.cancel();
    _fatigueTimer?.cancel();
    final cameraStatusNotifier = ref.read(cameraStatusProvider.notifier);
    cameraStatusNotifier.setMonitoring(false);
    cameraStatusNotifier.setConnected(false);
    cameraStatusNotifier.setConnecting(false);
    cameraStatusNotifier.setUsePhoneCamera(false);
    ref.read(drivingDurationProvider.notifier).state = Duration.zero;
    ref.read(fatigueLevelProvider.notifier).state = 'Low';
  }

  void _showFatigueAlert(BuildContext context, String level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fatigue Alert: Level $level! Consider taking a break.'),
        backgroundColor: level == 'High' ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
    // Implement actual voice alert here using flutter_tts if needed
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraStatus = ref.watch(cameraStatusProvider);
    final fatigueLevel = ref.watch(fatigueLevelProvider);
    final drivingDuration = ref.watch(drivingDurationProvider);

    String statusText;
    Color statusColor;
    LottieBuilder? lottieAnimation;

    if (cameraStatus.isConnecting) {
      statusText = 'Connecting to '
          '${cameraStatus.usePhoneCamera ? 'Phone Camera' : "Samin's Camera"}...';
      statusColor = Theme.of(context).colorScheme.tertiary;
      lottieAnimation = Lottie.asset(
        'assets/animations/loading.json',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      );
    } else if (cameraStatus.isConnected && cameraStatus.isMonitoring) {
      statusText = 'AI monitoring activated';
      statusColor = Theme.of(context).colorScheme.primary;
      lottieAnimation = Lottie.asset(
        'assets/animations/loading.json',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ); // You might want a different animation for monitoring
    } else if (cameraStatus.isConnected) {
      statusText = 'Camera connected!';
      statusColor = Theme.of(context).colorScheme.primary;
    } else {
      statusText = 'Not connected';
      statusColor = Theme.of(context).colorScheme.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarBuddy Camera'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopMonitoring();
            context.go('/');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: Center(
                child: cameraStatus.isConnected
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          // This would be the actual camera feed
                          const Icon(
                            Icons.videocam,
                            size: 150,
                            color: Colors.white,
                          ),
                          if (lottieAnimation != null) lottieAnimation,
                        ],
                      )
                    : (lottieAnimation ?? const CircularProgressIndicator()),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (cameraStatus.isConnected && cameraStatus.isMonitoring)
                        Column(
                          children: [
                            _buildInfoCard(
                              context,
                              title: 'Fatigue Level',
                              value: fatigueLevel,
                              icon: Icons.monitor_heart_rounded,
                              color: fatigueLevel == 'High'
                                  ? Colors.red
                                  : (fatigueLevel == 'Medium'
                                      ? Colors.orange
                                      : Colors.green),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              context,
                              title: 'Driving Duration',
                              value: _formatDuration(drivingDuration),
                              icon: Icons.timer,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            _buildSuggestionCard(context, fatigueLevel),
                          ],
                        ),
                    ],
                  ),
                  if (!cameraStatus.isConnected && !cameraStatus.isConnecting)
                    ElevatedButton(
                      onPressed: () => context.go('/select-device'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Reconnect Camera'),
                    ),
                  if (cameraStatus.isConnected && cameraStatus.isMonitoring)
                    ElevatedButton(
                      onPressed: _stopMonitoring,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text('Stop Monitoring'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, String fatigueLevel) {
    String suggestion;
    Color bgColor;

    if (fatigueLevel == 'High') {
      suggestion = 'It is highly recommended to take a rest immediately.';
      bgColor = Colors.red.shade100;
    } else if (fatigueLevel == 'Medium') {
      suggestion = 'Consider taking a short break soon to refresh.';
      bgColor = Colors.orange.shade100;
    } else {
      suggestion = 'Keep up the good work! Stay focused.';
      bgColor = Colors.green.shade100;
    }

    return Card(
      elevation: 2,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline,
                size: 30,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                suggestion,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
