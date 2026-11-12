import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../models/product.dart';
import '../../models/shop.dart';
import '../../models/enquiry.dart';
import '../../services/customer/enquiry_service.dart';
import '../../services/customer/order_service.dart';
import '../../models/order.dart';
import 'order_details_screen.dart';

class BuyEnquireScreen extends StatefulWidget {
  final Product product;
  final Shop? shop;

  const BuyEnquireScreen({super.key, required this.product, this.shop});

  @override
  State<BuyEnquireScreen> createState() => _BuyEnquireScreenState();
}

class _BuyEnquireScreenState extends State<BuyEnquireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _messageController = TextEditingController();
  final OrderService _orderService = OrderService();

  bool _isSubmitting = false;
  bool _isBuying = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openDirectBuy(String mode) async {
    final shop = widget.shop;

    if (shop == null || shop.id.isEmpty || shop.ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop information is unavailable. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1 || quantity > widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product.stock > 0
                ? 'Enter a quantity up to ${widget.product.stock}.'
                : 'This product is currently unavailable.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mode == 'online' && !shop.deliveryAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online delivery is not available from this shop.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isBuying) return;

    setState(() => _isBuying = true);
    DirectOrderRequest? request;

    try {
      request = await _orderService.getOrCreateDirectOrderRequest(
        widget.product.id,
      );
      final order = await _orderService.createDirectOrder(
        product: widget.product,
        shop: shop,
        quantity: quantity,
        purchaseMode: mode,
        fulfillmentType: mode == 'online' ? 'delivery' : 'pickup',
        requestId: request.requestId,
        expectedCustomerId: request.customerId,
      );
      await _orderService.completeDirectOrderRequest(
        customerId: request.customerId,
        productId: widget.product.id,
        requestId: request.requestId,
      );

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DirectPurchaseCheckoutScreen(order: order),
        ),
      );
    } catch (e) {
      final attempt = request;
      if (attempt != null &&
          _orderService.currentUserId == attempt.customerId) {
        ShopWiseOrder? existingOrder;
        try {
          existingOrder = await _orderService.getOrderById(attempt.requestId);
        } catch (_) {
          // Preserve the pending key when connectivity prevents confirmation.
        }

        if (existingOrder != null &&
            existingOrder.productId == widget.product.id) {
          try {
            await _orderService.completeDirectOrderRequest(
              customerId: attempt.customerId,
              productId: widget.product.id,
              requestId: attempt.requestId,
            );
          } catch (_) {
            // The same key remains safe to retry if local cleanup fails.
          }
          if (!mounted) return;
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DirectPurchaseCheckoutScreen(order: existingOrder!),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    final shop = widget.shop;

    if (shop == null || shop.id.isEmpty || shop.ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop information is unavailable. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());

    if (quantity == null || quantity < 1) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await EnquiryService().createEnquiry(
        ProductEnquiry(
          id: '',
          productId: widget.product.id,
          shopId: shop.id,
          ownerId: shop.ownerId,
          customerId: '',
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          customerEmail: '',
          productName: widget.product.name,
          productPrice: widget.product.price,
          quantity: quantity,
          message: _messageController.text.trim(),
          status: 'pending',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your enquiry has been sent to the shop.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final shopName = widget.shop?.name.trim().isNotEmpty == true
        ? widget.shop!.name
        : 'Local Shop';

    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: ShopWiseColors.textPrimary),
        title: const Text(
          'Buy / Enquire',
          style: TextStyle(
            color: ShopWiseColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _ProductSummary(product: product, shopName: shopName),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Your details',
              icon: Icons.person_outline_rounded,
              children: [
                _Field(
                  controller: _nameController,
                  label: 'Your name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _phoneController,
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Enter your phone number';
                    if (phone.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Purchase details',
              icon: Icons.shopping_bag_outlined,
              children: [
                _Field(
                  controller: _quantityController,
                  label: 'Quantity',
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final quantity = int.tryParse(value?.trim() ?? '');
                    if (quantity == null || quantity < 1) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _messageController,
                  label: 'Message (optional)',
                  icon: Icons.chat_bubble_outline_rounded,
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _BuyButton(
                    icon: Icons.local_shipping_outlined,
                    label: 'Buy Online',
                    enabled:
                        !_isBuying &&
                        widget.product.isAvailable &&
                        widget.product.stock > 0 &&
                        (widget.shop?.deliveryAvailable ?? false),
                    onTap: () => _openDirectBuy('online'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BuyButton(
                    icon: Icons.storefront_outlined,
                    label: 'Buy Offline',
                    enabled:
                        !_isBuying &&
                        widget.product.isAvailable &&
                        widget.product.stock > 0,
                    onTap: () => _openDirectBuy('offline'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting || _isBuying ? null : _submitEnquiry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ShopWiseColors.textPrimary,
                  side: const BorderSide(color: ShopWiseColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.3),
                      )
                    : const Text(
                        'Enquire with Shop',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ShopWise will use these details to prepare your enquiry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DirectPurchaseCheckoutScreen extends StatelessWidget {
  final ShopWiseOrder order;

  const DirectPurchaseCheckoutScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        elevation: 0,
        foregroundColor: ShopWiseColors.textPrimary,
        title: const Text(
          'Order Confirmed',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.check_circle_rounded,
              color: ShopWiseColors.emerald,
              size: 72,
            ),
            const SizedBox(height: 18),
            const Text(
              'Order placed successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ShopWiseColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.purchaseMode == 'online'
                  ? 'Your order will be delivered by the shop.'
                  : 'Your order is reserved for pickup at the shop.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '₹${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: ShopWiseColors.emerald,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ShopWiseColors.emerald,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ShopWiseRadius.large),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
                child: const Text(
                  'View Order',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _BuyButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 19),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ShopWiseColors.emerald,
          disabledBackgroundColor: ShopWiseColors.border,
          foregroundColor: Colors.white,
          disabledForegroundColor: ShopWiseColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
          ),
        ),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  final Product product;
  final String shopName;

  const _ProductSummary({required this.product, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ShopWiseColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              image: product.imageUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.imageUrls.isEmpty
                ? const Icon(
                    Icons.inventory_2_outlined,
                    color: ShopWiseColors.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: ShopWiseColors.emerald,
                    fontSize: 15,
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
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ShopWiseColors.oliveSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: ShopWiseColors.border),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 19,
                  color: ShopWiseColors.olive,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: ShopWiseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: ShopWiseColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopWiseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ShopWiseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: ShopWiseColors.emerald,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
