import 'package:flutter/foundation.dart';
import '../../data/models/notification/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;

  NotificationProvider(this._notificationRepository);

  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  // Create notification
  Future<String> createNotification(NotificationModel notification) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notificationId = await _notificationRepository.createNotification(notification);
      _isLoading = false;
      notifyListeners();
      return notificationId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationRepository.getUserNotifications(userId);
  }

  // Get all notifications stream (admin)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _notificationRepository.getAllNotifications();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationRepository.markAllAsRead(userId);
      _unreadCount = 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Update unread count
  Future<void> updateUnreadCount(String userId) async {
    try {
      _unreadCount = await _notificationRepository.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
