import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/meal/meal_model.dart';

/// Utility script to seed sample meal data for a restaurant
/// Usage: Call seedMealsForRestaurant() from your app or create a separate script
class SeedData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seeds sample meals for a restaurant with given email
  Future<void> seedMealsForRestaurant(String restaurantEmail) async {
    try {
      // Find restaurant by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: restaurantEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('❌ Restaurant not found with email: $restaurantEmail');
        return;
      }

      final restaurantDoc = userQuery.docs.first;
      final restaurantId = restaurantDoc.id;
      final restaurantName = restaurantDoc.get('name') ?? 'Hotel X';

      print('✅ Found restaurant: $restaurantName (ID: $restaurantId)');

      // Create sample meals
      final meals = _createSampleMeals(restaurantId, restaurantName);

      // Add meals to Firestore
      int count = 0;
      for (var meal in meals) {
        await _firestore.collection('meals').add(meal.toFirestore());
        count++;
        print('  ✓ Added: ${meal.title}');
      }

      print('\n🎉 Successfully added $count meals for $restaurantName');
    } catch (e) {
      print('❌ Error seeding meals: $e');
    }
  }

  /// Creates a list of sample meals
  List<MealModel> _createSampleMeals(String restaurantId, String restaurantName) {
    final now = DateTime.now();
    final pickupStart = DateTime(now.year, now.month, now.day, 18, 0); // 6 PM today
    final pickupEnd = DateTime(now.year, now.month, now.day, 21, 0); // 9 PM today

    return [
      // Breakfast items
      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Classic Breakfast Combo',
        description:
            'Scrambled eggs, toast, bacon, and hash browns. A hearty breakfast to start your day!',
        category: MealCategory.breakfast,
        originalPrice: 250,
        discountedPrice: 120,
        quantity: 10,
        availableQuantity: 10,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['eggs', 'gluten', 'dairy'],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Vegan Breakfast Bowl',
        description:
            'Quinoa, roasted vegetables, avocado, and tahini dressing. Nutritious and delicious!',
        category: MealCategory.breakfast,
        originalPrice: 280,
        discountedPrice: 140,
        quantity: 8,
        availableQuantity: 8,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['sesame'],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: true,
        createdAt: now,
      ),

      // Lunch items
      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Grilled Chicken Sandwich',
        description:
            'Tender grilled chicken breast, lettuce, tomato, and special sauce on a toasted bun.',
        category: MealCategory.lunch,
        originalPrice: 320,
        discountedPrice: 160,
        quantity: 15,
        availableQuantity: 15,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['gluten', 'dairy'],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Caesar Salad with Chicken',
        description:
            'Fresh romaine lettuce, parmesan cheese, croutons, and grilled chicken with Caesar dressing.',
        category: MealCategory.lunch,
        originalPrice: 280,
        discountedPrice: 130,
        quantity: 12,
        availableQuantity: 12,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['dairy', 'gluten', 'fish'],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      // Dinner items
      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Margherita Pizza',
        description:
            'Classic pizza with fresh mozzarella, tomato sauce, and basil. 12-inch personal size.',
        category: MealCategory.dinner,
        originalPrice: 380,
        discountedPrice: 180,
        quantity: 20,
        availableQuantity: 20,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['gluten', 'dairy'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Paneer Tikka Masala',
        description:
            'Grilled paneer cubes in rich, creamy tomato gravy. Served with naan or rice.',
        category: MealCategory.dinner,
        originalPrice: 340,
        discountedPrice: 160,
        quantity: 18,
        availableQuantity: 18,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['dairy'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: true,
        createdAt: now,
      ),

      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Vegetarian Pasta Primavera',
        description:
            'Penne pasta with seasonal vegetables in a light garlic and olive oil sauce.',
        category: MealCategory.dinner,
        originalPrice: 300,
        discountedPrice: 140,
        quantity: 15,
        availableQuantity: 15,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['gluten'],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: false,
        createdAt: now,
      ),

      // Desserts
      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Chocolate Brownie',
        description:
            'Rich, fudgy chocolate brownie with a crispy top. Perfect for chocolate lovers!',
        category: MealCategory.dessert,
        originalPrice: 140,
        discountedPrice: 60,
        quantity: 25,
        availableQuantity: 25,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['gluten', 'dairy', 'eggs'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Gulab Jamun (4 pcs)',
        description:
            'Traditional Indian dessert - soft milk-solid dumplings in sweet rose-flavored syrup.',
        category: MealCategory.dessert,
        originalPrice: 120,
        discountedPrice: 50,
        quantity: 20,
        availableQuantity: 20,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['dairy', 'gluten'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      // Snacks
      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Crispy Chicken Wings',
        description:
            '6 pieces of crispy chicken wings with your choice of BBQ or Buffalo sauce.',
        category: MealCategory.snack,
        originalPrice: 240,
        discountedPrice: 110,
        quantity: 15,
        availableQuantity: 15,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['gluten'],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        createdAt: now,
      ),

      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Samosa Platter (6 pcs)',
        description:
            'Crispy fried pastry filled with spiced potatoes and peas. Served with mint chutney.',
        category: MealCategory.snack,
        originalPrice: 180,
        discountedPrice: 80,
        quantity: 20,
        availableQuantity: 20,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['gluten'],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: false,
        createdAt: now,
      ),

      // Beverages
      MealModel(
        id: '',
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        title: 'Fresh Mango Lassi',
        description:
            'Traditional Indian yogurt-based drink blended with fresh mangoes. Refreshing and creamy!',
        category: MealCategory.beverage,
        originalPrice: 120,
        discountedPrice: 60,
        quantity: 15,
        availableQuantity: 15,
        pickupStartTime: pickupStart,
        pickupEndTime: pickupEnd,
        allergens: ['dairy'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: true,
        createdAt: now,
      ),
    ];
  }

  /// Clears all meals for a specific restaurant (useful for testing)
  Future<void> clearRestaurantMeals(String restaurantEmail) async {
    try {
      // Find restaurant by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: restaurantEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('❌ Restaurant not found with email: $restaurantEmail');
        return;
      }

      final restaurantId = userQuery.docs.first.id;

      // Get all meals for this restaurant
      final mealsQuery = await _firestore
          .collection('meals')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      // Delete each meal
      for (var doc in mealsQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ Cleared ${mealsQuery.docs.length} meals for restaurant');
    } catch (e) {
      print('❌ Error clearing meals: $e');
    }
  }
}