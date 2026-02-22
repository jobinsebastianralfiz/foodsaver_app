import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/user/user_model.dart';

class RestaurantManagementScreen extends StatelessWidget {
  const RestaurantManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        backgroundColor: AppColors.accent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .where('role', isEqualTo: 'restaurant')
            .where('isApproved', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final restaurants = snapshot.data?.docs ?? [];

          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text('No approved restaurants', style: AppTextStyles.subtitle1),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurantData = restaurants[index].data() as Map<String, dynamic>;
              final restaurant = UserModel.fromFirestore(restaurants[index]);

              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: _RestaurantCard(
                  restaurant: restaurant,
                  restaurantData: restaurantData,
                  restaurantId: restaurants[index].id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final UserModel restaurant;
  final Map<String, dynamic> restaurantData;
  final String restaurantId;

  const _RestaurantCard({
    required this.restaurant,
    required this.restaurantData,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withOpacity(0.1),
          child: const Icon(Icons.restaurant, color: AppColors.secondary),
        ),
        title: Text(
          restaurant.name,
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(restaurant.email, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'APPROVED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Details
                _DetailRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: restaurant.email,
                ),
                if (restaurant.phoneNumber != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: restaurant.phoneNumber!,
                  ),
                ],
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Joined',
                  value: '${restaurant.createdAt.day}/${restaurant.createdAt.month}/${restaurant.createdAt.year}',
                ),

                const SizedBox(height: 16),

                // Statistics
                _StatisticsSection(restaurantId: restaurantId),

                const SizedBox(height: 16),

                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        _showRestaurantDetails(context, restaurant, restaurantData);
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showRestaurantMeals(context, restaurantId, restaurant.name);
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 18),
                      label: const Text('View Meals'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Suspend Restaurant?'),
                            content: Text('Suspend ${restaurant.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.warning,
                                ),
                                child: const Text('Suspend'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Suspend restaurant functionality coming soon!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Suspend'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRestaurantDetails(BuildContext context, UserModel restaurant, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.secondary.withOpacity(0.1),
                        child: const Icon(Icons.restaurant, size: 40, color: AppColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        restaurant.name,
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Restaurant Details', style: AppTextStyles.heading3),
                    const Divider(),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.email, label: 'Email', value: restaurant.email),
                    if (restaurant.phoneNumber != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(icon: Icons.phone, label: 'Phone', value: restaurant.phoneNumber!),
                    ],
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Joined',
                      value: '${restaurant.createdAt.day}/${restaurant.createdAt.month}/${restaurant.createdAt.year}',
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.check_circle,
                      label: 'Status',
                      value: 'Approved',
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

  void _showRestaurantMeals(BuildContext context, String restaurantId, String restaurantName) {
    final firestore = FirebaseFirestore.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
              padding: const EdgeInsets.all(20),
              child: Text(
                '$restaurantName - Meals',
                style: AppTextStyles.heading2,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('meals')
                    .where('restaurantId', isEqualTo: restaurantId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final meals = snapshot.data?.docs ?? [];

                  if (meals.isEmpty) {
                    return Center(
                      child: Text('No meals found', style: AppTextStyles.body2),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(meal['title'] ?? 'Untitled'),
                          subtitle: Text('₹${meal['discountedPrice']} • ${meal['availableQuantity']}/${meal['quantity']} left'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (meal['status'] ?? 'available').toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  final String restaurantId;

  const _StatisticsSection({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return FutureBuilder<Map<String, int>>(
      future: _getStatistics(firestore, restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Meals',
                value: stats['meals'].toString(),
                icon: Icons.restaurant_menu,
              ),
              _StatItem(
                label: 'Orders',
                value: stats['orders'].toString(),
                icon: Icons.receipt_long,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getStatistics(FirebaseFirestore firestore, String restaurantId) async {
    final mealsSnapshot = await firestore
        .collection('meals')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final ordersSnapshot = await firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    return {
      'meals': mealsSnapshot.docs.length,
      'orders': ordersSnapshot.docs.length,
    };
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.caption),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
