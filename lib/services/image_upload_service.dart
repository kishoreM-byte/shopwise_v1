import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';

class ImageUploadService {
  ImageUploadService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
    );
  }

  static Future<XFile?> pickFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
    );
  }

  static Future<List<XFile>> pickMultipleFromGallery() async {
    return _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
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
