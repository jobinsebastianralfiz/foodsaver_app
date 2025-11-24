import 'package:flutter/foundation.dart';
import '../../data/models/review/review_model.dart';
import '../../data/repositories/review_repository.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewRepository _reviewRepository;

  ReviewProvider(this._reviewRepository);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create review
  Future<String> createReview(ReviewModel review) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reviewId = await _reviewRepository.createReview(review);
      _isLoading = false;
      notifyListeners();
      return reviewId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get meal reviews stream
  Stream<List<ReviewModel>> getMealReviews(String mealId) {
    return _reviewRepository.getMealReviews(mealId);
  }

  // Get restaurant reviews stream
  Stream<List<ReviewModel>> getRestaurantReviews(String restaurantId) {
    return _reviewRepository.getRestaurantReviews(restaurantId);
  }

  // Get user reviews stream
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _reviewRepository.getUserReviews(userId);
  }

  // Get all reviews stream
  Stream<List<ReviewModel>> getAllReviews({int limit = 10}) {
    return _reviewRepository.getAllReviews(limit: limit);
  }

  // Check if user has reviewed an order
  Future<bool> hasUserReviewedOrder(String orderId) async {
    try {
      return await _reviewRepository.hasUserReviewedOrder(orderId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Get restaurant average rating
  Future<double> getRestaurantAverageRating(String restaurantId) async {
    try {
      return await _reviewRepository.getRestaurantAverageRating(restaurantId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return 0.0;
    }
  }

  // Get meal average rating
  Future<double> getMealAverageRating(String mealId) async {
    try {
      return await _reviewRepository.getMealAverageRating(mealId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return 0.0;
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reviewRepository.deleteReview(reviewId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
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
