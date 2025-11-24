import 'package:flutter/foundation.dart';
import '../../data/models/order/order_model.dart';
import '../../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;

  OrderProvider(this._orderRepository);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create order
  Future<String> createOrder(OrderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderId = await _orderRepository.createOrder(order);
      _isLoading = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get order by ID
  Future<OrderModel> getOrder(String orderId) async {
    try {
      return await _orderRepository.getOrder(orderId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Get user orders stream
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _orderRepository.getUserOrders(userId);
  }

  // Get restaurant orders stream
  Stream<List<OrderModel>> getRestaurantOrders(String restaurantId) {
    return _orderRepository.getRestaurantOrders(restaurantId);
  }

  // Get active restaurant orders stream
  Stream<List<OrderModel>> getActiveRestaurantOrders(String restaurantId) {
    return _orderRepository.getActiveRestaurantOrders(restaurantId);
  }

  // Get all orders stream (admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _orderRepository.getAllOrders();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderRepository.updateOrderStatus(orderId, status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(
    String orderId,
    String mealId,
    int quantity,
    String reason,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderRepository.cancelOrder(orderId, mealId, quantity, reason);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get restaurant statistics
  Future<Map<String, dynamic>> getRestaurantStatistics(
      String restaurantId) async {
    try {
      return await _orderRepository.getRestaurantStatistics(restaurantId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
