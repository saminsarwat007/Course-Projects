import 'dart:convert';
import 'dart:io';
import 'package:agrothink/models/structured_guide_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrothink/providers/planting_guide_provider.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/providers/location_provider.dart';

class PlantingGuideScreen extends StatefulWidget {
  const PlantingGuideScreen({Key? key}) : super(key: key);

  static const String routeName = '/user/planting-guide';

  @override
  State<PlantingGuideScreen> createState() => _PlantingGuideScreenState();
}

class _PlantingGuideScreenState extends State<PlantingGuideScreen> {
  final _textController = TextEditingController();

  void _generateGuide() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final plantingGuideProvider = Provider.of<PlantingGuideProvider>(
      context,
      listen: false,
    );

    locationProvider.fetchLocation().then((_) {
      if (locationProvider.status == LocationStatus.success) {
        plantingGuideProvider.generateGuide(
          seedName: _textController.text,
          location: locationProvider.currentPosition,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not fetch location: ${locationProvider.errorMessage}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planting Guide Generator'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputSection(),
              const SizedBox(height: 24),
              _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Provide Seed Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter Seed Name',
                hintText: 'e.g., "Tomato", "Wheat"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('OR'),
            const SizedBox(height: 12),
            Consumer<PlantingGuideProvider>(
              builder: (context, provider, child) {
                if (provider.image != null) {
                  return _buildImagePreview(provider);
                } else {
                  return _buildImagePickerButtons();
                }
              },
            ),
            const SizedBox(height: 20),
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return ElevatedButton.icon(
                  icon:
                      locationProvider.status == LocationStatus.loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.eco),
                  label: const Text('Generate Guide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed:
                      locationProvider.status == LocationStatus.loading
                          ? null
                          : _generateGuide,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('From Camera'),
          onPressed: () {
            Provider.of<PlantingGuideProvider>(
              context,
              listen: false,
            ).pickImage(ImageSource.camera);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('From Gallery'),
          onPressed: () {
            Provider.of<PlantingGuideProvider>(
              context,
              listen: false,
            ).pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  Widget _buildImagePreview(PlantingGuideProvider provider) {
    return Column(
      children: [
        Image.file(provider.image!, height: 150, width: 150, fit: BoxFit.cover),
        TextButton.icon(
          icon: const Icon(Icons.close),
          label: const Text('Remove Image'),
          onPressed: provider.clearImage,
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Consumer<PlantingGuideProvider>(
      builder: (context, provider, child) {
        switch (provider.status) {
          case PlantingGuideStatus.initial:
            return const Center(
              child: Text('Enter a seed name or provide an image to start.'),
            );
          case PlantingGuideStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case PlantingGuideStatus.error:
            return Center(
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          case PlantingGuideStatus.success:
            if (provider.structuredGuide == null) {
              return const Center(child: Text('Failed to parse the guide.'));
            }
            return _buildStructuredGuide(provider.structuredGuide!);
        }
      },
    );
  }

  Widget _buildStructuredGuide(StructuredPlantingGuide guide) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guide.seedName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              guide.region,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildExpansionTile('Timeline', [
              ListTile(
                title: const Text('Duration'),
                subtitle: Text(guide.timeline.duration),
              ),
              ListTile(
                title: const Text('Best Time to Plant'),
                subtitle: Text(guide.timeline.bestTimeToPlant),
              ),
            ]),
            _buildExpansionTile(
              'Pre-Planting Tasks',
              guide.prePlantingTasks
                  .map(
                    (task) => ListTile(
                      title: Text(task.task),
                      subtitle: Text(task.description),
                    ),
                  )
                  .toList(),
            ),
            _buildExpansionTile(
              'Planting Tasks',
              guide.plantingTasks
                  .map(
                    (task) => ListTile(
                      title: Text(task.task),
                      subtitle: Text(task.description),
                    ),
                  )
                  .toList(),
            ),
            _buildExpansionTile(
              'Post-Planting Tasks',
              guide.postPlantingTasks
                  .map(
                    (task) => ListTile(
                      title: Text(task.task),
                      subtitle: Text(task.description),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(guide.summary),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Guide'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final plantingProvider = Provider.of<PlantingGuideProvider>(
                  context,
                  listen: false,
                );
                final user = authProvider.user;
                if (user != null) {
                  plantingProvider.saveGuide(
                    userId: user.uid,
                    seedName:
                        _textController.text.isNotEmpty
                            ? _textController.text
                            : guide.seedName,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Guide saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You must be logged in to save.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile(String title, List<Widget> children) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: children,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
