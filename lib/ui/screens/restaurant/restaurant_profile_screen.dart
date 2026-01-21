import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../data/services/storage/image_service.dart';
import '../../shared/widgets/image_picker_widget.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  final ImageService _imageService = ImageService();
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
    _currentImageUrl = user?.profilePhoto;
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _addressController.text = data?['address'] ?? '';
          _descriptionController.text = data?['description'] ?? '';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final file = await _imageService.pickImageFromGallery();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _pickImageFromCamera() async {
    final file = await _imageService.pickImageFromCamera();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user!.id;
      String? imageUrl = _currentImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          imageUrl = await _imageService.uploadProfileImage(
            file: _selectedImage!,
            userId: userId,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _isLoading = false;
            _isUploadingImage = false;
          });
          return;
        }
        setState(() => _isUploadingImage = false);
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'profilePhoto': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await authProvider.refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Picker
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: ImagePickerWidget(
                  type: ImagePickerType.profile,
                  selectedImage: _selectedImage,
                  currentImageUrl: _currentImageUrl,
                  isLoading: _isUploadingImage,
                  size: 120,
                  onPickFromGallery: _pickImageFromGallery,
                  onPickFromCamera: _pickImageFromCamera,
                  onRemove: (_selectedImage != null || _currentImageUrl != null)
                      ? _removeImage
                      : null,
                ),
              ),

              const SizedBox(height: 8),

              FadeInUp(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  'Tap to change logo',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  user?.email ?? '',
                  style: AppTextStyles.caption,
                ),
              ),

              const SizedBox(height: 32),

              // Restaurant Name Field
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Name',
                    prefixIcon: Icon(Icons.restaurant),
                    helperText: 'The name displayed to customers',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter restaurant name';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Phone Field
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'Contact number for customers',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Address Field
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                    helperText: 'Pickup location for orders',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Description Field
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    helperText: 'Tell customers about your restaurant',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Operating Hours Info
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Operating hours are set per meal listing.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      backgroundColor: AppColors.secondary,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isUploadingImage ? 'Uploading image...' : 'Saving...',
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
