import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/providers/news_provider.dart';
import 'package:flutter/material.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/models/news_model.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:agrothink/widgets/custom_button.dart';
import 'package:agrothink/widgets/custom_input_field.dart';
import 'package:provider/provider.dart';

class WeatherWarningFormScreen extends StatefulWidget {
  const WeatherWarningFormScreen({Key? key}) : super(key: key);

  @override
  WeatherWarningFormScreenState createState() =>
      WeatherWarningFormScreenState();
}

class WeatherWarningFormScreenState extends State<WeatherWarningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _areasController = TextEditingController();
  String _selectedSeverity = 'Medium';
  bool _isLoading = false;

  final List<String> _severityOptions = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    _areasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Add Weather Warning'),
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
          'Weather Warning Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Alert farmers about upcoming weather conditions that may affect crops',
          style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomInputField(
          label: 'Warning Title',
          hint: 'Enter a clear title for the warning',
          controller: _titleController,
          prefixIcon: Icons.warning_amber_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'Warning Details',
          hint: 'Describe the weather condition and potential impact on crops',
          controller: _contentController,
          prefixIcon: Icons.description_outlined,
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter warning details';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Warning Severity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildSeveritySelector(),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'Duration',
          hint: 'e.g., "3 days" or "June 10-15"',
          controller: _durationController,
          prefixIcon: Icons.timer_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the expected duration';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'Affected Areas',
          hint: 'List areas that will be affected (comma separated)',
          controller: _areasController,
          prefixIcon: Icons.location_on_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the affected areas';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSeveritySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.textLightColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSeverity,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                elevation: 16,
                style: const TextStyle(color: AppTheme.textColor),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedSeverity = value;
                    });
                  }
                },
                items:
                    _severityOptions.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      Color chipColor;
                      switch (value) {
                        case 'High':
                          chipColor = Colors.red;
                          break;
                        case 'Medium':
                          chipColor = Colors.orange;
                          break;
                        default:
                          chipColor = Colors.yellow.shade800;
                      }

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: chipColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
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
      text: 'Publish Weather Warning',
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
        type: NewsType.weatherWarning,
        publishedDate: DateTime.now(),
        publishedBy: currentUser?.name ?? 'Government Official',
        additionalData: {
          'severity': _selectedSeverity,
          'duration': _durationController.text,
          'affectedAreas':
              _areasController.text.split(',').map((e) => e.trim()).toList(),
        },
      );

      final success = await newsProvider.addNews(newsItem);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Weather warning published successfully!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          _formKey.currentState?.reset();
          _titleController.clear();
          _contentController.clear();
          _durationController.clear();
          _areasController.clear();
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
}
