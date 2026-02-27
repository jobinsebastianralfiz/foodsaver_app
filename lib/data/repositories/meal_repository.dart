import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/meal/meal_model.dart';

class MealRepository {
  final FirebaseFirestore _firestore;

  MealRepository({FirebaseFirestore? firestore})
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

  // Create meal
  Future<String> createMeal(MealModel meal) async {
    try {
      final docRef = await _firestore.collection('meals').add(meal.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create meal: $e');
    }
  }

  // Get meal by ID
  Future<MealModel> getMeal(String mealId) async {
    try {
      final doc = await _firestore.collection('meals').doc(mealId).get();
      if (!doc.exists) {
        throw Exception('Meal not found');
      }
      return MealModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get meal: $e');
    }
  }

  // Get restaurant meals stream
  Stream<List<MealModel>> getRestaurantMeals(String restaurantId) {
    return _firestore
        .collection('meals')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getRestaurantMeals');
        })
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList());
  }

  // Get all available meals stream
  Stream<List<MealModel>> getAvailableMeals() {
    return _firestore
        .collection('meals')
        .where('status', isEqualTo: 'available')
        .where('availableQuantity', isGreaterThan: 0)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getAvailableMeals');
        })
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList());
  }

  // Get meals by category stream
  Stream<List<MealModel>> getMealsByCategory(MealCategory category) {
    return _firestore
        .collection('meals')
        .where('status', isEqualTo: 'available')
        .where('category', isEqualTo: category.toString().split('.').last)
        .where('availableQuantity', isGreaterThan: 0)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getMealsByCategory');
        })
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList());
  }

  // Get available meals filtered by city
  Stream<List<MealModel>> getAvailableMealsByCity(String city) {
    return _firestore
        .collection('meals')
        .where('status', isEqualTo: 'available')
        .where('availableQuantity', isGreaterThan: 0)
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logFirestoreError(error, 'getAvailableMealsByCity');
        })
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList());
  }

  // Update meal
  Future<void> updateMeal(String mealId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('meals').doc(mealId).update(updates);
    } catch (e) {
      throw Exception('Failed to update meal: $e');
    }
  }

  // Delete meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _firestore.collection('meals').doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal: $e');
    }
  }

  // Update meal status
  Future<void> updateMealStatus(String mealId, MealStatus status) async {
    try {
      await _firestore.collection('meals').doc(mealId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update meal status: $e');
    }
  }

  // Decrease meal quantity (when order is placed)
  Future<void> decreaseMealQuantity(String mealId, int quantity) async {
    try {
      await _firestore.collection('meals').doc(mealId).update({
        'availableQuantity': FieldValue.increment(-quantity),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to decrease meal quantity: $e');
    }
  }

  // Increase meal quantity (when order is cancelled)
  Future<void> increaseMealQuantity(String mealId, int quantity) async {
    try {
      await _firestore.collection('meals').doc(mealId).update({
        'availableQuantity': FieldValue.increment(quantity),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increase meal quantity: $e');
    }
  }
}
