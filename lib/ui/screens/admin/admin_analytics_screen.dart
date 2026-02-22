import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/order/order_model.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        backgroundColor: AppColors.accent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, usersSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, ordersSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('meals').snapshots(),
                builder: (context, mealsSnapshot) {
                  if (usersSnapshot.connectionState == ConnectionState.waiting ||
                      ordersSnapshot.connectionState == ConnectionState.waiting ||
                      mealsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = usersSnapshot.data?.docs ?? [];
                  final orders = ordersSnapshot.data?.docs.map((doc) => OrderModel.fromFirestore(doc)).toList() ?? [];
                  final meals = mealsSnapshot.data?.docs ?? [];

                  // Calculate stats
                  final totalUsers = users.length;
                  final totalCustomers = users.where((u) => (u.data() as Map)['role'] == 'customer').length;
                  final totalRestaurants = users.where((u) => (u.data() as Map)['role'] == 'restaurant').length;

                  final totalOrders = orders.length;
                  final completedOrders = orders.where((o) => o.status == OrderStatus.completed).length;
                  final totalRevenue = orders
                      .where((o) => o.status == OrderStatus.completed)
                      .fold<double>(0, (sum, order) => sum + order.totalPrice);

                  final totalMeals = meals.length;
                  final totalMealsSaved = orders
                      .where((o) => o.status == OrderStatus.completed)
                      .fold<int>(0, (sum, order) => sum + order.quantity);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Platform Overview
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            'Platform Overview',
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Users Stats
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Users',
                                  value: totalUsers.toString(),
                                  icon: Icons.people,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Customers',
                                  value: totalCustomers.toString(),
                                  icon: Icons.person,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Restaurants',
                                  value: totalRestaurants.toString(),
                                  icon: Icons.restaurant,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Meals',
                                  value: totalMeals.toString(),
                                  icon: Icons.restaurant_menu,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Orders Stats
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            'Orders & Revenue',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Orders',
                                  value: totalOrders.toString(),
                                  icon: Icons.receipt_long,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Completed',
                                  value: completedOrders.toString(),
                                  icon: Icons.check_circle,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Revenue Card
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_money, color: Colors.white, size: 48),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Platform Revenue',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₹${totalRevenue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Impact Stats
                        FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.eco, color: AppColors.success, size: 48),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Environmental Impact',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$totalMealsSaved meals saved from waste',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Approx. ${(totalMealsSaved * 0.5).toStringAsFixed(1)} kg CO₂ prevented',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
