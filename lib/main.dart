import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'data/models/user/user_model.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/meal_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/services/local/shared_prefs_service.dart';
import 'providers/auth/auth_provider.dart';
import 'providers/meal/meal_provider.dart';
import 'providers/order/order_provider.dart';
import 'providers/review/review_provider.dart';
import 'providers/notification/notification_provider.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/customer/customer_home_screen.dart';
import 'ui/screens/restaurant/restaurant_dashboard_screen.dart';
import 'ui/screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore logging to show index creation URLs
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Add global error handler for Firestore index errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final exception = details.exception.toString();
    if (exception.contains('index') || exception.contains('FAILED_PRECONDITION')) {
      debugPrint('\n${'='*80}');
      debugPrint('🔥 FIRESTORE INDEX REQUIRED 🔥');
      debugPrint('='*80);
      debugPrint(exception);
      debugPrint('${'='*80}\n');
    }
  };

  // Initialize SharedPreferences
  final prefsService = await SharedPreferencesService.init();

  // TEMPORARY: Uncomment to seed meals for hotelx@gmail.com
   //await SeedData().seedMealsForRestaurant('hotelx@gmail.com');
  // To clear meals: await SeedData().clearRestaurantMeals('hotelx@gmail.com');

  // Print Firestore index information
  debugPrint('\n${'='*80}');
  debugPrint('🔥 FIRESTORE INDEXES CONFIGURATION 🔥');
  debugPrint('='*80);
  debugPrint('If you encounter index errors, create them using the URLs shown in logs.');
  debugPrint('Common indexes needed for this app:');
  debugPrint('');
  debugPrint('1. reviews collection:');
  debugPrint('   - mealId (Ascending) + createdAt (Descending)');
  debugPrint('   - restaurantId (Ascending) + createdAt (Descending)');
  debugPrint('   - userId (Ascending) + createdAt (Descending)');
  debugPrint('');
  debugPrint('2. orders collection:');
  debugPrint('   - restaurantId (Ascending) + status (Ascending)');
  debugPrint('   - userId (Ascending) + createdAt (Descending)');
  debugPrint('');
  debugPrint('3. meals collection:');
  debugPrint('   - restaurantId (Ascending) + createdAt (Descending)');
  debugPrint('');
  debugPrint('If errors occur, Firebase will provide direct URLs to create indexes.');
  debugPrint('${'='*80}\n');

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(FoodSaverApp(prefsService: prefsService));
}

class FoodSaverApp extends StatelessWidget {
  final SharedPreferencesService prefsService;

  const FoodSaverApp({super.key, required this.prefsService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<SharedPreferencesService>.value(value: prefsService),

        // Repositories
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        Provider<MealRepository>(
          create: (_) => MealRepository(),
        ),
        Provider<OrderRepository>(
          create: (_) => OrderRepository(),
        ),
        Provider<ReviewRepository>(
          create: (_) => ReviewRepository(),
        ),
        Provider<NotificationRepository>(
          create: (_) => NotificationRepository(),
        ),

        // Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            context.read<SharedPreferencesService>(),
          ),
        ),
        ChangeNotifierProvider<MealProvider>(
          create: (context) => MealProvider(
            context.read<MealRepository>(),
          ),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (context) => OrderProvider(
            context.read<OrderRepository>(),
          ),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (context) => ReviewProvider(
            context.read<ReviewRepository>(),
          ),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (context) => NotificationProvider(
            context.read<NotificationRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // Role-based navigation
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading while checking auth status
            if (authProvider.status == AuthStatus.initial) {
              return const SplashScreen();
            }

            // If authenticated, navigate based on role
            if (authProvider.isAuthenticated && authProvider.user != null) {
              switch (authProvider.user!.role) {
                case UserRole.customer:
                  return const CustomerHomeScreen();
                case UserRole.restaurant:
                  return const RestaurantDashboardScreen();
                case UserRole.admin:
                  return const AdminDashboardScreen();
              }
            }

            // Not authenticated, show login
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
