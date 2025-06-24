import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/config/constants.dart';
import 'package:agrothink/config/routes.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/widgets/feature_card.dart';
import 'package:agrothink/screens/profile/profile_screen.dart';
import 'package:agrothink/providers/feature_toggle_provider.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  UserDashboardScreenState createState() => UserDashboardScreenState();
}

class UserDashboardScreenState extends State<UserDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, user?.name ?? 'User'),
            Expanded(child: _buildFeatureGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              _buildProfileMenu(context),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hello, $userName!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'What would you like to do today?',
            style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.person_outline, color: AppTheme.textColor),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.pushNamed(context, ProfileScreen.routeName);
            break;
          case 'saved_guides':
            Navigator.pushNamed(context, AppRoutes.savedGuides);
            break;
          case 'settings':
            // In a real app, navigate to settings screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings would be implemented here'),
              ),
            );
            break;
          case 'logout':
            _showLogoutDialog(context);
            break;
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: AppTheme.textColor),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'saved_guides',
              child: Row(
                children: [
                  Icon(Icons.save, color: AppTheme.textColor),
                  SizedBox(width: 12),
                  Text('Saved Guides'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppTheme.textColor),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.errorColor),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Define dashboard features
    final List<Map<String, dynamic>> allFeatures = [
      {
        'id': 'todoList',
        'title': 'To-Do List',
        'description': 'Manage your farming tasks and schedule.',
        'icon': Icons.check_circle_outline,
        'color': Colors.indigo,
        'route': AppRoutes.todoList,
      },
      {
        'id': 'cropMonitor',
        'title': 'Crop Monitor',
        'description': 'Monitor your crops with IoT devices and get insights.',
        'icon': Icons.sensors,
        'color': Colors.purple,
        'route': AppRoutes.iotDevice,
      },
      {
        'id': 'diseaseDetection',
        'title': AppConstants.diseaseDetectionTitle,
        'description':
            'Upload crop images to detect diseases and get treatment recommendations.',
        'icon': Icons.camera_alt_outlined,
        'color': Colors.orange,
        'route': AppRoutes.diseaseDetection,
      },
      {
        'id': 'chatbot',
        'title': AppConstants.chatbotTitle,
        'description':
            'Get instant farming guidance through our AI-powered chatbot.',
        'icon': Icons.chat_bubble_outlined,
        'color': Colors.green,
        'route': AppRoutes.chatbot,
      },
      {
        'id': 'newsFeed',
        'title': AppConstants.newsFeedTitle,
        'description':
            'Stay updated with the latest agricultural news, weather warnings, and price alerts.',
        'icon': Icons.feed_outlined,
        'color': Colors.blue,
        'route': AppRoutes.newsFeed,
      },
    ];

    if (user != null && !user.isGovernment) {
      allFeatures.insert(0, {
        'id': 'plantingGuide',
        'title': AppConstants.plantingGuideTitle,
        'description':
            'Get a planting guide for your seeds with a proper timeline.',
        'icon': Icons.eco_outlined,
        'color': Colors.teal,
        'route': AppRoutes.plantingGuide,
      });
    }

    return Consumer<FeatureToggleProvider>(
      builder: (context, toggleProvider, child) {
        final enabledFeatures =
            allFeatures.where((feature) {
              // If the feature is not in the toggle map, default to showing it.
              // This is a safeguard for when new features are added.
              return toggleProvider.featureToggles[feature['id']] ?? true;
            }).toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: enabledFeatures.length,
            itemBuilder: (context, index) {
              final feature = enabledFeatures[index];
              return FeatureCard(
                title: feature['title'],
                description: feature['description'],
                icon: feature['icon'],
                color: feature['color'],
                onTap: () {
                  Navigator.pushNamed(context, feature['route']);
                },
                animationIndex: index,
              );
            },
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  authProvider.signOut().then((_) {
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  });
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
    );
  }
}
