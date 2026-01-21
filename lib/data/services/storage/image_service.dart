import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Maximum file size (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  // Allowed file extensions
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({int imageQuality = 80}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera({int imageQuality = 80}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Validate image file
  Future<bool> validateImage(File file) async {
    // Check file size
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds 5MB limit');
    }

    // Check file extension
    final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid file format. Allowed: jpg, jpeg, png, webp');
    }

    return true;
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    await validateImage(file);

    final extension = path.extension(file.path);
    final ref = _storage.ref().child('profiles/$userId/profile$extension');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/${extension.replaceAll('.', '')}',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      ),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload meal image
  Future<String> uploadMealImage({
    required File file,
    required String restaurantId,
    required String mealId,
  }) async {
    await validateImage(file);

    final extension = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('meals/$restaurantId/${mealId}_$timestamp$extension');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/${extension.replaceAll('.', '')}',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'restaurantId': restaurantId,
          'mealId': mealId,
        },
      ),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Silently fail if image doesn't exist
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profiles/$userId');
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
    }
  }

  /// Get upload progress stream
  Stream<TaskSnapshot> uploadWithProgress({
    required File file,
    required String storagePath,
  }) {
    final ref = _storage.ref().child(storagePath);
    return ref.putFile(file).snapshotEvents;
  }
}