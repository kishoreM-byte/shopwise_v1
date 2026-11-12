import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  static const String _cloudName = 'jyulza0z';
  static const String _uploadPreset = 'shopwise_images';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  static const Duration _uploadTimeout = Duration(seconds: 30);

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Image data cannot be empty.');
    }

    final String safeFileName = normalizeFileName(fileName);

    if (safeFileName.isEmpty) {
      throw ArgumentError('Image file name cannot be empty.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'shopwise';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: safeFileName),
    );

    final http.StreamedResponse response;

    try {
      response = await request.send().timeout(_uploadTimeout);
    } on TimeoutException {
      throw Exception(
        'Image upload timed out. Please check your connection and try again.',
      );
    }

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): $responseBody',
      );
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = data['secure_url'];

    if (secureUrl is! String || !isValidSecureImageUrl(secureUrl)) {
      throw Exception('Cloudinary did not return a secure image URL.');
    }

    return secureUrl.trim();
  }

  /// Cloudinary's `secure_url` must be an absolute HTTPS URL before it can be
  /// persisted as a product image.
  static bool isValidSecureImageUrl(String value) {
    final Uri? uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static String normalizeFileName(String fileName) {
    final String normalized = fileName.trim();

    if (normalized.isEmpty) {
      return '';
    }

    return normalized
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
