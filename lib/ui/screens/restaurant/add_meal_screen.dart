import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/meal/meal_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/meal/meal_provider.dart';
import '../../../data/services/storage/image_service.dart';
import '../../shared/widgets/image_picker_widget.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  MealCategory _selectedCategory = MealCategory.lunch;
  DateTime? _pickupStartTime;
  DateTime? _pickupEndTime;
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isGlutenFree = false;
  final List<String> _allergens = [];

  final ImageService _imageService = ImageService();
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
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
    setState(() => _selectedImage = null);
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          final dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStartTime) {
            _pickupStartTime = dateTime;
          } else {
            _pickupEndTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _handleSaveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupStartTime == null || _pickupEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup start and end times'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_pickupEndTime!.isBefore(_pickupStartTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final mealProvider = context.read<MealProvider>();

    // Fetch restaurant's location from Firestore
    double? restaurantLat;
    double? restaurantLng;
    String? restaurantCity;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authProvider.user!.id)
          .get();
      final data = userDoc.data();
      restaurantLat = (data?['latitude'] as num?)?.toDouble();
      restaurantLng = (data?['longitude'] as num?)?.toDouble();
      restaurantCity = data?['city'];
    } catch (_) {}

    String? imageUrl;

    // Upload image if selected
    if (_selectedImage != null) {
      setState(() => _isUploadingImage = true);
      try {
        // Generate a temporary ID for the meal image
        final tempMealId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _imageService.uploadMealImage(
          file: _selectedImage!,
          restaurantId: authProvider.user!.id,
          mealId: tempMealId,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isUploadingImage = false);
        return;
      }
      setState(() => _isUploadingImage = false);
    }

    final meal = MealModel(
      id: '',
      restaurantId: authProvider.user!.id,
      restaurantName: authProvider.user!.name,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      category: _selectedCategory,
      originalPrice: double.parse(_originalPriceController.text),
      discountedPrice: double.parse(_discountedPriceController.text),
      quantity: int.parse(_quantityController.text),
      availableQuantity: int.parse(_quantityController.text),
      pickupStartTime: _pickupStartTime!,
      pickupEndTime: _pickupEndTime!,
      isVegetarian: _isVegetarian,
      isVegan: _isVegan,
      isGlutenFree: _isGlutenFree,
      allergens: _allergens,
      latitude: restaurantLat,
      longitude: restaurantLng,
      city: restaurantCity,
      createdAt: DateTime.now(),
    );

    try {
      await mealProvider.createMeal(meal);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();
    final isLoading = mealProvider.isLoading || _isUploadingImage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Meal'),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Meal Image Picker
              FadeInUp(
                delay: const Duration(milliseconds: 50),
                child: ImagePickerWidget(
                  type: ImagePickerType.meal,
                  selectedImage: _selectedImage,
                  currentImageUrl: null,
                  isLoading: _isUploadingImage,
                  height: 200,
                  onPickFromGallery: _pickImageFromGallery,
                  onPickFromCamera: _pickImageFromCamera,
                  onRemove: _selectedImage != null ? _removeImage : null,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Title',
                    hintText: 'e.g., Vegetable Curry',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter meal title';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Description
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your meal...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Category
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: DropdownButtonFormField<MealCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: MealCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Prices
              Row(
                children: [
                  Expanded(
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: TextFormField(
                        controller: _originalPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Original Price',
                          hintText: '10.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: TextFormField(
                        controller: _discountedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discounted Price',
                          hintText: '5.00',
                          prefixIcon: Icon(Icons.local_offer),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final price = double.tryParse(value);
                          if (price == null) {
                            return 'Invalid';
                          }
                          final original = double.tryParse(_originalPriceController.text);
                          if (original != null && price >= original) {
                            return 'Must be less';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quantity
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'How many portions?',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Invalid quantity';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Pickup Times
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Pickup Start Time'),
                      subtitle: Text(
                        _pickupStartTime != null
                            ? '${_pickupStartTime!.day}/${_pickupStartTime!.month} ${_pickupStartTime!.hour}:${_pickupStartTime!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to select',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectDateTime(context, true),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Pickup End Time'),
                      subtitle: Text(
                        _pickupEndTime != null
                            ? '${_pickupEndTime!.day}/${_pickupEndTime!.month} ${_pickupEndTime!.hour}:${_pickupEndTime!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to select',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectDateTime(context, false),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dietary Options
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dietary Information',
                        style: AppTextStyles.subtitle1,
                      ),
                      CheckboxListTile(
                        title: const Text('Vegetarian'),
                        value: _isVegetarian,
                        onChanged: (value) {
                          setState(() {
                            _isVegetarian = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Vegan'),
                        value: _isVegan,
                        onChanged: (value) {
                          setState(() {
                            _isVegan = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Gluten Free'),
                        value: _isGlutenFree,
                        onChanged: (value) {
                          setState(() {
                            _isGlutenFree = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              FadeInUp(
                delay: const Duration(milliseconds: 900),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSaveMeal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: AppColors.secondary,
                  ),
                  child: isLoading
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
                              _isUploadingImage ? 'Uploading image...' : 'Creating meal...',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
                          'Create Meal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}