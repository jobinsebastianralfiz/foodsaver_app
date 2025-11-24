import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Create notification
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore.collection('notifications').add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      _logFirestoreError(e, 'createNotification');
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications stream (both targeted and general)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', whereIn: [userId, null])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getUserNotifications');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get all notifications (admin view)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getAllNotifications');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      _logFirestoreError(e, 'markAsRead');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all user notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('targetUserId', whereIn: [userId, null])
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      _logFirestoreError(e, 'markAllAsRead');
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      _logFirestoreError(e, 'deleteNotification');
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Get unread count for user
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('targetUserId', whereIn: [userId, null])
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      _logFirestoreError(e, 'getUnreadCount');
      return 0;
    }
  }
}
