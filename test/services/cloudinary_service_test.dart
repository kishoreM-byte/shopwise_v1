import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/services/cloudinary_service.dart';
import 'package:shopwise_v1/services/image_upload_service.dart';

void main() {
  group('CloudinaryService filename normalization', () {
    test('trims surrounding whitespace', () {
      expect(
        CloudinaryService.normalizeFileName('  product image.jpg  '),
        'product_image.jpg',
      );
    });

    test('replaces unsafe filename characters', () {
      expect(
        CloudinaryService.normalizeFileName(r'product:/image*?.jpg'),
        'product__image__.jpg',
      );
    });

    test('replaces repeated whitespace with underscores', () {
      expect(
        CloudinaryService.normalizeFileName('product   front image.jpg'),
        'product_front_image.jpg',
      );
    });

    test('returns empty string for an empty filename', () {
      expect(CloudinaryService.normalizeFileName('   '), isEmpty);
    });
  });

  group('ImageUploadService limits', () {
    test('product image limit is six', () {
      expect(ImageUploadService.maxProductImages, 6);
    });

    test('image quality is constrained to a production value', () {
      expect(ImageUploadService.imageQuality, 88);
    });

    test('maximum image dimensions are constrained', () {
      expect(ImageUploadService.maxImageWidth, 1800);
      expect(ImageUploadService.maxImageHeight, 1800);
    });
  });
}
