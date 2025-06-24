import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class DeviceSelectionScreen extends ConsumerWidget {
  const DeviceSelectionScreen({super.key});

  void _connectCamera(
      BuildContext context, WidgetRef ref, bool usePhoneCamera) async {
    final cameraNotifier = ref.read(cameraStatusProvider.notifier);
    cameraNotifier.setConnecting(true);
    cameraNotifier.setUsePhoneCamera(usePhoneCamera);

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 3));

    cameraNotifier.setConnected(true);
    cameraNotifier.setConnecting(false);

    if (context.mounted) {
      context.go('/camera');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Your Camera'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Lottie.asset(
              'assets/animations/loading.json',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 32),
            Text(
              'Select a device to connect',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildDeviceOption(
              context,
              ref,
              icon: Icons.camera_alt_rounded,
              title: "Samin's Camera",
              subtitle: "Connect to your smart dashboard camera",
              onTap: () => _connectCamera(context, ref, false),
            ),
            const SizedBox(height: 24),
            _buildDeviceOption(
              context,
              ref,
              icon: Icons.phone_android_rounded,
              title: "Turn on Phone Camera",
              subtitle: "Use your phone's built-in camera for monitoring",
              onTap: () => _connectCamera(context, ref, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
