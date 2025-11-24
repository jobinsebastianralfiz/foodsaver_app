import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/meal/meal_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/meal/meal_provider.dart';
import 'browse_meals_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _toggleFavorite(BuildContext context, String mealId, bool isFavorite) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user!.id;

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

      if (isFavorite) {
        await userDoc.update({
          'favorites': FieldValue.arrayRemove([mealId])
        });
      } else {
        await userDoc.update({
          'favorites': FieldValue.arrayUnion([mealId])
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user!.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          final favorites = (userSnapshot.data?.data() as Map<String, dynamic>?)?['favorites'] as List<dynamic>? ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: AppTextStyles.subtitle1),
                  const SizedBox(height: 8),
                  Text('Tap the heart icon on meals to save them here', style: AppTextStyles.caption),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BrowseMealsScreen()),
                      );
                    },
                    child: const Text('Browse Meals'),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('meals')
                .where(FieldPath.documentId, whereIn: favorites.take(10).toList())
                .snapshots(),
            builder: (context, mealsSnapshot) {
              if (mealsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (mealsSnapshot.hasError) {
                return Center(child: Text('Error: ${mealsSnapshot.error}'));
              }

              final meals = mealsSnapshot.data?.docs.map((doc) => MealModel.fromFirestore(doc)).toList() ?? [];

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
                    child: _FavoriteMealCard(
                      meal: meals[index],
                      onRemove: () => _toggleFavorite(context, meals[index].id, true),
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

class _FavoriteMealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onRemove;

  const _FavoriteMealCard({required this.meal, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Image Placeholder with favorite button
          Stack(
            children: [
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
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: onRemove,
                  ),
                ),
              ),
            ],
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
                        '\$${meal.originalPrice}',
                        style: AppTextStyles.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${meal.discountedPrice}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
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
    );
  }
}
