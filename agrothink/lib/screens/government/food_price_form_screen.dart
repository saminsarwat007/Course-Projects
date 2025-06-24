import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/providers/news_provider.dart';
import 'package:flutter/material.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/models/news_model.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:agrothink/widgets/custom_button.dart';
import 'package:agrothink/widgets/custom_input_field.dart';
import 'package:provider/provider.dart';

class FoodPriceFormScreen extends StatefulWidget {
  const FoodPriceFormScreen({Key? key}) : super(key: key);

  @override
  FoodPriceFormScreenState createState() => FoodPriceFormScreenState();
}

class FoodPriceFormScreenState extends State<FoodPriceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _previousPriceController =
      TextEditingController();
  final TextEditingController _currentPriceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _previousPriceController.dispose();
    _currentPriceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Add Food Price Update'),
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
          'Food Price Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Provide details about price changes for agricultural products',
          style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        CustomInputField(
          label: 'Food/Crop Name',
          hint: 'Enter the name of the food or crop',
          controller: _foodNameController,
          prefixIcon: Icons.eco_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the food/crop name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomInputField(
                label: 'Previous Price',
                hint: '0.00',
                controller: _previousPriceController,
                prefixIcon: Icons.price_change_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomInputField(
                label: 'Current Price',
                hint: '0.00',
                controller: _currentPriceController,
                prefixIcon: Icons.price_check_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'Unit (kg, bunch, etc.)',
          hint: 'Enter the unit of measurement',
          controller: _unitController,
          prefixIcon: Icons.balance_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the unit';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomInputField(
          label: 'Description (optional)',
          hint: 'Enter any additional details about this price change',
          controller: _descriptionController,
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: 'Publish Food Price Update',
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

      final prevPrice = double.parse(_previousPriceController.text);
      final currPrice = double.parse(_currentPriceController.text);
      final change = ((currPrice - prevPrice) / prevPrice) * 100;

      final newsItem = NewsModel(
        id: '', // Firestore will generate this
        title: '${_foodNameController.text} Price Update',
        content: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'The price of ${_foodNameController.text} has changed.',
        type: NewsType.foodPrice,
        publishedDate: DateTime.now(),
        publishedBy: currentUser?.name ?? 'Government Official',
        additionalData: {
          'previousPrice': prevPrice.toStringAsFixed(2),
          'currentPrice': currPrice.toStringAsFixed(2),
          'unit': _unitController.text,
          'change': '${change.toStringAsFixed(1)}%',
        },
      );

      final success = await newsProvider.addNews(newsItem);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food price update published successfully!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          _formKey.currentState?.reset();
          _foodNameController.clear();
          _previousPriceController.clear();
          _currentPriceController.clear();
          _unitController.clear();
          _descriptionController.clear();
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
