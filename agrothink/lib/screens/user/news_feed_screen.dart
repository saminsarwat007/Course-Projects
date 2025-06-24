import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/config/constants.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/models/news_model.dart';
import 'package:agrothink/providers/news_provider.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:agrothink/providers/auth_provider.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({Key? key}) : super(key: key);

  @override
  NewsFeedScreenState createState() => NewsFeedScreenState();
}

class NewsFeedScreenState extends State<NewsFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NewsType _selectedCategory = NewsType.agriculturalNews;
  final List<Tab> _tabs = [
    const Tab(text: 'All News'),
    const Tab(text: 'Food Prices'),
    const Tab(text: 'Weather'),
    const Tab(text: 'Agricultural'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Fetch news as soon as the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the provider to fetch news, but don't listen to changes here.
      // The Consumer widget in the build method will handle UI updates.
      Provider.of<NewsProvider>(context, listen: false).fetchNews();
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedCategory =
                NewsType.agriculturalNews; // All will be filtered in the UI
            break;
          case 1:
            _selectedCategory = NewsType.foodPrice;
            break;
          case 2:
            _selectedCategory = NewsType.weatherWarning;
            break;
          case 3:
            _selectedCategory = NewsType.agriculturalNews;
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: AppConstants.newsFeedTitle),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Consumer<NewsProvider>(
              builder: (context, newsProvider, child) {
                if (newsProvider.status == NewsLoadingStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (newsProvider.status == NewsLoadingStatus.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          newsProvider.errorMessage ?? 'Failed to load news',
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => newsProvider.fetchNews(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // All News
                    _buildNewsList(newsProvider.news),
                    // Food Prices
                    _buildNewsList(
                      newsProvider.getNewsByType(NewsType.foodPrice),
                    ),
                    // Weather
                    _buildNewsList(
                      newsProvider.getNewsByType(NewsType.weatherWarning),
                    ),
                    // Agricultural
                    _buildNewsList(
                      newsProvider.getNewsByType(NewsType.agriculturalNews),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 48,
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 3),
          insets: EdgeInsets.symmetric(horizontal: 16),
        ),
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: _tabs,
      ),
    );
  }

  Widget _buildNewsList(List<NewsModel> newsList) {
    if (newsList.isEmpty) {
      return const Center(
        child: Text(
          'No news available in this category',
          style: TextStyle(color: AppTheme.textLightColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        return _buildNewsItem(newsList[index]);
      },
    );
  }

  Widget _buildNewsItem(NewsModel news) {
    final iconData = news.getTypeIcon();
    final color = news.getTypeColor();
    final date = DateFormat('MMM d, yyyy').format(news.publishedDate);
    final time = DateFormat('h:mm a').format(news.publishedDate);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isGovernmentUser = authProvider.user?.isGovernment ?? false;

    // Food price additionalData display
    final Map<String, dynamic>? additionalData = news.additionalData;
    final bool hasPriceData =
        news.type == NewsType.foodPrice &&
        additionalData != null &&
        additionalData.containsKey('previousPrice') &&
        additionalData.containsKey('currentPrice') &&
        additionalData.containsKey('change');

    // Weather warning additionalData display
    final bool hasWeatherData =
        news.type == NewsType.weatherWarning &&
        additionalData != null &&
        additionalData.containsKey('severity') &&
        additionalData.containsKey('affectedAreas');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(iconData, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getCategoryName(news.type),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const Spacer(),
                Text(
                  '$date - $time',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Title and content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                    height: 1.5,
                  ),
                ),
                if (hasPriceData) ...[
                  const SizedBox(height: 16),
                  _buildSimplePriceCard(additionalData!),
                ],
                if (hasWeatherData) ...[
                  const SizedBox(height: 16),
                  _buildSimpleWeatherDetails(additionalData!),
                ],
              ],
            ),
          ),
          // Footer with source
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Published by: ${news.publishedBy}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ],
            ),
          ),
          if (isGovernmentUser)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: () => _showDeleteConfirmation(context, news.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String newsId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to delete this news article? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onPressed: () {
                final newsProvider = Provider.of<NewsProvider>(
                  context,
                  listen: false,
                );
                newsProvider.deleteNews(newsId).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('News deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newsProvider.errorMessage ?? 'Failed to delete',
                        ),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimplePriceCard(Map<String, dynamic> data) {
    final previousPrice = data['previousPrice'];
    final currentPrice = data['currentPrice'];
    final change = data['change'];
    final unit = data['unit'] ?? 'kg';
    final isIncrease = change.toString().contains('+');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previous Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  Text(
                    '\$$previousPrice/$unit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncrease ? Colors.red : Colors.green,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Current Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  Text(
                    '\$$currentPrice/$unit ($change)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isIncrease ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleWeatherDetails(Map<String, dynamic> data) {
    final severity = data['severity'] ?? 'Medium';
    final List<dynamic> affectedAreas = data['affectedAreas'] ?? [];
    final duration = data['duration'] ?? 'Unknown';

    Color severityColor;
    switch (severity) {
      case 'High':
        severityColor = Colors.red;
        break;
      case 'Medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: severityColor, size: 16),
              const SizedBox(width: 4),
              Text(
                '$severity Severity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, color: Colors.blue, size: 16),
              const SizedBox(width: 4),
              Text(
                duration,
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ],
          ),
          if (affectedAreas.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Affected Areas:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              affectedAreas.join(', '),
              style: const TextStyle(fontSize: 12, color: AppTheme.textColor),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryName(NewsType type) {
    switch (type) {
      case NewsType.foodPrice:
        return AppConstants.foodPriceTitle;
      case NewsType.weatherWarning:
        return AppConstants.weatherWarningTitle;
      case NewsType.agriculturalNews:
        return AppConstants.agricultureNewsTitle;
    }
  }
}
