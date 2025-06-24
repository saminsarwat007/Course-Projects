import 'package:flutter/material.dart';

class IotDeviceScreen extends StatefulWidget {
  static const String routeName = '/iot-device';

  const IotDeviceScreen({Key? key}) : super(key: key);

  @override
  _IotDeviceScreenState createState() => _IotDeviceScreenState();
}

class _IotDeviceScreenState extends State<IotDeviceScreen> {
  final _cropNameController = TextEditingController();
  final _soilMoistureController = TextEditingController();
  final _soilTemperatureController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showManualInputs = false;

  void _navigateToDashboard() {
    if (_cropNameController.text.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    Navigator.pushNamed(
      context,
      '/data-dashboard',
      arguments: {'cropName': _cropNameController.text},
    );
  }

  void _analyzeManualData() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushNamed(
        context,
        '/data-dashboard',
        arguments: {
          'cropName': _cropNameController.text,
          'manualSensorData': {
            'soil_moisture': _soilMoistureController.text,
            'temperature': _soilTemperatureController.text,
          },
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Your Crop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '1. Enter Crop Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                  labelText: 'e.g., Tomato, Rice',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a crop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '2. Choose Data Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.sensors),
                  title: const Text('AgroSensor-1 (Mock)'),
                  trailing: ElevatedButton(
                    onPressed: _navigateToDashboard,
                    child: const Text('Analyze'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!_showManualInputs)
                TextButton(
                  onPressed: () => setState(() => _showManualInputs = true),
                  child: const Text('Or enter data manually'),
                ),
              if (_showManualInputs) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _soilMoistureController,
                  decoration: const InputDecoration(
                    labelText: 'Soil Moisture (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _soilTemperatureController,
                  decoration: const InputDecoration(
                    labelText: 'Soil Temperature (°C)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _analyzeManualData,
                  child: const Text('Analyze Manual Data'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _soilMoistureController.dispose();
    _soilTemperatureController.dispose();
    super.dispose();
  }
}
