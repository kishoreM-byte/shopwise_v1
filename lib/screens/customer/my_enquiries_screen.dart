import 'package:flutter/material.dart';

import '../../models/enquiry.dart';
import '../../services/customer/enquiry_service.dart';
import '../../services/customer/order_service.dart';
import '../../services/product_service.dart';
import '../../services/shop_service.dart';
import '../../theme/design_tokens.dart';
import 'order_details_screen.dart';
import 'purchase_checkout_screen.dart';

class MyEnquiriesScreen extends StatelessWidget {
  const MyEnquiriesScreen({super.key});

  static const Color primary = ShopWiseColors.emerald;
  static const Color background = ShopWiseColors.background;
  static const Color textPrimary = ShopWiseColors.textPrimary;
  static const Color textSecondary = ShopWiseColors.textSecondary;
  static const Color border = ShopWiseColors.border;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textPrimary,
        title: const Text(
          'My Enquiries',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<ProductEnquiry>>(
        stream: EnquiryService().watchMyEnquiries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          if (snapshot.hasError) {
            return _errorState();
          }

          final enquiries = snapshot.data ?? const <ProductEnquiry>[];

          if (enquiries.isEmpty) {
            return _emptyState();
          }

          final pending = enquiries.where((e) => e.status == 'pending').length;
          final accepted = enquiries
              .where((e) => e.status == 'accepted')
              .length;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _overview(
                total: enquiries.length,
                pending: pending,
                accepted: accepted,
              ),
              const SizedBox(height: 20),
              ...enquiries.map(
                (enquiry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _enquiryCard(context, enquiry),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _overview({
    required int total,
    required int pending,
    required int accepted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ShopWiseColors.emeraldDeep, ShopWiseColors.olive],
        ),
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat(
              icon: Icons.forum_rounded,
              value: '$total',
              label: 'Total',
            ),
          ),
          _divider(),
          Expanded(
            child: _stat(
              icon: Icons.schedule_rounded,
              value: '$pending',
              label: 'Pending',
            ),
          ),
          _divider(),
          Expanded(
            child: _stat(
              icon: Icons.check_circle_outline_rounded,
              value: '$accepted',
              label: 'Accepted',
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 42,
      color: ShopWiseColors.surface.withValues(alpha: 0.12),
    );
  }

  Widget _stat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: ShopWiseColors.oliveSoft, size: 19),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: ShopWiseColors.surface,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: ShopWiseColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _enquiryCard(BuildContext context, ProductEnquiry enquiry) {
    final status = enquiry.status.toLowerCase();

    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        onTap: () => _showDetails(context, enquiry),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: ShopWiseColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enquiry.productName.isEmpty
                              ? 'Product enquiry'
                              : enquiry.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantity ×${enquiry.quantity}',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: ShopWiseColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '₹${enquiry.productPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(enquiry.createdAt),
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'accepted') ...[
                const SizedBox(height: 12),
                _statusMessage(
                  icon: Icons.check_circle_rounded,
                  text: 'Accepted — Ready to buy',
                  foreground: ShopWiseColors.emeraldDeep,
                  background: ShopWiseColors.emeraldSoft,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: () => _buyNow(context, enquiry),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: ShopWiseColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text(
                      enquiry.orderId?.trim().isNotEmpty == true
                          ? 'Order placed'
                          : 'Buy Now',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'rejected') ...[
                const SizedBox(height: 12),
                _statusMessage(
                  icon: Icons.cancel_rounded,
                  text: 'The shop has declined this enquiry.',
                  foreground: ShopWiseColors.error,
                  background: ShopWiseColors.error.withValues(alpha: 0.08),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buyNow(BuildContext context, ProductEnquiry enquiry) async {
    final orderService = OrderService();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final orderId = enquiry.orderId?.trim();

      if (orderId != null && orderId.isNotEmpty) {
        final existing = await orderService.getOrderById(orderId);

        if (context.mounted) {
          Navigator.pop(context);

          if (existing != null) {
            await _showExistingOrder(context, existing);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Order information could not be loaded. Please try again.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      }

      final alreadyPlaced = await orderService.hasOrderForEnquiry(enquiry.id);

      if (alreadyPlaced) {
        final existing = await orderService.getOrderById(enquiry.id);

        if (context.mounted) {
          Navigator.pop(context);

          if (existing != null) {
            await _showExistingOrder(context, existing);
          }
        }
        return;
      }

      final product = await ProductService().getProduct(enquiry.productId);
      final shop = await ShopService().getShopById(enquiry.shopId);

      if (!context.mounted) return;

      Navigator.pop(context);

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This product is no longer available.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (shop == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This shop is no longer available.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!product.isAvailable || product.stock < enquiry.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product.stock <= 0
                  ? 'This product is currently unavailable.'
                  : 'Only ${product.stock} unit${product.stock == 1 ? '' : 's'} available.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseCheckoutScreen(
            product: product,
            shop: shop,
            enquiry: enquiry,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showExistingOrder(BuildContext context, dynamic order) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            decoration: const BoxDecoration(
              color: ShopWiseColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: ShopWiseColors.emerald,
                  size: 54,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Order placed',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(order: order),
                        ),
                      );
                    },
                    child: const Text(
                      'View Order',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusMessage({
    required IconData icon,
    required String text,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    late final Color foreground;
    late final Color background;
    late final String label;

    switch (status) {
      case 'accepted':
        foreground = ShopWiseColors.emeraldDeep;
        background = ShopWiseColors.emeraldSoft;
        label = 'ACCEPTED';
        break;
      case 'rejected':
        foreground = ShopWiseColors.error;
        background = ShopWiseColors.error.withValues(alpha: 0.08);
        label = 'REJECTED';
        break;
      default:
        foreground = ShopWiseColors.enquiries;
        background = ShopWiseColors.enquiries.withValues(alpha: 0.12);
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, ProductEnquiry enquiry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: const BoxDecoration(
            color: ShopWiseColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ShopWiseColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enquiry details',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _detail(
                  Icons.inventory_2_outlined,
                  'Product',
                  enquiry.productName,
                ),
                _detail(
                  Icons.storefront_outlined,
                  'Shop',
                  enquiry.shopId.isEmpty ? 'Shop' : enquiry.shopId,
                ),
                _detail(
                  Icons.numbers_rounded,
                  'Quantity',
                  '${enquiry.quantity}',
                ),
                _detail(
                  Icons.currency_rupee_rounded,
                  'Price',
                  '₹${enquiry.productPrice.toStringAsFixed(0)}',
                ),
                _detail(
                  Icons.info_outline_rounded,
                  'Status',
                  enquiry.status.toUpperCase(),
                ),
                if (enquiry.message.trim().isNotEmpty)
                  _detail(
                    Icons.chat_bubble_outline_rounded,
                    'Message',
                    enquiry.message,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: textSecondary),
          const SizedBox(width: 11),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, color: primary, size: 34),
            ),
            const SizedBox(height: 18),
            const Text(
              'No enquiries yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'When you enquire about a product, your enquiry and its status will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Unable to load your enquiries.\nPlease try again later.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
