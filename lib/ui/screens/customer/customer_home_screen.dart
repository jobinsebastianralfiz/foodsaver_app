import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/meal/meal_provider.dart';
import '../../../providers/order/order_provider.dart';
import '../../../providers/review/review_provider.dart';
import '../../../data/models/meal/meal_model.dart';
import '../../../data/models/order/order_model.dart';
import '../../../data/models/review/review_model.dart';
import '../../../data/services/location/location_service.dart';
import 'browse_meals_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'favorites_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final LocationService _locationService = LocationService();
  String _selectedCity = '';
  double? _userLat;
  double? _userLng;
  bool _isLoadingLocation = true;

  static const List<String> _majorCities = [
    'Thiruvananthapuram',
    'Kochi',
    'Kozhikode',
    'Thrissur',
    'Kollam',
    'Palakkad',
    'Alappuzha',
    'Kannur',
    'Kottayam',
    'Malappuram',
    'Kasaragod',
    'Pathanamthitta',
    'Idukki',
    'Wayanad',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _userLat = result.latitude;
        _userLng = result.longitude;
        _selectedCity = result.city;
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select City',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text('Current Location'),
                subtitle: _userLat != null
                    ? Text(_selectedCity.isNotEmpty ? _selectedCity : 'Detected location')
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _fetchCurrentLocation();
                },
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _majorCities.length,
                  itemBuilder: (context, index) {
                    final city = _majorCities[index];
                    final isSelected = _selectedCity == city;
                    return ListTile(
                      leading: Icon(
                        Icons.location_city,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedCity = city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Sort meals by distance from user location (nearest first).
  List<MealModel> _sortByDistance(List<MealModel> meals) {
    if (_userLat == null || _userLng == null) return meals;
    final sorted = List<MealModel>.from(meals);
    sorted.sort((a, b) {
      final distA = (a.latitude != null && a.longitude != null)
          ? LocationService.calculateDistance(_userLat!, _userLng!, a.latitude!, a.longitude!)
          : double.infinity;
      final distB = (b.latitude != null && b.longitude != null)
          ? LocationService.calculateDistance(_userLat!, _userLng!, b.latitude!, b.longitude!)
          : double.infinity;
      return distA.compareTo(distB);
    });
    return sorted;
  }

  String _getDistanceText(MealModel meal) {
    if (_userLat == null || _userLng == null || meal.latitude == null || meal.longitude == null) {
      return '';
    }
    final dist = LocationService.calculateDistance(
      _userLat!, _userLng!, meal.latitude!, meal.longitude!,
    );
    if (dist < 1) {
      return '${(dist * 1000).toStringAsFixed(0)} m away';
    }
    return '${dist.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: FadeIn(
                child: GestureDetector(
                  onTap: _showCityPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _isLoadingLocation
                            ? 'Detecting...'
                            : _selectedCity.isNotEmpty
                                ? _selectedCity
                                : 'Select City',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Text(
                            'Hello, ${user?.name ?? 'Customer'}!',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: const Text(
                            'Discover surplus meals and help reduce food waste',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrowseMealsScreen(
                              selectedCity: _selectedCity,
                              userLat: _userLat,
                              userLng: _userLng,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              'Search for meals or restaurants...',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Categories
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Browse by Category',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _CategoryCard(
                            icon: Icons.restaurant,
                            title: 'All Meals',
                            color: AppColors.primary,
                            category: null,
                            selectedCity: _selectedCity,
                            userLat: _userLat,
                            userLng: _userLng,
                          ),
                          _CategoryCard(
                            icon: Icons.breakfast_dining,
                            title: 'Breakfast',
                            color: AppColors.secondary,
                            category: MealCategory.breakfast,
                            selectedCity: _selectedCity,
                            userLat: _userLat,
                            userLng: _userLng,
                          ),
                          _CategoryCard(
                            icon: Icons.lunch_dining,
                            title: 'Lunch',
                            color: AppColors.accent,
                            category: MealCategory.lunch,
                            selectedCity: _selectedCity,
                            userLat: _userLat,
                            userLng: _userLng,
                          ),
                          _CategoryCard(
                            icon: Icons.dinner_dining,
                            title: 'Dinner',
                            color: AppColors.success,
                            category: MealCategory.dinner,
                            selectedCity: _selectedCity,
                            userLat: _userLat,
                            userLng: _userLng,
                          ),
                          _CategoryCard(
                            icon: Icons.cake,
                            title: 'Desserts',
                            color: AppColors.warning,
                            category: MealCategory.dessert,
                            selectedCity: _selectedCity,
                            userLat: _userLat,
                            userLng: _userLng,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Available Meals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeInLeft(
                        delay: const Duration(milliseconds: 400),
                        child: Text(
                          'Available Now',
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FadeInRight(
                        delay: const Duration(milliseconds: 400),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BrowseMealsScreen(
                                  selectedCity: _selectedCity,
                                  userLat: _userLat,
                                  userLng: _userLng,
                                ),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Available Meals List (filtered by city)
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: StreamBuilder<List<MealModel>>(
                      stream: _selectedCity.isNotEmpty
                          ? context.read<MealProvider>().getAvailableMealsByCity(_selectedCity)
                          : context.read<MealProvider>().getAvailableMeals(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                                const SizedBox(height: 16),
                                Text('Error loading meals', style: AppTextStyles.subtitle1),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: AppTextStyles.caption,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final meals = _sortByDistance(snapshot.data ?? []);

                        if (meals.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 64,
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedCity.isNotEmpty
                                      ? 'No meals available in $_selectedCity'
                                      : 'No meals available yet',
                                  style: AppTextStyles.subtitle1.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back soon for surplus meals from local restaurants',
                                  style: AppTextStyles.caption,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // Show first 4 meals
                        final displayMeals = meals.take(4).toList();

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayMeals.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final meal = displayMeals[index];
                            return _MealListCard(
                              meal: meal,
                              distanceText: _getDistanceText(meal),
                              selectedCity: _selectedCity,
                              userLat: _userLat,
                              userLng: _userLng,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Impact Stats
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: StreamBuilder<List<OrderModel>>(
                      stream: context.read<OrderProvider>().getUserOrders(user!.id),
                      builder: (context, snapshot) {
                        final orders = snapshot.data ?? [];
                        final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();

                        final mealsSaved = completedOrders.fold<int>(0, (sum, order) => sum + order.quantity);
                        final foodSaved = mealsSaved * 0.5; // Estimate 0.5kg per meal
                        final moneySaved = completedOrders.fold<double>(0, (sum, order) => sum + order.totalPrice);

                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Impact',
                                    style: AppTextStyles.subtitle1.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _ImpactStat(
                                    value: '$mealsSaved',
                                    label: 'Meals Saved',
                                    icon: Icons.restaurant,
                                  ),
                                  _ImpactStat(
                                    value: '${foodSaved.toStringAsFixed(1)} kg',
                                    label: 'Food Saved',
                                    icon: Icons.scale,
                                  ),
                                  _ImpactStat(
                                    value: '₹${moneySaved.toStringAsFixed(0)}',
                                    label: 'Money Saved',
                                    icon: Icons.attach_money,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Community Reviews
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeInLeft(
                        delay: const Duration(milliseconds: 700),
                        child: Text(
                          'Community Reviews',
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FadeInRight(
                        delay: const Duration(milliseconds: 700),
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('View all reviews coming soon!')),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Reviews List
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: SizedBox(
                      height: 180,
                      child: StreamBuilder<List<ReviewModel>>(
                        stream: context.read<ReviewProvider>().getAllReviews(),
                        builder: (context, snapshot) {
                          final reviews = snapshot.data ?? [];

                          if (reviews.isEmpty) {
                            return Center(
                              child: Text(
                                'No reviews yet. Be the first to review!',
                                style: AppTextStyles.body2,
                              ),
                            );
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: reviews.length > 10 ? 10 : reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return _ReviewCard(
                                name: review.userName,
                                rating: review.rating,
                                comment: review.comment,
                                restaurantName: review.restaurantName,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          switch (index) {
            case 0:
              // Home - already here
              break;
            case 1:
              // Browse
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BrowseMealsScreen(
                    selectedCity: _selectedCity,
                    userLat: _userLat,
                    userLng: _userLng,
                  ),
                ),
              );
              break;
            case 2:
              // Favorites
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
              break;
            case 3:
              // Orders
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),

      // Logout FAB (temporary for testing)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await authProvider.logout();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final MealCategory? category;
  final String selectedCity;
  final double? userLat;
  final double? userLng;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.color,
    this.category,
    required this.selectedCity,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowseMealsScreen(
              selectedCity: selectedCity,
              userLat: userLat,
              userLng: userLng,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _ImpactStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;
  final String? restaurantName;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.comment,
    this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              comment,
              style: AppTextStyles.body2,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (restaurantName != null) ...[
            const SizedBox(height: 8),
            Text(
              restaurantName!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealListCard extends StatelessWidget {
  final MealModel meal;
  final String distanceText;
  final String selectedCity;
  final double? userLat;
  final double? userLng;

  const _MealListCard({
    required this.meal,
    required this.distanceText,
    required this.selectedCity,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowseMealsScreen(
              selectedCity: selectedCity,
              userLat: userLat,
              userLng: userLng,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Meal Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: meal.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.restaurant_menu, size: 40, color: Colors.white),
                      )
                    : const Icon(Icons.restaurant_menu, size: 40, color: Colors.white),
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
                      style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.restaurantName,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (distanceText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            distanceText,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${meal.originalPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
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
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${meal.savingsPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
