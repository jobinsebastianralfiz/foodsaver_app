import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/meal/meal_model.dart';
import '../../../providers/meal/meal_provider.dart';

class EditMealScreen extends StatefulWidget {
  final MealModel meal;

  const EditMealScreen({super.key, required this.meal});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _discountedPriceController;
  late final TextEditingController _quantityController;

  late MealCategory _selectedCategory;
  late DateTime _pickupStartTime;
  late DateTime _pickupEndTime;
  late bool _isVegetarian;
  late bool _isVegan;
  late bool _isGlutenFree;
  late List<String> _allergens;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing meal data
    _titleController = TextEditingController(text: widget.meal.title);
    _descriptionController = TextEditingController(text: widget.meal.description);
    _originalPriceController = TextEditingController(text: widget.meal.originalPrice.toString());
    _discountedPriceController = TextEditingController(text: widget.meal.discountedPrice.toString());
    _quantityController = TextEditingController(text: widget.meal.availableQuantity.toString());

    _selectedCategory = widget.meal.category;
    _pickupStartTime = widget.meal.pickupStartTime;
    _pickupEndTime = widget.meal.pickupEndTime;
    _isVegetarian = widget.meal.isVegetarian;
    _isVegan = widget.meal.isVegan;
    _isGlutenFree = widget.meal.isGlutenFree;
    _allergens = List.from(widget.meal.allergens);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime initialDate = isStartTime ? _pickupStartTime : _pickupEndTime;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
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

  Future<void> _handleUpdateMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupEndTime.isBefore(_pickupStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final mealProvider = context.read<MealProvider>();

    // Calculate new available quantity (preserve sold items)
    final newQuantity = int.parse(_quantityController.text);
    final soldQuantity = widget.meal.quantity - widget.meal.availableQuantity;
    final newAvailableQuantity = newQuantity - soldQuantity;

    final updates = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory.toString().split('.').last,
      'originalPrice': double.parse(_originalPriceController.text),
      'discountedPrice': double.parse(_discountedPriceController.text),
      'quantity': newQuantity,
      'availableQuantity': newAvailableQuantity.clamp(0, newQuantity),
      'pickupStartTime': _pickupStartTime,
      'pickupEndTime': _pickupEndTime,
      'isVegetarian': _isVegetarian,
      'isVegan': _isVegan,
      'isGlutenFree': _isGlutenFree,
      'allergens': _allergens,
      'updatedAt': DateTime.now(),
    };

    try {
      await mealProvider.updateMeal(widget.meal.id, updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal updated successfully!'),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Meal'),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  decoration: InputDecoration(
                    labelText: 'Total Quantity',
                    hintText: 'How many portions?',
                    prefixIcon: const Icon(Icons.inventory),
                    helperText: '${widget.meal.quantity - widget.meal.availableQuantity} already sold',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Invalid quantity';
                    }
                    final soldQty = widget.meal.quantity - widget.meal.availableQuantity;
                    if (qty < soldQty) {
                      return 'Cannot be less than sold ($soldQty)';
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
                        '${_pickupStartTime.day}/${_pickupStartTime.month} ${_pickupStartTime.hour}:${_pickupStartTime.minute.toString().padLeft(2, '0')}',
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
                        '${_pickupEndTime.day}/${_pickupEndTime.month} ${_pickupEndTime.hour}:${_pickupEndTime.minute.toString().padLeft(2, '0')}',
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

              // Update Button
              FadeInUp(
                delay: const Duration(milliseconds: 900),
                child: ElevatedButton(
                  onPressed: mealProvider.isLoading ? null : _handleUpdateMeal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: AppColors.secondary,
                  ),
                  child: mealProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Meal',
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
