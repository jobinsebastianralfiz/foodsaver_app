class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api'; // Change this to your API URL
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Map
  static const double defaultZoom = 14.0;
  static const double defaultLatitude = 0.0;
  static const double defaultLongitude = 0.0;

  // Distance (in meters)
  static const double nearbyRadius = 5000; // 5km
  static const double maxSearchRadius = 50000; // 50km

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // QR Code
  static const int qrCodeSize = 300;

  // Discount
  static const double minDiscountPercentage = 10.0;
  static const double maxDiscountPercentage = 90.0;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration imageCacheExpiration = Duration(days: 7);
}
