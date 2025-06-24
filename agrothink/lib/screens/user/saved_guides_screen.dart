import 'dart:convert';
import 'package:agrothink/models/structured_guide_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/models/saved_guide_model.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/providers/planting_guide_provider.dart';
import 'package:agrothink/providers/saved_guides_provider.dart';

class SavedGuidesScreen extends StatelessWidget {
  const SavedGuidesScreen({Key? key}) : super(key: key);

  static const String routeName = '/user/saved-guides';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Planting Guides'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<SavedGuidesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.guides.isEmpty) {
            return const Center(
                child: Text('You have no saved guides yet.'));
          }

          final guides = provider.guides;

          return ListView.builder(
            itemCount: guides.length,
            itemBuilder: (context, index) {
              final guide = guides[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(guide.seedName),
                  subtitle: Text(
                    'Saved on ${guide.createdAt.toLocal().toString().split(' ')[0]}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.errorColor),
                    onPressed: () => _showDeleteConfirmation(context, guide.id!),
                  ),
                  onTap: () {
                    try {
                      // Clean the JSON string if needed
                      final cleanedJson = guide.guide
                          .replaceAll('```json', '')
                          .replaceAll('```', '')
                          .trim();
                      final structuredGuide =
                          StructuredPlantingGuide.fromJson(
                              jsonDecode(cleanedJson));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SavedGuideDetailScreen(guide: structuredGuide),
                        ),
                      );
                    } catch (e) {
                      // Fallback for older, non-JSON guides
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(guide.seedName),
                          content: SingleChildScrollView(
                            child: Text(guide.guide),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            )
                          ],
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String guideId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this guide? All related to-do tasks will also be deleted. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.errorColor)),
              onPressed: () {
                final provider =
                    Provider.of<SavedGuidesProvider>(context, listen: false);
                provider.deleteGuide(guideId);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Guide and associated tasks deleted'),
                      backgroundColor: Colors.green),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class SavedGuideDetailScreen extends StatelessWidget {
  final StructuredPlantingGuide guide;

  const SavedGuideDetailScreen({Key? key, required this.guide})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.seedName),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guide.region,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey)),
            const SizedBox(height: 16),
            _buildExpansionTile('Timeline', [
              ListTile(
                  title: const Text('Duration'),
                  subtitle: Text(guide.timeline.duration)),
              ListTile(
                  title: const Text('Best Time to Plant'),
                  subtitle: Text(guide.timeline.bestTimeToPlant)),
            ]),
            _buildExpansionTile(
                'Pre-Planting Tasks',
                guide.prePlantingTasks
                    .map((task) => ListTile(
                        title: Text(task.task),
                        subtitle: Text(task.description)))
                    .toList()),
            _buildExpansionTile(
                'Planting Tasks',
                guide.plantingTasks
                    .map((task) => ListTile(
                        title: Text(task.task),
                        subtitle: Text(task.description)))
                    .toList()),
            _buildExpansionTile(
                'Post-Planting Tasks',
                guide.postPlantingTasks
                    .map((task) => ListTile(
                        title: Text(task.task),
                        subtitle: Text(task.description)))
                    .toList()),
            const SizedBox(height: 16),
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(guide.summary),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile(String title, List<Widget> children) {
    return ExpansionTile(
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      children: children,
    );
  }
} 