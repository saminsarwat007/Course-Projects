import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:agrothink/config/constants.dart';
import 'package:agrothink/config/routes.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/widgets/feature_card.dart';

class GovernmentDashboardScreen extends StatefulWidget {
  const GovernmentDashboardScreen({Key? key}) : super(key: key);

  @override
  GovernmentDashboardScreenState createState() =>
      GovernmentDashboardScreenState();
}

class GovernmentDashboardScreenState extends State<GovernmentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, user?.name ?? 'Government Official'),
            Expanded(child: _buildFeatureGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "${AppConstants.appName} Gov",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              _buildProfileMenu(context),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hello, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'What information would you like to publish today?',
            style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
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
          case 'logout':
            _showLogoutDialog(context);
            break;
        }
      },
      itemBuilder:
          (context) => [
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
    // Define dashboard features for government users
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Add Food Price',
        'description':
            'Update food price information to be shown to farmers and users.',
        'icon': Icons.monetization_on_outlined,
        'color': Colors.green,
        'route': AppRoutes.foodPriceForm,
      },
      {
        'title': 'Add Weather Warning',
        'description':
            'Post weather warnings and alerts to notify farmers of upcoming conditions.',
        'icon': Icons.cloud_outlined,
        'color': Colors.blue,
        'route': AppRoutes.weatherWarningForm,
      },
      {
        'title': 'Add Agricultural News',
        'description':
            'Share important agricultural news, innovations, and policies.',
        'icon': Icons.article_outlined,
        'color': Colors.orange,
        'route': AppRoutes.newsForm,
      },
      {
        'title': 'View User Feed',
        'description':
            'See what farmers and users are viewing in their news feed.',
        'icon': Icons.preview_outlined,
        'color': Colors.purple,
        'route': AppRoutes.newsFeed,
      },
      {
        'title': 'App Controls',
        'description': 'Manage users and application settings.',
        'icon': Icons.admin_panel_settings_outlined,
        'color': Colors.red,
        'route': AppRoutes.governmentControls,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimationLimiter(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: FeatureCard(
                    title: features[index]['title'],
                    description: features[index]['description'],
                    icon: features[index]['icon'],
                    color: features[index]['color'],
                    onTap: () {
                      Navigator.pushNamed(context, features[index]['route']);
                    },
                    animationIndex: index,
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
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
