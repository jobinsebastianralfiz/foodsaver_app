import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  ready,
  completed,
  cancelled,
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String restaurantId;
  final String restaurantName;
  final String mealId;
  final String mealTitle;
  final String? mealImageUrl;
  final int quantity;
  final double pricePerItem;
  final double totalPrice;
  final DateTime pickupTime;
  final OrderStatus status;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.restaurantId,
    required this.restaurantName,
    required this.mealId,
    required this.mealTitle,
    this.mealImageUrl,
    required this.quantity,
    required this.pricePerItem,
    required this.totalPrice,
    required this.pickupTime,
    this.status = OrderStatus.pending,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  // Check if order can be cancelled
  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  // Check if order is active
  bool get isActive {
    return status != OrderStatus.completed && status != OrderStatus.cancelled;
  }

  // Convert from Firestore
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'],
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      mealId: data['mealId'] ?? '',
      mealTitle: data['mealTitle'] ?? '',
      mealImageUrl: data['mealImageUrl'],
      quantity: data['quantity'] ?? 1,
      pricePerItem: (data['pricePerItem'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      pickupTime: (data['pickupTime'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'mealId': mealId,
      'mealTitle': mealTitle,
      'mealImageUrl': mealImageUrl,
      'quantity': quantity,
      'pricePerItem': pricePerItem,
      'totalPrice': totalPrice,
      'pickupTime': Timestamp.fromDate(pickupTime),
      'status': status.toString().split('.').last,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // Convert from JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhone: json['userPhone'],
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      mealId: json['mealId'] ?? '',
      mealTitle: json['mealTitle'] ?? '',
      mealImageUrl: json['mealImageUrl'],
      quantity: json['quantity'] ?? 1,
      pricePerItem: (json['pricePerItem'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      pickupTime: DateTime.parse(json['pickupTime']),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'mealId': mealId,
      'mealTitle': mealTitle,
      'mealImageUrl': mealImageUrl,
      'quantity': quantity,
      'pricePerItem': pricePerItem,
      'totalPrice': totalPrice,
      'pickupTime': pickupTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? restaurantId,
    String? restaurantName,
    String? mealId,
    String? mealTitle,
    String? mealImageUrl,
    int? quantity,
    double? pricePerItem,
    double? totalPrice,
    DateTime? pickupTime,
    OrderStatus? status,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      mealId: mealId ?? this.mealId,
      mealTitle: mealTitle ?? this.mealTitle,
      mealImageUrl: mealImageUrl ?? this.mealImageUrl,
      quantity: quantity ?? this.quantity,
      pricePerItem: pricePerItem ?? this.pricePerItem,
      totalPrice: totalPrice ?? this.totalPrice,
      pickupTime: pickupTime ?? this.pickupTime,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
