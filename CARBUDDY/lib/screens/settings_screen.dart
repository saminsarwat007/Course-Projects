import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedFrequency = 'Medium';
  bool _enableVoiceAlerts = true;
  bool _enableVibration = true;
  double _sensitivityLevel = 0.5;

  final List<String> _frequencies = ['Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Monitoring Frequency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments:
                        _frequencies
                            .map(
                              (f) => ButtonSegment<String>(
                                value: f,
                                label: Text(f),
                              ),
                            )
                            .toList(),
                    selected: {_selectedFrequency},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedFrequency = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensitivity Level',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _sensitivityLevel,
                    onChanged: (value) {
                      setState(() {
                        _sensitivityLevel = value;
                      });
                    },
                    divisions: 10,
                    label: '${(_sensitivityLevel * 100).round()}%',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Voice Alerts'),
                    subtitle: const Text('Enable voice notifications'),
                    value: _enableVoiceAlerts,
                    onChanged: (value) {
                      setState(() {
                        _enableVoiceAlerts = value;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Vibration Alerts'),
                    subtitle: const Text('Enable vibration notifications'),
                    value: _enableVibration,
                    onChanged: (value) {
                      setState(() {
                        _enableVibration = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
