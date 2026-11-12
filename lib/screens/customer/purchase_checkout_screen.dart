import 'package:flutter/material.dart';

import '../../models/enquiry.dart';
import '../../models/product.dart';
import '../../models/shop.dart';
import '../../models/order.dart';
import '../../services/customer/order_service.dart';
import '../../services/product_service.dart';
import '../../services/shop_service.dart';
import '../../theme/design_tokens.dart';
import 'order_details_screen.dart';

class PurchaseCheckoutScreen extends StatefulWidget {
  final Product product;
  final Shop shop;
  final ProductEnquiry enquiry;

  const PurchaseCheckoutScreen({
    super.key,
    required this.product,
    required this.shop,
    required this.enquiry,
  });

  @override
  State<PurchaseCheckoutScreen> createState() => _PurchaseCheckoutScreenState();
}

class _PurchaseCheckoutScreenState extends State<PurchaseCheckoutScreen> {
  final ProductService _productService = ProductService();
  final ShopService _shopService = ShopService();
  final OrderService _orderService = OrderService();

  bool _loading = true;
  bool _placingOrder = false;
  String? _error;

  late Product _product;
  late Shop _shop;

  double get _subtotal => _product.price * widget.enquiry.quantity;

  double get _deliveryCharge =>
      _shop.deliveryAvailable ? _shop.deliveryCharge : 0;

  double get _installationCharge =>
      _shop.installationAvailable ? _shop.installationCharge : 0;

  double get _total => _subtotal + _deliveryCharge + _installationCharge;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _shop = widget.shop;
    _refreshLatestData();
  }

  Future<void> _refreshLatestData() async {
    try {
      final latestProduct = await _productService.getProduct(
        widget.enquiry.productId,
      );

      final latestShop = await _shopService.getShopById(widget.enquiry.shopId);

      if (!mounted) return;

      if (latestProduct == null) {
        setState(() {
          _loading = false;
          _error = 'This product is no longer available.';
        });
        return;
      }

      if (!latestProduct.isAvailable ||
          latestProduct.stock < widget.enquiry.quantity) {
        setState(() {
          _loading = false;
          _error = latestProduct.stock <= 0
              ? 'This product is currently unavailable.'
              : 'Only ${latestProduct.stock} unit${latestProduct.stock == 1 ? '' : 's'} remain available.';
        });
        return;
      }

      if (latestShop == null) {
        setState(() {
          _loading = false;
          _error = 'This shop is no longer available.';
        });
        return;
      }

      if (latestShop.deliveryAvailable && !latestShop.deliveryChargeIsKnown) {
        setState(() {
          _loading = false;
          _error = 'The shop has not provided a delivery charge yet.';
        });
        return;
      }

      if (latestShop.installationAvailable &&
          !latestShop.installationChargeIsKnown) {
        setState(() {
          _loading = false;
          _error = 'The shop has not provided an installation charge yet.';
        });
        return;
      }

      setState(() {
        _product = latestProduct;
        _shop = latestShop;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_placingOrder) return;

    setState(() => _placingOrder = true);

    try {
      final order = await _orderService.createOrderFromAcceptedEnquiry(
        widget.enquiry.id,
      );

      if (!mounted) return;

      await _showSuccess(order);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      // A transaction may commit remotely even when the client receives a
      // timeout. Resolve the stable enquiry order ID before reporting failure.
      if (_orderService.currentUserId == widget.enquiry.customerId) {
        try {
          final existing = await _orderService.getOrderById(widget.enquiry.id);

          if (!mounted) return;

          if (existing != null &&
              existing.enquiryId == widget.enquiry.id &&
              existing.productId == widget.enquiry.productId &&
              existing.shopId == widget.enquiry.shopId) {
            await _showSuccess(existing);
            return;
          }
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not confirm the order yet. Retry safely; this enquiry uses the same order request.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in with the account that sent this enquiry.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (message.toLowerCase().contains('already been placed')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not confirm the order yet. Please retry safely.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) {
        setState(() => _placingOrder = false);
      }
    }
  }

  Future<void> _showSuccess(ShopWiseOrder order) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: const BoxDecoration(
              color: ShopWiseColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: ShopWiseColors.emeraldSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: ShopWiseColors.emeraldDeep,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Order placed successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${order.id}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: ShopWiseColors.emeraldDeep,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ShopWiseColors.emerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
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
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Back to My Enquiries',
                    style: TextStyle(
                      color: ShopWiseColors.textSecondary,
                      fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        elevation: 0,
        foregroundColor: ShopWiseColors.textPrimary,
        title: const Text(
          'Review Order',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ShopWiseColors.emerald),
            )
          : _error != null
          ? _errorState()
          : _content(),
    );
  }

  Widget _content() {
    final quantity = widget.enquiry.quantity;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        _acceptedBanner(),
        const SizedBox(height: 16),
        _productCard(),
        const SizedBox(height: 16),
        _shopCard(),
        const SizedBox(height: 16),
        _priceCard(quantity),
        const SizedBox(height: 22),
        SizedBox(
          height: 55,
          child: FilledButton(
            onPressed: _placingOrder ? null : _placeOrder,
            style: FilledButton.styleFrom(
              backgroundColor: ShopWiseColors.emerald,
              disabledBackgroundColor: ShopWiseColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: _placingOrder
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ShopWiseColors.surface,
                    ),
                  )
                : const Text(
                    'Place Order',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'No online payment is collected. This confirms your purchase request with the shop.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ShopWiseColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _acceptedBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ShopWiseColors.emeraldSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: ShopWiseColors.emeraldDeep,
            size: 22,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enquiry accepted',
                  style: TextStyle(
                    color: ShopWiseColors.emeraldDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review the latest price and place your order.',
                  style: TextStyle(
                    color: ShopWiseColors.emeraldDeep,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard() {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: ShopWiseColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              image: _product.imageUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_product.imageUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _product.imageUrls.isEmpty
                ? const Icon(
                    Icons.inventory_2_outlined,
                    color: ShopWiseColors.textMuted,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Quantity ×${widget.enquiry.quantity}',
                  style: const TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_product.price.toStringAsFixed(0)} / unit',
                  style: const TextStyle(
                    color: ShopWiseColors.emeraldDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop',
            style: TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _shop.name.isEmpty ? 'Local Shop' : _shop.name,
            style: const TextStyle(
              color: ShopWiseColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (_shop.address.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: ShopWiseColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _shop.address,
                    style: const TextStyle(
                      color: ShopWiseColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceCard(int quantity) {
    return _Card(
      child: Column(
        children: [
          _priceRow('Unit price', '₹${_product.price.toStringAsFixed(0)}'),
          _priceRow('Quantity', '×$quantity'),
          const Divider(height: 24),
          _priceRow('Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
          if (_shop.deliveryAvailable)
            _priceRow('Delivery', '₹${_deliveryCharge.toStringAsFixed(0)}'),
          if (_shop.installationAvailable)
            _priceRow(
              'Installation',
              '₹${_installationCharge.toStringAsFixed(0)}',
            ),
          const Divider(height: 24),
          _priceRow(
            'Final total',
            '₹${_total.toStringAsFixed(0)}',
            strong: true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? ShopWiseColors.textPrimary
                    : ShopWiseColors.textSecondary,
                fontSize: strong ? 14 : 12,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong
                  ? ShopWiseColors.emeraldDeep
                  : ShopWiseColors.textPrimary,
              fontSize: strong ? 17 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: ShopWiseColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to prepare your order',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ShopWiseColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _refreshLatestData,
              style: FilledButton.styleFrom(
                backgroundColor: ShopWiseColors.emerald,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: child,
    );
  }
}
