import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Helper to log Firestore index errors
  void _logFirestoreError(dynamic error, String operation) {
    final errorStr = error.toString();
    if (errorStr.contains('index') || errorStr.contains('FAILED_PRECONDITION')) {
      debugPrint('\n${'='*80}');
      debugPrint('🔥 FIRESTORE INDEX REQUIRED 🔥');
      debugPrint('Operation: $operation');
      debugPrint('='*80);
      debugPrint(errorStr);
      debugPrint('='*80);
      // Extract and print the index creation URL if available
      final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(errorStr);
      if (urlMatch != null) {
        debugPrint('\n📋 CREATE INDEX HERE:');
        debugPrint(urlMatch.group(0));
        debugPrint('');
      }
      debugPrint('${'='*80}\n');
    }
  }

  // Create order
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef =
          await _firestore.collection('orders').add(order.toFirestore());

      // Decrease meal available quantity
      await _firestore.collection('meals').doc(order.mealId).update({
        'availableQuantity': FieldValue.increment(-order.quantity),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      _logFirestoreError(e, 'createOrder');
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<OrderModel> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) {
        throw Exception('Order not found');
      }
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get user orders stream
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getUserOrders');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // Get restaurant orders stream
  Stream<List<OrderModel>> getRestaurantOrders(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getRestaurantOrders');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // Get active restaurant orders stream
  Stream<List<OrderModel>> getActiveRestaurantOrders(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereIn: ['pending', 'confirmed', 'ready'])
        .orderBy('createdAt', descending: false) // Oldest first for active orders
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getActiveRestaurantOrders');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // Get all orders stream (admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit for performance
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getAllOrders');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (status == OrderStatus.completed) {
        updates['completedAt'] = Timestamp.now();
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(
    String orderId,
    String mealId,
    int quantity,
    String reason,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // Restore meal quantity
      await _firestore.collection('meals').doc(mealId).update({
        'availableQuantity': FieldValue.increment(quantity),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Get order statistics for restaurant
  Future<Map<String, dynamic>> getRestaurantStatistics(
      String restaurantId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Get all orders
      final allOrdersSnapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      // Get today's orders
      final todayOrdersSnapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      double totalRevenue = 0;
      int totalOrders = allOrdersSnapshot.docs.length;
      int todayOrders = todayOrdersSnapshot.docs.length;
      int completedOrders = 0;

      for (var doc in allOrdersSnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        if (order.status == OrderStatus.completed) {
          totalRevenue += order.totalPrice;
          completedOrders++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'todayOrders': todayOrders,
        'completedOrders': completedOrders,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
