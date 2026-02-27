import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/meal/meal_model.dart';

class MealModerationScreen extends StatefulWidget {
  const MealModerationScreen({super.key});

  @override
  State<MealModerationScreen> createState() => _MealModerationScreenState();
}

class _MealModerationScreenState extends State<MealModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meal Moderation'),
        backgroundColor: AppColors.accent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Meals'),
            Tab(text: 'Flagged'),
            Tab(text: 'Removed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Meals Tab
          _MealsList(
            stream: _firestore
                .collection('meals')
                .where('isRemoved', isEqualTo: false)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            emptyMessage: 'No meals available',
            showActions: true,
          ),

          // Flagged Meals Tab
          _MealsList(
            stream: _firestore
                .collection('meals')
                .where('isFlagged', isEqualTo: true)
                .where('isRemoved', isEqualTo: false)
                .snapshots(),
            emptyMessage: 'No flagged meals',
            showActions: true,
          ),

          // Removed Meals Tab
          _MealsList(
            stream: _firestore
                .collection('meals')
                .where('isRemoved', isEqualTo: true)
                .snapshots(),
            emptyMessage: 'No removed meals',
            showActions: false,
            showRestore: true,
          ),
        ],
      ),
    );
  }
}

class _MealsList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMessage;
  final bool showActions;
  final bool showRestore;

  const _MealsList({
    required this.stream,
    required this.emptyMessage,
    this.showActions = false,
    this.showRestore = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('🔥 Firestore Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final meals = snapshot.data?.docs ?? [];

        if (meals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(emptyMessage, style: AppTextStyles.subtitle1),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final mealDoc = meals[index];
            final meal = MealModel.fromFirestore(mealDoc);
            final mealData = mealDoc.data() as Map<String, dynamic>;

            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              child: _MealCard(
                meal: meal,
                mealData: mealData,
                showActions: showActions,
                showRestore: showRestore,
              ),
            );
          },
        );
      },
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealModel meal;
  final Map<String, dynamic> mealData;
  final bool showActions;
  final bool showRestore;

  const _MealCard({
    required this.meal,
    required this.mealData,
    required this.showActions,
    required this.showRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isFlagged = mealData['isFlagged'] ?? false;
    final flagReason = mealData['flagReason'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isFlagged ? Border.all(color: AppColors.warning, width: 2) : null,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFlagged
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.title, style: AppTextStyles.subtitle1),
                      Text(meal.restaurantName, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (isFlagged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FLAGGED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.description, style: AppTextStyles.body2),
                const SizedBox(height: 12),

                // Price & Category
                Row(
                  children: [
                    Text(
                      '₹${meal.discountedPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(was ₹${meal.originalPrice.toStringAsFixed(2)})',
                      style: AppTextStyles.caption.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meal.category.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.inventory,
                      value: '${meal.availableQuantity}/${meal.quantity}',
                      label: 'Available',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.access_time,
                      value: '${meal.pickupStartTime.hour}:${meal.pickupStartTime.minute.toString().padLeft(2, '0')}',
                      label: 'Pickup',
                    ),
                  ],
                ),

                // Flag Reason
                if (isFlagged && flagReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: $flagReason',
                            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Actions
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!isFlagged)
                        OutlinedButton.icon(
                          onPressed: () => _showFlagDialog(context, meal.id),
                          icon: const Icon(Icons.flag, size: 18),
                          label: const Text('Flag'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _unflagMeal(context, meal.id),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Unflag'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _removeMeal(context, meal.id, meal.title),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],

                // Restore Action
                if (showRestore) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _restoreMeal(context, meal.id),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore Meal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(BuildContext context, String mealId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for flagging this meal:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
                  'isFlagged': true,
                  'flagReason': reasonController.text.trim(),
                  'flaggedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meal flagged successfully'),
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
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }

  void _unflagMeal(BuildContext context, String mealId) async {
    try {
      await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
        'isFlagged': false,
        'flagReason': '',
        'flaggedAt': null,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal unflagged successfully'),
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

  void _removeMeal(BuildContext context, String mealId, String mealTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Meal?'),
        content: Text('Are you sure you want to remove "$mealTitle"? This will hide it from customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
          'isRemoved': true,
          'removedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal removed successfully'),
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
  }

  void _restoreMeal(BuildContext context, String mealId) async {
    try {
      await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
        'isRemoved': false,
        'isFlagged': false,
        'flagReason': '',
        'removedAt': null,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal restored successfully'),
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
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
