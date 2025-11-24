import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review/review_model.dart';

class ReviewRepository {
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

  // Create review
  Future<String> createReview(ReviewModel review) async {
    try {
      final docRef = await _firestore.collection('reviews').add(review.toFirestore());
      return docRef.id;
    } catch (e) {
      _logFirestoreError(e, 'createReview');
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a meal
  Stream<List<ReviewModel>> getMealReviews(String mealId) {
    return _firestore
        .collection('reviews')
        .where('mealId', isEqualTo: mealId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getMealReviews');
        })
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  // Get reviews for a restaurant
  Stream<List<ReviewModel>> getRestaurantReviews(String restaurantId) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getRestaurantReviews');
        })
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  // Get user reviews
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getUserReviews');
        })
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  // Get all reviews (recent first, limited)
  Stream<List<ReviewModel>> getAllReviews({int limit = 10}) {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getAllReviews');
        })
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  // Check if user has already reviewed an order
  Future<bool> hasUserReviewedOrder(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logFirestoreError(e, 'hasUserReviewedOrder');
      throw Exception('Failed to check review status: $e');
    }
  }

  // Get restaurant average rating
  Future<double> getRestaurantAverageRating(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['rating'] ?? 0) as int),
      );

      return total / snapshot.docs.length;
    } catch (e) {
      _logFirestoreError(e, 'getRestaurantAverageRating');
      throw Exception('Failed to get average rating: $e');
    }
  }

  // Get meal average rating
  Future<double> getMealAverageRating(String mealId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('mealId', isEqualTo: mealId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['rating'] ?? 0) as int),
      );

      return total / snapshot.docs.length;
    } catch (e) {
      _logFirestoreError(e, 'getMealAverageRating');
      throw Exception('Failed to get average rating: $e');
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      _logFirestoreError(e, 'deleteReview');
      throw Exception('Failed to delete review: $e');
    }
  }
}
