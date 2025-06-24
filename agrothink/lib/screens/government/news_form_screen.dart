import 'package:flutter/material.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/models/news_model.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/providers/news_provider.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:agrothink/widgets/custom_button.dart';
import 'package:agrothink/widgets/custom_input_field.dart';
import 'package:provider/provider.dart';

class NewsFormScreen extends StatefulWidget {
  const NewsFormScreen({Key? key}) : super(key: key);

  @override
  NewsFormScreenState createState() => NewsFormScreenState();
}

class NewsFormScreenState extends State<NewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  NewsType _selectedType = NewsType.agriculturalNews;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Add Agricultural News'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agricultural News',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share important agricultural news and updates with farmers',
          style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'News Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildNewsTypeSelector(),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'News Title',
          hint: 'Enter a clear and concise title',
          controller: _titleController,
          prefixIcon: Icons.title,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'News Content',
          hint: 'Enter the full news article or update',
          controller: _contentController,
          prefixIcon: Icons.description_outlined,
          maxLines: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter news content';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNewsTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            _getNewsTypeIcon(_selectedType),
            color: _getNewsTypeColor(_selectedType),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<NewsType>(
                value: _selectedType,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                elevation: 16,
                style: const TextStyle(color: AppTheme.textColor),
                onChanged: (NewsType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                items:
                    NewsType.values.map<DropdownMenuItem<NewsType>>((
                      NewsType type,
                    ) {
                      return DropdownMenuItem<NewsType>(
                        value: type,
                        child: Text(_getNewsTypeName(type)),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: 'Publish News',
      fullWidth: true,
      isLoading: _isLoading,
      icon: Icons.publish_outlined,
      onPressed: _handleSubmit,
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      final newsItem = NewsModel(
        id: '', // Firestore will generate this
        title: _titleController.text,
        content: _contentController.text,
        type: _selectedType,
        publishedDate: DateTime.now(),
        publishedBy: currentUser?.name ?? 'Government Official',
      );

      final success = await newsProvider.addNews(newsItem);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_getNewsTypeName(_selectedType)} published successfully!',
              ),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          _formKey.currentState?.reset();
          _titleController.clear();
          _contentController.clear();
          setState(() {
            _selectedType = NewsType.agriculturalNews;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newsProvider.errorMessage ?? 'Failed to publish.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getNewsTypeIcon(NewsType type) {
    switch (type) {
      case NewsType.foodPrice:
        return Icons.monetization_on_outlined;
      case NewsType.weatherWarning:
        return Icons.cloud_outlined;
      case NewsType.agriculturalNews:
        return Icons.article_outlined;
    }
  }

  Color _getNewsTypeColor(NewsType type) {
    switch (type) {
      case NewsType.foodPrice:
        return Colors.green;
      case NewsType.weatherWarning:
        return Colors.blue;
      case NewsType.agriculturalNews:
        return Colors.orange;
    }
  }

  String _getNewsTypeName(NewsType type) {
    switch (type) {
      case NewsType.foodPrice:
        return 'Food Price Update';
      case NewsType.weatherWarning:
        return 'Weather Warning';
      case NewsType.agriculturalNews:
        return 'Agricultural News';
    }
  }
}
