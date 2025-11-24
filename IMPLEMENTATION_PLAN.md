# FoodSaver App - Implementation Plan
## Single Flutter App with Role-Based Access & Provider State Management

---

## 🎯 App Architecture Overview

### **Single App - Multiple Roles**
This is **ONE Flutter application** that serves three different user types through role-based navigation:
- **Customer** → Browse and order meals
- **Restaurant** → Manage meals and orders
- **Admin** → Platform management and analytics

### **Authentication: Email/Password Only**
- Simple email and password authentication
- Role assigned during registration
- Role-based routing after login

---

## Table of Contents
1. [Role-Based Navigation Flow](#role-based-navigation-flow)
2. [Project Structure](#project-structure)
3. [Dependencies](#dependencies)
4. [State Management Architecture](#state-management-architecture)
5. [Data Models](#data-models)
6. [Implementation Phases](#implementation-phases)
7. [Authentication Implementation](#authentication-implementation)
8. [Role-Based Features](#role-based-features)

---

## 1. Role-Based Navigation Flow

```
App Launch
    ↓
Check Auth Status
    ↓
┌─────────────────────────────┐
│   Authenticated?            │
│   ┌───────┐    ┌──────┐   │
│   │  No   │    │ Yes  │   │
│   └───┬───┘    └───┬──┘   │
└───────┼────────────┼───────┘
        ↓            ↓
   Login Screen   Check User Role
                     ↓
        ┌────────────┼────────────┐
        ↓            ↓            ↓
   CUSTOMER    RESTAURANT      ADMIN
        ↓            ↓            ↓
  Customer Home  Restaurant   Admin
   Dashboard     Dashboard   Dashboard
```

### Login Flow
```dart
User enters email/password
    ↓
Validate credentials
    ↓
Get user profile with role
    ↓
Route based on role:
  - UserRole.customer → /customer/home
  - UserRole.restaurant → /restaurant/dashboard
  - UserRole.admin → /admin/dashboard
```

---

## 2. Project Structure

```
foodsaver_app/
├── lib/
│   ├── main.dart                    # App entry point with MultiProvider
│   ├── app.dart                     # MaterialApp with routing
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart   # App-wide constants
│   │   │   ├── api_endpoints.dart   # API endpoint URLs
│   │   │   ├── app_colors.dart      # Color palette
│   │   │   └── app_strings.dart     # String constants
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # Light/Dark theme
│   │   │   └── text_styles.dart     # Typography
│   │   ├── utils/
│   │   │   ├── validators.dart      # Form validators
│   │   │   ├── formatters.dart      # Data formatters
│   │   │   ├── extensions.dart      # Dart extensions
│   │   │   └── helpers.dart         # Helper functions
│   │   ├── errors/
│   │   │   ├── exceptions.dart      # Custom exceptions
│   │   │   └── failures.dart        # Failure classes
│   │   └── network/
│   │       ├── api_client.dart      # Dio HTTP client
│   │       ├── network_info.dart    # Connectivity check
│   │       └── interceptors.dart    # Auth & error interceptors
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user/
│   │   │   │   ├── user_model.dart           # Base user model
│   │   │   │   ├── customer_profile.dart     # Customer-specific data
│   │   │   │   └── restaurant_profile.dart   # Restaurant-specific data
│   │   │   ├── meal/
│   │   │   │   ├── meal_model.dart
│   │   │   │   ├── meal_category.dart
│   │   │   │   └── time_slot.dart
│   │   │   ├── order/
│   │   │   │   ├── order_model.dart
│   │   │   │   ├── order_item.dart
│   │   │   │   └── cart_item.dart
│   │   │   ├── location/
│   │   │   │   └── location_model.dart
│   │   │   └── review/
│   │   │       └── review_model.dart
│   │   │
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart           # Authentication logic
│   │   │   ├── user_repository.dart           # User CRUD
│   │   │   ├── meal_repository.dart           # Meal operations
│   │   │   ├── order_repository.dart          # Order operations
│   │   │   ├── restaurant_repository.dart     # Restaurant operations
│   │   │   └── admin_repository.dart          # Admin operations
│   │   │
│   │   └── services/
│   │       ├── api/
│   │       │   ├── auth_api_service.dart
│   │       │   ├── meal_api_service.dart
│   │       │   ├── order_api_service.dart
│   │       │   └── admin_api_service.dart
│   │       └── local/
│   │           ├── shared_prefs_service.dart
│   │           └── secure_storage_service.dart
│   │
│   ├── providers/
│   │   ├── auth/
│   │   │   ├── auth_provider.dart              # Auth state management
│   │   │   └── auth_state.dart                 # Auth state classes
│   │   ├── user/
│   │   │   └── user_provider.dart              # User profile state
│   │   │
│   │   ├── customer/                           # Customer-specific providers
│   │   │   ├── meal_list_provider.dart
│   │   │   ├── meal_detail_provider.dart
│   │   │   ├── meal_filter_provider.dart
│   │   │   ├── cart_provider.dart
│   │   │   ├── order_provider.dart
│   │   │   ├── favorites_provider.dart
│   │   │   └── loyalty_provider.dart
│   │   │
│   │   ├── restaurant/                         # Restaurant-specific providers
│   │   │   ├── restaurant_dashboard_provider.dart
│   │   │   ├── restaurant_meal_provider.dart
│   │   │   ├── restaurant_order_provider.dart
│   │   │   └── restaurant_analytics_provider.dart
│   │   │
│   │   ├── admin/                              # Admin-specific providers
│   │   │   ├── admin_dashboard_provider.dart
│   │   │   ├── user_management_provider.dart
│   │   │   └── platform_analytics_provider.dart
│   │   │
│   │   └── common/
│   │       ├── location_provider.dart
│   │       └── notification_provider.dart
│   │
│   ├── ui/
│   │   ├── shared/
│   │   │   ├── widgets/
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   ├── loading_indicator.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   ├── meal_card.dart
│   │   │   │   ├── restaurant_card.dart
│   │   │   │   └── qr_code_widget.dart
│   │   │   └── layouts/
│   │   │       └── base_scaffold.dart
│   │   │
│   │   └── screens/
│   │       │
│   │       ├── auth/                           # COMMON: All roles use these
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   └── forgot_password_screen.dart
│   │       │
│   │       ├── splash/
│   │       │   └── splash_screen.dart
│   │       │
│   │       ├── customer/                       # CUSTOMER ROLE SCREENS
│   │       │   ├── home/
│   │       │   │   ├── customer_home_screen.dart
│   │       │   │   └── widgets/
│   │       │   ├── search/
│   │       │   │   ├── search_screen.dart
│   │       │   │   └── filter_screen.dart
│   │       │   ├── meal/
│   │       │   │   └── meal_detail_screen.dart
│   │       │   ├── cart/
│   │       │   │   ├── cart_screen.dart
│   │       │   │   └── checkout_screen.dart
│   │       │   ├── orders/
│   │       │   │   ├── active_orders_screen.dart
│   │       │   │   ├── order_detail_screen.dart
│   │       │   │   └── order_history_screen.dart
│   │       │   └── profile/
│   │       │       └── customer_profile_screen.dart
│   │       │
│   │       ├── restaurant/                     # RESTAURANT ROLE SCREENS
│   │       │   ├── dashboard/
│   │       │   │   └── restaurant_dashboard_screen.dart
│   │       │   ├── meals/
│   │       │   │   ├── meal_list_screen.dart
│   │       │   │   ├── add_meal_screen.dart
│   │       │   │   └── edit_meal_screen.dart
│   │       │   ├── orders/
│   │       │   │   ├── restaurant_orders_screen.dart
│   │       │   │   └── order_verification_screen.dart
│   │       │   ├── analytics/
│   │       │   │   └── analytics_screen.dart
│   │       │   └── profile/
│   │       │       └── restaurant_profile_screen.dart
│   │       │
│   │       └── admin/                          # ADMIN ROLE SCREENS
│   │           ├── dashboard/
│   │           │   └── admin_dashboard_screen.dart
│   │           ├── users/
│   │           │   ├── user_list_screen.dart
│   │           │   └── user_detail_screen.dart
│   │           ├── restaurants/
│   │           │   ├── restaurant_list_screen.dart
│   │           │   ├── restaurant_approval_screen.dart
│   │           │   └── restaurant_detail_screen.dart
│   │           ├── orders/
│   │           │   └── all_orders_screen.dart
│   │           └── analytics/
│   │               └── platform_analytics_screen.dart
│   │
│   ├── routes/
│   │   ├── app_router.dart              # GoRouter configuration
│   │   └── route_guards.dart            # Role-based route guards
│   │
│   └── config/
│       └── environment.dart             # Environment variables
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
└── assets/
    ├── images/
    ├── icons/
    └── fonts/
```

---

## 3. Dependencies

### pubspec.yaml
```yaml
name: foodsaver_app
description: A food waste reduction marketplace
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1

  # Navigation
  go_router: ^13.0.0

  # Network
  dio: ^5.4.0
  http: ^1.1.0

  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Location & Maps
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1

  # Images
  cached_network_image: ^3.3.0
  image_picker: ^1.0.5

  # QR Code
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1

  # UI Components
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  lottie: ^2.7.0

  # Forms & Validation
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0

  # Utilities
  intl: ^0.18.1
  timeago: ^3.6.0
  url_launcher: ^6.2.2
  connectivity_plus: ^5.0.2
  permission_handler: ^11.1.0

  # Code Generation
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.1

  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1

  # Testing
  mockito: ^5.4.4
```

---

## 4. State Management Architecture

### Provider Setup in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final sharedPrefs = await SharedPreferencesService.init();
  final secureStorage = SecureStorageService();
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        // Core Services
        Provider<SharedPreferencesService>.value(value: sharedPrefs),
        Provider<SecureStorageService>.value(value: secureStorage),
        Provider<ApiClient>.value(value: apiClient),

        // Repositories
        ProxyProvider<ApiClient, AuthRepository>(
          update: (_, api, __) => AuthRepository(api),
        ),
        ProxyProvider<ApiClient, MealRepository>(
          update: (_, api, __) => MealRepository(api),
        ),
        ProxyProvider<ApiClient, OrderRepository>(
          update: (_, api, __) => OrderRepository(api),
        ),
        ProxyProvider<ApiClient, RestaurantRepository>(
          update: (_, api, __) => RestaurantRepository(api),
        ),
        ProxyProvider<ApiClient, AdminRepository>(
          update: (_, api, __) => AdminRepository(api),
        ),

        // Core Providers (Used by all roles)
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            context.read<SharedPreferencesService>(),
          )..checkAuthStatus(),
        ),

        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) => UserProvider(context.read<AuthRepository>()),
          update: (_, auth, previous) => previous!..updateAuth(auth),
        ),

        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),

        // Customer Providers (Only loaded when user is customer)
        ChangeNotifierProxyProvider<AuthProvider, MealListProvider>(
          create: (context) => MealListProvider(context.read<MealRepository>()),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.customer) return previous!;
            return previous!..updateAuth(auth);
          },
        ),

        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),

        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) => OrderProvider(context.read<OrderRepository>()),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.customer) return previous!;
            return previous!..updateAuth(auth);
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(context.read<MealRepository>()),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.customer) return previous!;
            return previous!..updateAuth(auth);
          },
        ),

        // Restaurant Providers
        ChangeNotifierProxyProvider<AuthProvider, RestaurantDashboardProvider>(
          create: (context) => RestaurantDashboardProvider(
            context.read<RestaurantRepository>(),
          ),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.restaurant) return previous!;
            return previous!..updateAuth(auth);
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, RestaurantMealProvider>(
          create: (context) => RestaurantMealProvider(
            context.read<MealRepository>(),
          ),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.restaurant) return previous!;
            return previous!..updateAuth(auth);
          },
        ),

        // Admin Providers
        ChangeNotifierProxyProvider<AuthProvider, AdminDashboardProvider>(
          create: (context) => AdminDashboardProvider(
            context.read<AdminRepository>(),
          ),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.admin) return previous!;
            return previous!..updateAuth(auth);
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, UserManagementProvider>(
          create: (context) => UserManagementProvider(
            context.read<AdminRepository>(),
          ),
          update: (_, auth, previous) {
            if (auth.userRole != UserRole.admin) return previous!;
            return previous!..updateAuth(auth);
          },
        ),
      ],
      child: const FoodSaverApp(),
    ),
  );
}
```

---

## 5. Data Models

### User Model with Role

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? phoneNumber,
    String? profilePhoto,
    required UserRole role,  // THIS IS KEY FOR ROLE-BASED ROUTING
    CustomerProfile? customerProfile,
    RestaurantProfile? restaurantProfile,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// User Roles Enum
enum UserRole {
  @JsonValue('customer')
  customer,

  @JsonValue('restaurant')
  restaurant,

  @JsonValue('admin')
  admin,
}

// Customer-specific profile
@freezed
class CustomerProfile with _$CustomerProfile {
  const factory CustomerProfile({
    List<String>? dietaryPreferences,
    List<String>? allergens,
    Location? defaultLocation,
    int? loyaltyPoints,
  }) = _CustomerProfile;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileFromJson(json);
}

// Restaurant-specific profile
@freezed
class RestaurantProfile with _$RestaurantProfile {
  const factory RestaurantProfile({
    required String businessName,
    required String businessLicense,
    required Location location,
    required List<String> cuisineTypes,
    String? description,
    List<String>? photos,
    bool? isVerified,
    bool? isActive,
  }) = _RestaurantProfile;

  factory RestaurantProfile.fromJson(Map<String, dynamic> json) =>
      _$RestaurantProfileFromJson(json);
}

// Other models...
@freezed
class Meal with _$Meal {
  const factory Meal({
    required String id,
    required String restaurantId,
    required String name,
    required String description,
    required List<String> photos,
    required double originalPrice,
    required double discountedPrice,
    required int availableQuantity,
    required List<TimeSlot> pickupSlots,
    required MealCategory category,
    required List<String> allergens,
    String? ingredients,
    int? calories,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    required String restaurantId,
    required List<OrderItem> items,
    required double totalAmount,
    required OrderStatus status,
    required TimeSlot pickupTime,
    required String qrCode,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

enum OrderStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('confirmed')
  confirmed,

  @JsonValue('ready')
  ready,

  @JsonValue('completed')
  completed,

  @JsonValue('cancelled')
  cancelled,
}

enum MealCategory {
  @JsonValue('breakfast')
  breakfast,

  @JsonValue('lunch')
  lunch,

  @JsonValue('dinner')
  dinner,

  @JsonValue('snacks')
  snacks,

  @JsonValue('bakery')
  bakery,
}
```

---

## 6. Implementation Phases

### Phase 1: Foundation & Authentication (Week 1-2)

#### Week 1: Project Setup
- [x] ~~Flutter project created~~
- [ ] Set up folder structure
- [ ] Add dependencies
- [ ] Create theme and constants
- [ ] Set up API client with Dio
- [ ] Create base models with Freezed
- [ ] Set up local storage services

#### Week 2: Authentication System
- [ ] Create `AuthProvider` with email/password auth
- [ ] Create `AuthRepository` for API calls
- [ ] Build Login screen UI
- [ ] Build Registration screen UI (with role selection)
- [ ] Build Forgot Password screen
- [ ] Implement session management
- [ ] Add auth token storage
- [ ] Create role-based navigation

### Phase 2: Customer Features (Week 3-6)

#### Week 3: Customer Home & Browse
- [ ] Create `MealListProvider`
- [ ] Build Customer Home screen
- [ ] Implement meal cards
- [ ] Add pagination
- [ ] Create search functionality
- [ ] Build filter system

#### Week 4: Meal Details & Cart
- [ ] Create `MealDetailProvider`
- [ ] Build Meal Detail screen
- [ ] Create `CartProvider`
- [ ] Build Cart screen
- [ ] Implement add/remove from cart

#### Week 5: Orders & Checkout
- [ ] Create `OrderProvider`
- [ ] Build Checkout screen
- [ ] Implement order creation
- [ ] Generate QR codes
- [ ] Build Order Confirmation screen

#### Week 6: Customer Profile & History
- [ ] Build Active Orders screen
- [ ] Build Order History screen
- [ ] Create Customer Profile screen
- [ ] Add favorites functionality

### Phase 3: Restaurant Features (Week 7-9)

#### Week 7: Restaurant Dashboard
- [ ] Create `RestaurantDashboardProvider`
- [ ] Build Restaurant Dashboard UI
- [ ] Show metrics (sales, orders, etc.)
- [ ] Add quick actions

#### Week 8: Restaurant Meal Management
- [ ] Create `RestaurantMealProvider`
- [ ] Build Meal List screen
- [ ] Build Add Meal screen
- [ ] Build Edit Meal screen
- [ ] Implement photo upload
- [ ] Add inventory management

#### Week 9: Restaurant Order Management
- [ ] Create `RestaurantOrderProvider`
- [ ] Build Restaurant Orders screen
- [ ] Build Order Verification screen (QR scanner)
- [ ] Implement order status updates
- [ ] Add analytics dashboard

### Phase 4: Admin Features (Week 10-11)

#### Week 10: Admin Dashboard & User Management
- [ ] Create `AdminDashboardProvider`
- [ ] Build Admin Dashboard UI
- [ ] Create `UserManagementProvider`
- [ ] Build User List screen
- [ ] Build User Detail screen
- [ ] Implement user approval/suspension

#### Week 11: Admin Restaurant & Platform Management
- [ ] Build Restaurant List screen
- [ ] Build Restaurant Approval screen
- [ ] Create All Orders screen
- [ ] Build Platform Analytics screen
- [ ] Add reporting features

### Phase 5: Polish & Testing (Week 12)

#### Week 12: Final Polish
- [ ] Add animations
- [ ] Implement error handling
- [ ] Add loading states
- [ ] Write unit tests
- [ ] Write widget tests
- [ ] Fix bugs
- [ ] Optimize performance
- [ ] Prepare for deployment

---

## 7. Authentication Implementation

### AuthProvider - Core Authentication Logic

```dart
import 'package:flutter/foundation.dart';
import '../data/models/user/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/local/shared_prefs_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SharedPreferencesService _prefs;

  AuthState _state = AuthState();
  AuthState get state => _state;

  User? get currentUser => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  UserRole? get userRole => _state.user?.role;

  AuthProvider(this._authRepository, this._prefs);

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    final token = await _prefs.getAuthToken();
    if (token != null) {
      try {
        final user = await _authRepository.getCurrentUser();
        _state = AuthState(isAuthenticated: true, user: user);
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  // Login with Email/Password
  Future<void> login(String email, String password) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);

      // Save token
      await _prefs.setAuthToken(response.token);

      // Save user
      _state = AuthState(
        isAuthenticated: true,
        user: response.user,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  // Register with Email/Password
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
  }) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
      );

      // Save token
      await _prefs.setAuthToken(response.token);

      // Save user
      _state = AuthState(
        isAuthenticated: true,
        user: response.user,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _prefs.clearAuthToken();
    _state = AuthState(isAuthenticated: false);
    notifyListeners();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }
}
```

### Role-Based Router Configuration

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userRole = authProvider.userRole;
        final currentPath = state.matchedLocation;

        // If not authenticated, redirect to login
        if (!isAuthenticated && !currentPath.startsWith('/auth')) {
          return '/auth/login';
        }

        // If authenticated, redirect based on role
        if (isAuthenticated) {
          // Prevent access to auth screens when logged in
          if (currentPath.startsWith('/auth')) {
            return _getHomeRouteForRole(userRole!);
          }

          // Prevent cross-role access
          if (!_canAccessRoute(currentPath, userRole!)) {
            return _getHomeRouteForRole(userRole);
          }
        }

        return null; // No redirect needed
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes (Common for all)
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // CUSTOMER ROUTES
        GoRoute(
          path: '/customer/home',
          builder: (context, state) => const CustomerHomeScreen(),
        ),
        GoRoute(
          path: '/customer/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/customer/meal/:id',
          builder: (context, state) {
            final mealId = state.pathParameters['id']!;
            return MealDetailScreen(mealId: mealId);
          },
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/customer/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/customer/orders',
          builder: (context, state) => const ActiveOrdersScreen(),
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const CustomerProfileScreen(),
        ),

        // RESTAURANT ROUTES
        GoRoute(
          path: '/restaurant/dashboard',
          builder: (context, state) => const RestaurantDashboardScreen(),
        ),
        GoRoute(
          path: '/restaurant/meals',
          builder: (context, state) => const MealListScreen(),
        ),
        GoRoute(
          path: '/restaurant/meals/add',
          builder: (context, state) => const AddMealScreen(),
        ),
        GoRoute(
          path: '/restaurant/orders',
          builder: (context, state) => const RestaurantOrdersScreen(),
        ),
        GoRoute(
          path: '/restaurant/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/restaurant/profile',
          builder: (context, state) => const RestaurantProfileScreen(),
        ),

        // ADMIN ROUTES
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UserListScreen(),
        ),
        GoRoute(
          path: '/admin/restaurants',
          builder: (context, state) => const RestaurantListScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const AllOrdersScreen(),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (context, state) => const PlatformAnalyticsScreen(),
        ),
      ],
    );
  }

  static String _getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '/customer/home';
      case UserRole.restaurant:
        return '/restaurant/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
    }
  }

  static bool _canAccessRoute(String path, UserRole role) {
    if (path.startsWith('/customer')) return role == UserRole.customer;
    if (path.startsWith('/restaurant')) return role == UserRole.restaurant;
    if (path.startsWith('/admin')) return role == UserRole.admin;
    return true; // Common routes accessible by all
  }
}
```

### Login Screen Implementation

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Navigation is handled by GoRouter redirect based on role
      // No need to manually navigate
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        'FoodSaver',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save Food, Save Money',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/auth/forgot-password'),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () => context.go('/auth/register'),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

### Register Screen with Role Selection

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      // Navigation is handled by GoRouter redirect based on role
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Role Selection
                    const Text(
                      'I am a:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(
                          value: UserRole.customer,
                          label: Text('Customer'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: UserRole.restaurant,
                          label: Text('Restaurant'),
                          icon: Icon(Icons.restaurant),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (Set<UserRole> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () => context.go('/auth/login'),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

---

## 8. Role-Based Features

### Customer Features
- Browse available meals
- Search and filter meals
- View meal details
- Add to cart
- Place orders
- Track orders with QR codes
- View order history
- Manage favorites
- Earn loyalty points
- Manage profile

### Restaurant Features
- Dashboard with metrics
- Add/Edit/Delete meals
- Manage inventory
- View incoming orders
- Verify orders (QR scanner)
- Update order status
- View sales analytics
- Manage restaurant profile

### Admin Features
- Platform overview dashboard
- User management (approve/suspend)
- Restaurant management (approve/reject)
- View all orders
- Platform-wide analytics
- Content moderation
- System configuration

---

## Summary

This implementation plan provides:

✅ **Single Flutter App** - Not separate apps
✅ **Email/Password Authentication Only** - No social login
✅ **Role-Based Access** - Customer, Restaurant, Admin
✅ **Automatic Routing** - Based on user role after login
✅ **Provider State Management** - Clean and scalable
✅ **12-Week Timeline** - Realistic and phased

The app automatically routes users to the correct interface based on their role:
- **Customer** → Browse and order meals
- **Restaurant** → Manage meals and orders
- **Admin** → Platform management

Ready to start building!
