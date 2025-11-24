import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/order/order_model.dart';
import '../../../data/models/review/review_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/order/order_provider.dart';
import '../../../providers/review/review_provider.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderProvider.getUserOrders(authProvider.user!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.subtitle1),
                  const SizedBox(height: 8),
                  Text('Browse meals to place your first order!', style: AppTextStyles.caption),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: _OrderCard(order: orders[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _getStatusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (order.status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.ready:
        return Icons.restaurant;
      case OrderStatus.completed:
        return Icons.task_alt;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.restaurantName,
                        style: AppTextStyles.caption,
                      ),
                    ],
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
                Text(order.mealTitle, style: AppTextStyles.subtitle1),
                const SizedBox(height: 12),

                // Details
                _InfoRow(
                  icon: Icons.shopping_basket,
                  label: 'Quantity',
                  value: '${order.quantity}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Total',
                  value: '\$${order.totalPrice.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Pickup',
                  value: '${order.pickupTime.hour}:${order.pickupTime.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Ordered',
                  value: '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                ),

                // Status Steps
                if (order.status != OrderStatus.cancelled) ...[
                  const SizedBox(height: 16),
                  _StatusStepper(status: order.status),
                ],

                // Cancel Button
                if (order.canBeCancelled) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Order?'),
                          content: const Text('Are you sure you want to cancel this order?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: AppColors.error),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await orderProvider.cancelOrder(
                          order.id,
                          order.mealId,
                          order.quantity,
                          'Cancelled by customer',
                        );
                      }
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ],

                // Completed Message & Review Button
                if (order.status == OrderStatus.completed) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Order completed! Thanks for saving food.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(context, order),
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Write a Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],

                // Cancelled Message
                if (order.status == OrderStatus.cancelled) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            order.cancellationReason ?? 'Order was cancelled',
                            style: AppTextStyles.caption.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
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

  void _showReviewDialog(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewDialog(order: order),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
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
        Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus status;

  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.ready,
      OrderStatus.completed,
    ];

    final currentIndex = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex <= currentIndex;
          return _StepCircle(
            isCompleted: isCompleted,
            isCurrent: stepIndex == currentIndex,
          );
        } else {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.primary : AppColors.border,
            ),
          );
        }
      }),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;

  const _StepCircle({
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.primary : AppColors.border,
        border: isCurrent
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final OrderModel order;

  const _ReviewDialog({required this.order});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final reviewProvider = context.read<ReviewProvider>();

    // Check if already reviewed
    final hasReviewed = await reviewProvider.hasUserReviewedOrder(widget.order.id);
    if (hasReviewed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already reviewed this order'),
          backgroundColor: AppColors.warning,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final review = ReviewModel(
      id: '',
      orderId: widget.order.id,
      mealId: widget.order.mealId,
      mealTitle: widget.order.mealTitle,
      restaurantId: widget.order.restaurantId,
      restaurantName: widget.order.restaurantName,
      userId: authProvider.user!.id,
      userName: authProvider.user!.name,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await reviewProvider.createReview(review);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
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
    final reviewProvider = context.watch<ReviewProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                  Text('Rate Your Experience', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Share your feedback about ${widget.order.restaurantName}',
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 24),

                  // Meal Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
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
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.mealTitle,
                                style: AppTextStyles.subtitle1,
                              ),
                              Text(
                                widget.order.restaurantName,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Star Rating
                  Text('Rating', style: AppTextStyles.subtitle1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: AppColors.warning,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Comment
                  Text('Your Review', style: AppTextStyles.subtitle1),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: reviewProvider.isLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: reviewProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
