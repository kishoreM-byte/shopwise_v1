import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> shareProduct({
    required String productName,
    required double price,
    required String shopName,
  }) async {
    final String text =
        'Check out $productName on ShopWise.\n'
        'Price: ₹${price.toStringAsFixed(0)}\n'
        'Sold by: $shopName';

    await SharePlus.instance.share(ShareParams(text: text));
  }
}
