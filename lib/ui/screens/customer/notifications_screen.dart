import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notification data
    final notifications = [
      {
        'icon': Icons.check_circle,
        'color': AppColors.success,
        'title': 'Order Completed',
        'message': 'Your order #1234 has been completed. Thank you!',
        'time': '2 hours ago',
      },
      {
        'icon': Icons.restaurant,
        'color': AppColors.primary,
        'title': 'Order Ready',
        'message': 'Your order is ready for pickup at Restaurant Name',
        'time': '5 hours ago',
      },
      {
        'icon': Icons.local_offer,
        'color': AppColors.warning,
        'title': 'New Deals Available',
        'message': '50% off on selected meals near you!',
        'time': '1 day ago',
      },
      {
        'icon': Icons.info,
        'color': AppColors.info,
        'title': 'Welcome to FoodSaver',
        'message': 'Start saving food and money today!',
        'time': '2 days ago',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mark all as read coming soon!')),
              );
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: AppTextStyles.subtitle1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when something new arrives',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: _NotificationCard(
                    icon: notification['icon'] as IconData,
                    color: notification['color'] as Color,
                    title: notification['title'] as String,
                    message: notification['message'] as String,
                    time: notification['time'] as String,
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message, style: AppTextStyles.body2),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
