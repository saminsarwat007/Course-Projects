import 'package:flutter/material.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:agrothink/config/theme.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/providers/admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:agrothink/providers/feature_toggle_provider.dart';

class GovernmentControlsScreen extends StatelessWidget {
  const GovernmentControlsScreen({Key? key}) : super(key: key);

  static const String routeName = '/government/controls';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Government App Controls'),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureToggles(context),
            const Divider(height: 32, thickness: 1),
            _buildUserManagement(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggles(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feature Toggles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Consumer<FeatureToggleProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: provider.featureToggles.entries.map((entry) {
                  return SwitchListTile(
                    title: Text(_formatFeatureName(entry.key)),
                    value: entry.value,
                    onChanged: (bool value) {
                      provider.updateToggle(entry.key, value);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatFeatureName(String key) {
    // Simple formatter: 'plantingGuide' -> 'Planting Guide'
    return key
        .replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'),
            (Match m) => ' ${m.group(0)}')
        .capitalize();
  }

  Widget _buildUserManagement(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Consumer<AdminProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.users.isEmpty) {
                return const Center(
                  child: Text('No users found.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.users.length,
                itemBuilder: (context, index) {
                  final user = provider.users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: const Icon(Icons.person,
                            color: AppTheme.primaryColor),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.errorColor),
                        onPressed: () {
                          _showDeleteConfirmation(context, user.uid);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this user? This will only remove their Firestore data for now. Full account deletion requires a backend function.'),
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
                    Provider.of<AdminProvider>(context, listen: false);
                provider.deleteUser(userId);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('User data deleted from Firestore.'),
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 