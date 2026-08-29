import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';

class ImageUploadService {
  ImageUploadService._();

  static const int maxProductImages = 6;

  static const int imageQuality = 88;

  static const double maxImageWidth = 1800;

  static const double maxImageHeight = 1800;

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxImageWidth,
      maxHeight: maxImageHeight,
    );
  }

  static Future<XFile?> pickFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
      maxWidth: maxImageWidth,
      maxHeight: maxImageHeight,
    );
  }

  static Future<List<XFile>> pickMultipleFromGallery() async {
    return _picker.pickMultiImage(
      imageQuality: imageQuality,
      maxWidth: maxImageWidth,
      maxHeight: maxImageHeight,
    );
  }

  static Future<String> uploadXFile({
    required XFile file,
    required String folder,
  }) async {
    final Uint8List bytes = await file.readAsBytes();

    return CloudinaryService.uploadImage(
      bytes: bytes,
      fileName:
          '${folder}_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
  }
}
