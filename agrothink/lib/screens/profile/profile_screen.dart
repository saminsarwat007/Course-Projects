import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/widgets/custom_button.dart';
import 'package:agrothink/widgets/custom_input_field.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newEmailController = TextEditingController(); // For changing email

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _nameController.text = authProvider.user!.name;
      _emailController.text = authProvider.user!.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _showPickImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text('Gallery'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: const Text('Camera'),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateName() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateUserDisplayName(
        _nameController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Name updated successfully!'
                : authProvider.errorMessage ?? 'Failed to update name.',
          ),
        ),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateUserProfilePicture(_pickedImage!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile picture updated!'
              : authProvider.errorMessage ??
                  'Failed to update profile picture.',
        ),
      ),
    );
    if (success) {
      setState(() {
        _pickedImage = null; // Clear picked image after successful upload
      });
    }
  }

  void _showChangeEmailDialog() {
    _newEmailController.clear();
    _currentPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInputField(
                controller: _newEmailController,
                label: 'New Email',
                validator: (value) => value!.isEmpty ? 'Enter new email' : null,
              ),
              const SizedBox(height: 10),
              CustomInputField(
                controller: _currentPasswordController,
                label: 'Current Password',
                isPassword: true,
                validator:
                    (value) => value!.isEmpty ? 'Enter current password' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_newEmailController.text.isNotEmpty &&
                    _currentPasswordController.text.isNotEmpty) {
                  Navigator.of(
                    context,
                  ).pop(); // Close dialog before async operation
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final success = await authProvider.updateUserEmail(
                    _newEmailController.text.trim(),
                    _currentPasswordController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Email updated successfully! You might need to re-login.'
                            : authProvider.errorMessage ??
                                'Failed to update email.',
                      ),
                    ),
                  );
                  if (success) {
                    _emailController.text =
                        _newEmailController.text
                            .trim(); // Update UI if successful
                  }
                }
              },
              child: const Text('Update Email'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    _currentPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to delete your account? This action cannot be undone. Please enter your password to confirm.',
              ),
              const SizedBox(height: 10),
              CustomInputField(
                controller: _currentPasswordController,
                label: 'Current Password',
                isPassword: true,
                validator: (value) => value!.isEmpty ? 'Enter password' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (_currentPasswordController.text.isNotEmpty) {
                  Navigator.of(
                    context,
                  ).pop(); // Close dialog before async operation
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final success = await authProvider.deleteUserAccount(
                    _currentPasswordController.text.trim(),
                  );
                  if (success) {
                    // Navigate to login/onboarding after account deletion
                    // Assuming you have a named route for your initial screen or login screen
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage ??
                              'Failed to delete account.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          authProvider.status == AuthStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : authProvider.user == null
              ? const Center(
                child: Text('User not found. Please log in again.'),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  _pickedImage != null
                                      ? FileImage(_pickedImage!)
                                      : authProvider.user?.photoUrl != null &&
                                          authProvider
                                              .user!
                                              .photoUrl!
                                              .isNotEmpty
                                      ? NetworkImage(
                                        authProvider.user!.photoUrl!,
                                      )
                                      : const AssetImage(
                                            'assets/images/default_profile.png',
                                          )
                                          as ImageProvider, // Fallback to default asset
                              backgroundColor: Colors.grey[200],
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _showPickImageDialog,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_pickedImage != null)
                        CustomButton(
                          text: 'Update Profile Picture',
                          onPressed: _updateProfilePicture,
                        ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        controller: _nameController,
                        label: 'Full Name',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomButton(text: 'Save Name', onPressed: _updateName),
                      const SizedBox(height: 20),
                      // Display current email (read-only in this field)
                      CustomInputField(
                        controller: _emailController,
                        label: 'Email Address',
                        prefixIcon: Icons.email,
                        enabled: false,
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Change Email',
                        onPressed: _showChangeEmailDialog,
                        type: ButtonType.warning,
                      ),
                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Delete Account',
                        onPressed: _showDeleteAccountDialog,
                        type: ButtonType.danger,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
