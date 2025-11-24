import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String orderId;
  final String mealId;
  final String mealTitle;
  final String restaurantId;
  final String restaurantName;
  final String userId;
  final String userName;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.mealId,
    required this.mealTitle,
    required this.restaurantId,
    required this.restaurantName,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  // Convert from Firestore
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      mealId: data['mealId'] ?? '',
      mealTitle: data['mealTitle'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'mealId': mealId,
      'mealTitle': mealTitle,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert from JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      mealId: json['mealId'] ?? '',
      mealTitle: json['mealTitle'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'mealId': mealId,
      'mealTitle': mealTitle,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
