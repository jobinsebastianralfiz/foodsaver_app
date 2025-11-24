import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  general,
  order,
  promotion,
  announcement,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? targetUserId; // null means for all users
  final String senderId; // admin or restaurant ID
  final String senderName; // admin or restaurant name
  final String senderRole; // 'admin' or 'restaurant'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetUserId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.isRead = false,
    required this.createdAt,
  });

  // Convert from Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.general,
      ),
      targetUserId: data['targetUserId'],
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'targetUserId': targetUserId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.general,
      ),
      targetUserId: json['targetUserId'],
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'targetUserId': targetUserId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Copy with
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? targetUserId,
    String? senderId,
    String? senderName,
    String? senderRole,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUserId: targetUserId ?? this.targetUserId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
