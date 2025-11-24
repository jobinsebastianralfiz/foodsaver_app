import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/meal/meal_model.dart';
import '../../../providers/meal/meal_provider.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/order/order_provider.dart';
import '../../../data/models/order/order_model.dart';
import '../../../data/services/payment/razorpay_service.dart';

class BrowseMealsScreen extends StatefulWidget {
  const BrowseMealsScreen({super.key});

  @override
  State<BrowseMealsScreen> createState() => _BrowseMealsScreenState();
}

class _BrowseMealsScreenState extends State<BrowseMealsScreen> {
  MealCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MealModel> _filterMeals(List<MealModel> meals) {
    if (_searchQuery.isEmpty) return meals;

    return meals.where((meal) {
      final searchLower = _searchQuery.toLowerCase();
      return meal.title.toLowerCase().contains(searchLower) ||
             meal.description.toLowerCase().contains(searchLower) ||
             meal.restaurantName.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Browse Meals'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for meals or restaurants...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Category Filter
          Container(
            height: 60,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...MealCategory.values.map(
                  (category) => _CategoryChip(
                    label: category.toString().split('.').last.toUpperCase(),
                    isSelected: _selectedCategory == category,
                    onTap: () => setState(() => _selectedCategory = category),
                  ),
                ),
              ],
            ),
          ),

          // Meals Grid
          Expanded(
            child: StreamBuilder<List<MealModel>>(
              stream: _selectedCategory == null
                  ? mealProvider.getAvailableMeals()
                  : mealProvider.getMealsByCategory(_selectedCategory!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allMeals = snapshot.data ?? [];
                final meals = _filterMeals(allMeals);

                if (meals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('No meals available', style: AppTextStyles.subtitle1),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: _MealCard(
                        meal: meals[index],
                        onTap: () => _showMealDetails(context, meals[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMealDetails(BuildContext context, MealModel meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MealDetailsSheet(meal: meal),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onTap;

  const _MealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(Icons.restaurant_menu, size: 48, color: Colors.white),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      style: AppTextStyles.subtitle1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.restaurantName,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${meal.originalPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${meal.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.availableQuantity} left',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealDetailsSheet extends StatefulWidget {
  final MealModel meal;

  const _MealDetailsSheet({required this.meal});

  @override
  State<_MealDetailsSheet> createState() => _MealDetailsSheetState();
}

class _MealDetailsSheetState extends State<_MealDetailsSheet> {
  int _quantity = 1;
  late RazorpayService _razorpayService;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessingPayment = true);

    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final order = OrderModel(
      id: '',
      userId: authProvider.user!.id,
      userName: authProvider.user!.name,
      userEmail: authProvider.user!.email,
      userPhone: authProvider.user!.phoneNumber,
      restaurantId: widget.meal.restaurantId,
      restaurantName: widget.meal.restaurantName,
      mealId: widget.meal.id,
      mealTitle: widget.meal.title,
      quantity: _quantity,
      pricePerItem: widget.meal.discountedPrice,
      totalPrice: widget.meal.discountedPrice * _quantity,
      pickupTime: widget.meal.pickupStartTime,
      createdAt: DateTime.now(),
    );

    try {
      await orderProvider.createOrder(order);
      if (!mounted) return;

      setState(() => _isProcessingPayment = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! Order ID: ${response.paymentId?.substring(0, 10)}...'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment received but order failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _initiatePayment() {
    final authProvider = context.read<AuthProvider>();
    final totalAmount = widget.meal.discountedPrice * _quantity;
    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

    _razorpayService.openCheckout(
      amount: totalAmount,
      orderId: orderId,
      name: authProvider.user!.name,
      email: authProvider.user!.email,
      phone: authProvider.user!.phoneNumber ?? '',
      description: '${widget.meal.title} x $_quantity',
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(widget.meal.title, style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Text(widget.meal.restaurantName, style: AppTextStyles.body2),
                  const SizedBox(height: 16),

                  // Description
                  Text(widget.meal.description, style: AppTextStyles.body1),
                  const SizedBox(height: 16),

                  // Price
                  Row(
                    children: [
                      Text(
                        '₹${widget.meal.originalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.body1.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${widget.meal.discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.meal.savingsPercentage.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Dietary Info
                  if (widget.meal.isVegetarian || widget.meal.isVegan || widget.meal.isGlutenFree)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.meal.isVegetarian)
                          Chip(
                            label: const Text('Vegetarian'),
                            backgroundColor: AppColors.success.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppColors.success),
                          ),
                        if (widget.meal.isVegan)
                          Chip(
                            label: const Text('Vegan'),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppColors.primary),
                          ),
                        if (widget.meal.isGlutenFree)
                          Chip(
                            label: const Text('Gluten Free'),
                            backgroundColor: AppColors.warning.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppColors.warning),
                          ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Pickup Time
                  ListTile(
                    leading: const Icon(Icons.access_time, color: AppColors.primary),
                    title: const Text('Pickup Time'),
                    subtitle: Text(
                      '${widget.meal.pickupStartTime.hour}:${widget.meal.pickupStartTime.minute.toString().padLeft(2, '0')} - ${widget.meal.pickupEndTime.hour}:${widget.meal.pickupEndTime.minute.toString().padLeft(2, '0')}',
                    ),
                    tileColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),

                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    children: [
                      Text('Quantity:', style: AppTextStyles.subtitle1),
                      const Spacer(),
                      IconButton(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_quantity', style: AppTextStyles.subtitle1),
                      IconButton(
                        onPressed: _quantity < widget.meal.availableQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    '${widget.meal.availableQuantity} available',
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(height: 24),

                  // Total Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: AppTextStyles.subtitle1),
                        Text(
                          '₹${(widget.meal.discountedPrice * _quantity).toStringAsFixed(0)}',
                          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Order Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: (_isProcessingPayment || orderProvider.isLoading)
                  ? null
                  : _initiatePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: (_isProcessingPayment || orderProvider.isLoading)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Place Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
