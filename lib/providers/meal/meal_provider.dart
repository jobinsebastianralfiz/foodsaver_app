import 'package:flutter/foundation.dart';
import '../../data/models/meal/meal_model.dart';
import '../../data/repositories/meal_repository.dart';

class MealProvider extends ChangeNotifier {
  final MealRepository _mealRepository;

  MealProvider(this._mealRepository);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create meal
  Future<String> createMeal(MealModel meal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mealId = await _mealRepository.createMeal(meal);
      _isLoading = false;
      notifyListeners();
      return mealId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get meal by ID
  Future<MealModel> getMeal(String mealId) async {
    try {
      return await _mealRepository.getMeal(mealId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Get restaurant meals stream
  Stream<List<MealModel>> getRestaurantMeals(String restaurantId) {
    return _mealRepository.getRestaurantMeals(restaurantId);
  }

  // Get available meals stream
  Stream<List<MealModel>> getAvailableMeals() {
    return _mealRepository.getAvailableMeals();
  }

  // Get meals by category stream
  Stream<List<MealModel>> getMealsByCategory(MealCategory category) {
    return _mealRepository.getMealsByCategory(category);
  }

  // Get available meals filtered by city
  Stream<List<MealModel>> getAvailableMealsByCity(String city) {
    return _mealRepository.getAvailableMealsByCity(city);
  }

  // Update meal
  Future<void> updateMeal(String mealId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _mealRepository.updateMeal(mealId, updates);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete meal
  Future<void> deleteMeal(String mealId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _mealRepository.deleteMeal(mealId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update meal status
  Future<void> updateMealStatus(String mealId, MealStatus status) async {
    try {
      await _mealRepository.updateMealStatus(mealId, status);
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
