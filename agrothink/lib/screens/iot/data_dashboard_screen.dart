import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/providers/iot_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DataDashboardScreen extends StatefulWidget {
  static const String routeName = '/data-dashboard';

  final String cropName;

  const DataDashboardScreen({Key? key, required this.cropName})
    : super(key: key);

  @override
  _DataDashboardScreenState createState() => _DataDashboardScreenState();
}

class _DataDashboardScreenState extends State<DataDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final sensorData = args['manualSensorData'] as Map<String, dynamic>?;

      Provider.of<IotProvider>(
        context,
        listen: false,
      ).fetchInitialData(widget.cropName, manualSensorData: sensorData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data for ${widget.cropName}')),
      body: Consumer<IotProvider>(
        builder: (context, provider, child) {
          if (provider.status == IotStatus.dataLoading ||
              provider.status == IotStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.status == IotStatus.error) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWeatherCard(provider),
                const SizedBox(height: 16),
                _buildSensorCard(provider.sensorData),
                const SizedBox(height: 20),
                if (provider.status == IotStatus.insightsLoaded &&
                    (provider.healthScore != null ||
                        provider.diseaseOutbreakChance != null)) ...[
                  Row(
                    children: [
                      if (provider.healthScore != null)
                        _buildGauge(
                          title: 'Crop Health',
                          score: provider.healthScore!,
                          isHealthScore: true,
                        ),
                      if (provider.diseaseOutbreakChance != null)
                        _buildGauge(
                          title: 'Disease Risk',
                          score: provider.diseaseOutbreakChance!,
                          isHealthScore: false,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // This section handles the button OR the streaming text
                if (provider.status == IotStatus.dataLoaded)
                  ElevatedButton(
                    onPressed: () => provider.generateInsights(widget.cropName),
                    child: const Text('Analyze Insights'),
                  ),

                if (provider.status == IotStatus.insightsLoading ||
                    provider.status == IotStatus.insightsLoaded)
                  _buildInsightsSection(provider.rawInsights),

                if (provider.status == IotStatus.insightsLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(IotProvider provider) {
    final data = provider.weatherData;
    if (data == null)
      return const Card(child: Text('Weather data not available.'));
    final location = provider.locationName ?? 'Unknown Location';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.wb_sunny),
        title: Text('$location - ${data['main']['temp']}°C'),
        subtitle: Text(data['weather'][0]['description']),
        trailing: Text('Humidity: ${data['main']['humidity']}%'),
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic>? data) {
    if (data == null)
      return const Card(child: Text('Sensor data not available.'));
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.thermostat),
            title: const Text('Soil Temperature'),
            trailing: Text('${data['temperature']}°C'),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Soil Moisture'),
            trailing: Text('${data['soil_moisture']}%'),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge({
    required String title,
    required int score,
    required bool isHealthScore,
  }) {
    Color progressColor;
    String statusText;

    if (isHealthScore) {
      // For health, high is good
      if (score > 75) {
        progressColor = Colors.green;
        statusText = 'Good';
      } else if (score > 40) {
        progressColor = Colors.orange;
        statusText = 'Okay';
      } else {
        progressColor = Colors.red;
        statusText = 'Poor';
      }
    } else {
      // For disease risk, high is bad
      if (score > 75) {
        progressColor = Colors.red;
        statusText = 'Very High Risk';
      } else if (score > 40) {
        progressColor = Colors.orange;
        statusText = 'High Risk';
      } else {
        progressColor = Colors.green;
        statusText = 'Low Risk';
      }
    }

    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 12.0,
            percent: score / 100.0,
            center: Text(
              '$score%',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            progressColor: progressColor,
            backgroundColor: Colors.grey.shade300,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(String? rawText) {
    if (rawText == null || rawText.isEmpty) {
      return const Card(child: ListTile(title: Text('No insights generated.')));
    }
    // Split the text into paragraphs and process them.
    final paragraphs = rawText.split('\n').where((p) => p.trim().isNotEmpty);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              paragraphs.map((paragraph) {
                // Check if a line is likely a header (e.g., wrapped in ** or ends with :)
                final isHeader =
                    paragraph.trim().startsWith('**') &&
                    paragraph.trim().endsWith('**');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    // Clean up the text by removing asterisks
                    paragraph.replaceAll('*', '').trim(),
                    style: TextStyle(
                      fontSize: isHeader ? 18 : 15,
                      fontWeight:
                          isHeader ? FontWeight.bold : FontWeight.normal,
                      height: 1.5, // Improves readability
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
