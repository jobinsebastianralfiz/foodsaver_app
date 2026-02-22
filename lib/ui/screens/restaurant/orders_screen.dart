import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/order/order_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/order/order_provider.dart';

class RestaurantOrdersScreen extends StatelessWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: AppColors.secondary,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderProvider.getRestaurantOrders(authProvider.user!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allOrders = snapshot.data ?? [];

          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.subtitle1),
                ],
              ),
            );
          }

          final pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending).toList();
          final confirmedOrders = allOrders.where((o) => o.status == OrderStatus.confirmed).toList();
          final readyOrders = allOrders.where((o) => o.status == OrderStatus.ready).toList();
          final completedOrders = allOrders.where((o) => o.status == OrderStatus.completed).toList();

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.secondary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.secondary,
                  tabs: [
                    Tab(text: 'Pending (${pendingOrders.length})'),
                    Tab(text: 'Confirmed (${confirmedOrders.length})'),
                    Tab(text: 'Ready (${readyOrders.length})'),
                    Tab(text: 'Completed (${completedOrders.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OrdersList(orders: pendingOrders),
                      _OrdersList(orders: confirmedOrders),
                      _OrdersList(orders: readyOrders),
                      _OrdersList(orders: completedOrders),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text('No orders', style: AppTextStyles.body2),
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
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isUpdating = false;

  OrderModel get order => widget.order;

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

  Future<void> _updateStatus(OrderStatus newStatus, String successMessage) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      debugPrint('🔄 Updating order ${order.id} to $newStatus');
      final orderProvider = context.read<OrderProvider>();
      await orderProvider.updateOrderStatus(order.id, newStatus);
      debugPrint('✅ Order updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isUpdating = false);
      }
    }
  }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.userName,
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                Text(order.mealTitle, style: AppTextStyles.subtitle1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shopping_basket, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Quantity: ${order.quantity}', style: AppTextStyles.body2),
                    const Spacer(),
                    Text(
                      '₹${order.totalPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup: ${order.pickupTime.hour}:${order.pickupTime.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                if (order.userPhone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(order.userPhone!, style: AppTextStyles.caption),
                    ],
                  ),
                ],

                // Action Buttons
                if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
                  const SizedBox(height: 16),
                  if (_isUpdating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Row(
                      children: [
                        if (order.status == OrderStatus.pending)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(
                                OrderStatus.confirmed,
                                'Order confirmed! Check the Confirmed tab.',
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Confirm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        if (order.status == OrderStatus.confirmed)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(
                                OrderStatus.ready,
                                'Order marked ready! Check the Ready tab.',
                              ),
                              icon: const Icon(Icons.done_all),
                              label: const Text('Mark Ready'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                              ),
                            ),
                          ),
                        if (order.status == OrderStatus.ready)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(
                                OrderStatus.completed,
                                'Order completed! Check the Completed tab.',
                              ),
                              icon: const Icon(Icons.task_alt),
                              label: const Text('Complete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
