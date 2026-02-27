import 'dart:async';
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
    // Firestore doesn't allow null in whereIn, so we merge two streams
    final userStream = _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getUserNotifications (user)');
        });

    final generalStream = _firestore
        .collection('notifications')
        .where('targetUserId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getUserNotifications (general)');
        });

    final controller = StreamController<List<NotificationModel>>();
    QuerySnapshot? lastUserSnap;
    QuerySnapshot? lastGeneralSnap;

    void merge() {
      if (lastUserSnap == null || lastGeneralSnap == null) return;
      final allDocs = [...lastUserSnap!.docs, ...lastGeneralSnap!.docs];
      allDocs.sort((a, b) {
        final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      controller.add(
        allDocs.take(50).map((doc) => NotificationModel.fromFirestore(doc)).toList(),
      );
    }

    final sub1 = userStream.listen((snap) { lastUserSnap = snap; merge(); });
    final sub2 = generalStream.listen((snap) { lastGeneralSnap = snap; merge(); });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      controller.close();
    };

    return controller.stream;
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
      final userSnapshot = await _firestore
          .collection('notifications')
          .where('targetUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final generalSnapshot = await _firestore
          .collection('notifications')
          .where('targetUserId', isNull: true)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in [...userSnapshot.docs, ...generalSnapshot.docs]) {
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
      final userSnapshot = await _firestore
          .collection('notifications')
          .where('targetUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final generalSnapshot = await _firestore
          .collection('notifications')
          .where('targetUserId', isNull: true)
          .where('isRead', isEqualTo: false)
          .get();

      return userSnapshot.docs.length + generalSnapshot.docs.length;
    } catch (e) {
      _logFirestoreError(e, 'getUnreadCount');
      return 0;
    }
  }
}
