import 'package:cloud_firestore/cloud_firestore.dart';

enum MealCategory {
  breakfast,
  lunch,
  dinner,
  dessert,
  snack,
  beverage,
  other,
}

enum MealStatus {
  available,
  soldOut,
  expired,
}

class MealModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String title;
  final String description;
  final String? imageUrl;
  final MealCategory category;
  final double originalPrice;
  final double discountedPrice;
  final int quantity;
  final int availableQuantity;
  final DateTime pickupStartTime;
  final DateTime pickupEndTime;
  final MealStatus status;
  final List<String> allergens;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MealModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.availableQuantity,
    required this.pickupStartTime,
    required this.pickupEndTime,
    this.status = MealStatus.available,
    this.allergens = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate savings percentage
  double get savingsPercentage {
    if (originalPrice == 0) return 0;
    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  // Check if meal is still available
  bool get isAvailable {
    return status == MealStatus.available &&
        availableQuantity > 0 &&
        DateTime.now().isBefore(pickupEndTime);
  }

  // Convert from Firestore
  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      category: MealCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => MealCategory.other,
      ),
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      availableQuantity: data['availableQuantity'] ?? 0,
      pickupStartTime: (data['pickupStartTime'] as Timestamp).toDate(),
      pickupEndTime: (data['pickupEndTime'] as Timestamp).toDate(),
      status: MealStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => MealStatus.available,
      ),
      allergens: List<String>.from(data['allergens'] ?? []),
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.toString().split('.').last,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'pickupStartTime': Timestamp.fromDate(pickupStartTime),
      'pickupEndTime': Timestamp.fromDate(pickupEndTime),
      'status': status.toString().split('.').last,
      'allergens': allergens,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Convert from JSON
  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      category: MealCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => MealCategory.other,
      ),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      availableQuantity: json['availableQuantity'] ?? 0,
      pickupStartTime: DateTime.parse(json['pickupStartTime']),
      pickupEndTime: DateTime.parse(json['pickupEndTime']),
      status: MealStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MealStatus.available,
      ),
      allergens: List<String>.from(json['allergens'] ?? []),
      isVegetarian: json['isVegetarian'] ?? false,
      isVegan: json['isVegan'] ?? false,
      isGlutenFree: json['isGlutenFree'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.toString().split('.').last,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'pickupStartTime': pickupStartTime.toIso8601String(),
      'pickupEndTime': pickupEndTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'allergens': allergens,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  MealModel copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? title,
    String? description,
    String? imageUrl,
    MealCategory? category,
    double? originalPrice,
    double? discountedPrice,
    int? quantity,
    int? availableQuantity,
    DateTime? pickupStartTime,
    DateTime? pickupEndTime,
    MealStatus? status,
    List<String>? allergens,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      pickupStartTime: pickupStartTime ?? this.pickupStartTime,
      pickupEndTime: pickupEndTime ?? this.pickupEndTime,
      status: status ?? this.status,
      allergens: allergens ?? this.allergens,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
