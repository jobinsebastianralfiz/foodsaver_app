import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/storage/image_service.dart';

enum ImagePickerType { profile, meal }

class ImagePickerWidget extends StatelessWidget {
  final File? selectedImage;
  final String? currentImageUrl;
  final ImagePickerType type;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final VoidCallback? onRemove;
  final bool isLoading;
  final double? size;
  final double? width;
  final double? height;

  const ImagePickerWidget({
    super.key,
    this.selectedImage,
    this.currentImageUrl,
    required this.type,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    this.onRemove,
    this.isLoading = false,
    this.size,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (type == ImagePickerType.profile) {
      return _buildProfilePicker(context);
    } else {
      return _buildMealPicker(context);
    }
  }

  Widget _buildProfilePicker(BuildContext context) {
    final imageSize = size ?? 120.0;
    final hasImage = selectedImage != null || (currentImageUrl != null && currentImageUrl!.isNotEmpty);

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showPickerOptions(context),
          child: Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _buildImageContent(imageSize),
            ),
          ),
        ),
        // Edit button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showPickerOptions(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Remove button
        if (hasImage && onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMealPicker(BuildContext context) {
    final imageWidth = width ?? double.infinity;
    final imageHeight = height ?? 200.0;
    final hasImage = selectedImage != null || (currentImageUrl != null && currentImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: () => _showPickerOptions(context),
      child: Container(
        width: imageWidth,
        height: imageHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _buildMealImageContent(imageWidth, imageHeight),
                  ),
                  // Edit overlay
                  if (hasImage)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            icon: Icons.edit,
                            color: AppColors.primary,
                            onTap: () => _showPickerOptions(context),
                          ),
                          if (onRemove != null) ...[
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.delete,
                              color: AppColors.error,
                              onTap: onRemove!,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildImageContent(double size) {
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currentImageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.person,
          size: size * 0.5,
          color: AppColors.primary,
        ),
      );
    } else {
      return Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primary,
      );
    }
  }

  Widget _buildMealImageContent(double width, double height) {
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currentImageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(width, height),
      );
    } else {
      return _buildPlaceholder(width, height);
    }
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add image',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      onPickFromGallery();
                    },
                  ),
                  _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      onPickFromCamera();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}