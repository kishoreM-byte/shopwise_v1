import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/design_tokens.dart';

class OrderDetailsScreen extends StatelessWidget {
  final ShopWiseOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        elevation: 0,
        foregroundColor: ShopWiseColors.textPrimary,
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          _statusCard(),
          const SizedBox(height: 16),
          _section(
            title: 'Order',
            children: [
              _row('Order ID', order.id),
              _row('Product', order.productName),
              _row('Quantity', '×${order.quantity}'),
              _row('Status', order.status.toUpperCase()),
              _row('Placed', _formatDate(order.createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Price breakdown',
            children: order.hasValidPriceBreakdown
                ? [
                    _row(
                      'Unit price',
                      '₹${order.unitPrice.toStringAsFixed(0)}',
                    ),
                    _row('Subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
                    _row(
                      'Delivery',
                      '₹${order.deliveryCharge.toStringAsFixed(0)}',
                    ),
                    _row(
                      'Installation',
                      '₹${order.installationCharge.toStringAsFixed(0)}',
                    ),
                    const Divider(height: 22),
                    _row(
                      'Total',
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      strong: true,
                    ),
                  ]
                : [
                    const Text(
                      'Price details are unavailable for this order.',
                      style: TextStyle(color: ShopWiseColors.textSecondary),
                    ),
                  ],
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Order lifecycle',
            children: [
              _lifecycle(
                'Placed',
                order.status == 'placed' ||
                    order.status == 'accepted' ||
                    order.status == 'completed',
                Icons.receipt_long_rounded,
              ),
              _lifecycle(
                'Accepted',
                order.status == 'accepted' || order.status == 'completed',
                Icons.check_circle_outline_rounded,
              ),
              _lifecycle(
                'Completed',
                order.status == 'completed',
                Icons.task_alt_rounded,
              ),
              if (order.status == 'cancelled')
                _lifecycle('Cancelled', true, Icons.cancel_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final label = switch (order.status.trim().toLowerCase()) {
      'placed' => 'Order placed',
      'accepted' => 'Order accepted',
      'completed' => 'Order completed',
      'cancelled' => 'Order cancelled',
      _ => 'Order status unavailable',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ShopWiseColors.textPrimary, ShopWiseColors.emeraldDeep],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ShopWiseColors.emerald.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: ShopWiseColors.emerald,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ShopWiseColors.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.hasValidPriceBreakdown
                      ? '₹${order.totalAmount.toStringAsFixed(0)}'
                      : 'Total unavailable',
                  style: const TextStyle(
                    color: ShopWiseColors.emerald,
                    fontSize: 14,
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

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ShopWiseColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: strong
                    ? ShopWiseColors.emeraldDeep
                    : ShopWiseColors.textPrimary,
                fontSize: strong ? 16 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifecycle(String title, bool active, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: active ? ShopWiseColors.emerald : ShopWiseColors.border,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: active
                  ? ShopWiseColors.textPrimary
                  : ShopWiseColors.textMuted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
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
