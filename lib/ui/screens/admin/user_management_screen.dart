import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/user/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  UserRole? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.accent,
        actions: [
          PopupMenuButton<UserRole?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (role) {
              setState(() {
                _selectedFilter = role;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Users'),
              ),
              const PopupMenuItem(
                value: UserRole.customer,
                child: Text('Customers'),
              ),
              const PopupMenuItem(
                value: UserRole.restaurant,
                child: Text('Restaurants'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _selectedFilter == null
            ? _firestore.collection('users').snapshots()
            : _firestore
                .collection('users')
                .where('role', isEqualTo: _selectedFilter.toString().split('.').last)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text('No users found', style: AppTextStyles.subtitle1),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final user = UserModel.fromFirestore(users[index]);

              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: _UserCard(user: user, userData: userData),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> userData;

  const _UserCard({required this.user, required this.userData});

  Color _getRoleColor() {
    switch (user.role) {
      case UserRole.customer:
        return AppColors.primary;
      case UserRole.restaurant:
        return AppColors.secondary;
      case UserRole.admin:
        return AppColors.accent;
    }
  }

  IconData _getRoleIcon() {
    switch (user.role) {
      case UserRole.customer:
        return Icons.person;
      case UserRole.restaurant:
        return Icons.restaurant;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Widget _buildProfileAvatar(double size) {
    final imageUrl = user.profilePhoto;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: _getRoleColor().withOpacity(0.1),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => Icon(
              _getRoleIcon(),
              size: size * 0.5,
              color: _getRoleColor(),
            ),
            errorWidget: (context, url, error) => Icon(
              _getRoleIcon(),
              size: size * 0.5,
              color: _getRoleColor(),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getRoleColor().withOpacity(0.1),
      child: Icon(
        _getRoleIcon(),
        size: size * 0.5,
        color: _getRoleColor(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = userData['isApproved'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        leading: _buildProfileAvatar(40),
        title: Text(
          user.name,
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(),
                    ),
                  ),
                ),
                if (!isApproved) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details
                _DetailRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: user.email,
                ),
                if (user.phoneNumber != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: user.phoneNumber!,
                  ),
                ],
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Joined',
                  value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),

                const SizedBox(height: 16),

                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        _showUserDetails(context, user, userData);
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    if (user.role == UserRole.customer)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Suspend User?'),
                              content: Text('Suspend ${user.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.warning,
                                  ),
                                  child: const Text('Suspend'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.id)
                                  .update({'isSuspended': true});

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User suspended successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Suspend'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete User?'),
                            content: Text(
                              'Are you sure you want to delete ${user.name}? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.id)
                                .delete();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User deleted successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: _getRoleColor().withOpacity(0.1),
                        child: Icon(_getRoleIcon(), size: 40, color: _getRoleColor()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        user.name,
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('User Details', style: AppTextStyles.heading3),
                    const Divider(),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.email, label: 'Email', value: user.email),
                    if (user.phoneNumber != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(icon: Icons.phone, label: 'Phone', value: user.phoneNumber!),
                    ],
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.badge,
                      label: 'Role',
                      value: user.role.toString().split('.').last.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Joined',
                      value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                    ),
                    if (userData['isApproved'] != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.check_circle,
                        label: 'Approved',
                        value: userData['isApproved'] ? 'Yes' : 'No',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.caption),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
