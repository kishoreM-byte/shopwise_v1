import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

import '../../models/order.dart';
import '../../services/customer/order_service.dart';

class ShopOwnerOrdersScreen extends StatefulWidget {
  const ShopOwnerOrdersScreen({super.key});

  static const Color primary = ShopWiseColors.olive;
  static const Color background = ShopWiseColors.background;
  static const Color textPrimary = ShopWiseColors.textPrimary;
  static const Color textSecondary = ShopWiseColors.textSecondary;
  static const Color border = ShopWiseColors.border;

  @override
  State<ShopOwnerOrdersScreen> createState() => _ShopOwnerOrdersScreenState();
}

class _ShopOwnerOrdersScreenState extends State<ShopOwnerOrdersScreen> {
  static const Color primary = ShopOwnerOrdersScreen.primary;
  static const Color background = ShopOwnerOrdersScreen.background;
  static const Color textPrimary = ShopOwnerOrdersScreen.textPrimary;
  static const Color textSecondary = ShopOwnerOrdersScreen.textSecondary;
  static const Color border = ShopOwnerOrdersScreen.border;

  late Stream<List<ShopWiseOrder>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = OrderService().watchShopOwnerOrders();
  }

  void _retryLoading() {
    setState(() => _ordersStream = OrderService().watchShopOwnerOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopOwnerOrdersScreen.background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: ShopOwnerOrdersScreen.textPrimary,
        title: const Text(
          'Orders',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<List<ShopWiseOrder>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ShopOwnerOrdersScreen.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return _errorState(snapshot.error);
          }

          final orders = snapshot.data ?? const <ShopWiseOrder>[];

          if (orders.isEmpty) {
            return _emptyState();
          }

          final placed = orders.where((o) => o.status == 'placed').length;
          final accepted = orders.where((o) => o.status == 'accepted').length;
          final completed = orders.where((o) => o.status == 'completed').length;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _summaryCard(
                total: orders.length,
                placed: placed,
                accepted: accepted,
                completed: completed,
              ),
              const SizedBox(height: 20),
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _orderCard(context, order),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required int total,
    required int placed,
    required int accepted,
    required int completed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ShopWiseColors.surfaceSoft, ShopWiseColors.oliveSoft],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order overview',
            style: TextStyle(
              color: ShopWiseColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metric('$total', 'Total')),
              _divider(),
              Expanded(child: _metric('$placed', 'New')),
              _divider(),
              Expanded(child: _metric('$accepted', 'Active')),
              _divider(),
              Expanded(child: _metric('$completed', 'Done')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: ShopWiseColors.success,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: ShopWiseColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 34,
      color: ShopWiseColors.olive.withValues(alpha: 0.18),
    );
  }

  Widget _orderCard(BuildContext context, ShopWiseOrder order) {
    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showOrderDetails(context, order),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                      Icons.shopping_bag_rounded,
                      color: ShopWiseColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName.isEmpty
                              ? 'Order'
                              : order.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: ShopWiseColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Customer • ${order.quantity} unit${order.quantity == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      order.hasValidPriceBreakdown
                          ? '₹${order.totalAmount.toStringAsFixed(0)}'
                          : 'Unavailable',
                      style: const TextStyle(
                        color: ShopWiseColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View details',
                    style: TextStyle(
                      color: ShopWiseColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: ShopWiseColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    late final Color foreground;
    late final Color background;
    late final String label;

    switch (status) {
      case 'accepted':
        foreground = ShopWiseColors.olive;
        background = ShopWiseColors.oliveSoft;
        label = 'ACCEPTED';
        break;
      case 'completed':
        foreground = ShopWiseColors.textPrimary;
        background = ShopWiseColors.oliveSoft;
        label = 'COMPLETED';
        break;
      case 'cancelled':
        foreground = ShopWiseColors.wishlist;
        background = ShopWiseColors.surfaceSoft;
        label = 'CANCELLED';
        break;
      case 'placed':
        foreground = ShopWiseColors.search;
        background = ShopWiseColors.surfaceSoft;
        label = 'NEW ORDER';
        break;
      default:
        foreground = textSecondary;
        background = ShopWiseColors.background;
        label = 'STATUS UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(
    BuildContext context,
    ShopWiseOrder order,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OwnerOrderSheet(order: order),
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
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No orders yet',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Orders created from accepted customer enquiries will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load orders',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: primary),
            ),
          ],
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

class _OwnerOrderSheet extends StatefulWidget {
  final ShopWiseOrder order;

  const _OwnerOrderSheet({required this.order});

  @override
  State<_OwnerOrderSheet> createState() => _OwnerOrderSheetState();
}

class _OwnerOrderSheetState extends State<_OwnerOrderSheet> {
  static const Color primary = ShopWiseColors.olive;
  static const Color textPrimary = ShopWiseColors.textPrimary;
  static const Color textSecondary = ShopWiseColors.textSecondary;

  final OrderService _orderService = OrderService();

  bool _updating = false;

  Future<void> _updateStatus(String status) async {
    if (_updating) return;

    setState(() => _updating = true);

    try {
      await _orderService.updateOrderStatus(widget.order.id, status);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Order accepted.'
                : status == 'completed'
                ? 'Order marked as completed.'
                : 'Order cancelled.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _updating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: ShopWiseColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order details',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${order.id}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(order.status),
              ],
            ),
            const SizedBox(height: 20),
            _infoCard(order),
            const SizedBox(height: 16),
            _priceSection(order),
            const SizedBox(height: 18),
            _actions(order),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(ShopWiseOrder order) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ShopWiseColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('Product', order.productName),
          _row(
            'Quantity',
            '${order.quantity} unit${order.quantity == 1 ? '' : 's'}',
          ),
          _row('Customer ID', _shortId(order.customerId)),
          _row('Enquiry ID', _shortId(order.enquiryId)),
        ],
      ),
    );
  }

  Widget _priceSection(ShopWiseOrder order) {
    if (!order.hasValidPriceBreakdown) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Price details are unavailable for this order.',
          style: TextStyle(color: textSecondary, fontSize: 11),
        ),
      );
    }

    return Column(
      children: [
        _row('Subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
        _row('Delivery', '₹${order.deliveryCharge.toStringAsFixed(0)}'),
        _row('Installation', '₹${order.installationCharge.toStringAsFixed(0)}'),
        const Divider(height: 18),
        _row('Total', '₹${order.totalAmount.toStringAsFixed(0)}', strong: true),
      ],
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textSecondary,
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
                color: strong ? ShopWiseColors.olive : textPrimary,
                fontSize: strong ? 16 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(ShopWiseOrder order) {
    if (order.status == 'placed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _updating
                  ? null
                  : () => _confirmStatus('cancelled', 'Cancel this order?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ShopWiseColors.wishlist,
                side: const BorderSide(color: Color(0xFFFECACA)),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _updating
                  ? null
                  : () => _confirmStatus('accepted', 'Accept this order?'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _buttonChild('Accept order'),
            ),
          ),
        ],
      );
    }

    if (order.status == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _updating
                  ? null
                  : () => _confirmStatus('cancelled', 'Cancel this order?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ShopWiseColors.wishlist,
                side: const BorderSide(color: Color(0xFFFECACA)),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _updating
                  ? null
                  : () => _confirmStatus(
                      'completed',
                      'Mark this order as completed?',
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _buttonChild('Mark completed'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(
          backgroundColor: ShopWiseColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Close',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buttonChild(String text) {
    if (_updating) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
    }

    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800));
  }

  Future<void> _confirmStatus(String status, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            status == 'accepted'
                ? 'The customer will see this order as accepted.'
                : status == 'completed'
                ? 'The customer will see this order as completed.'
                : 'The order will be marked as cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _updateStatus(status);
    }
  }

  Widget _statusBadge(String status) {
    late final Color foreground;
    late final Color background;
    late final String label;

    switch (status) {
      case 'accepted':
        foreground = ShopWiseColors.olive;
        background = ShopWiseColors.oliveSoft;
        label = 'ACCEPTED';
        break;
      case 'completed':
        foreground = ShopWiseColors.textPrimary;
        background = ShopWiseColors.oliveSoft;
        label = 'COMPLETED';
        break;
      case 'cancelled':
        foreground = ShopWiseColors.wishlist;
        background = ShopWiseColors.surfaceSoft;
        label = 'CANCELLED';
        break;
      case 'placed':
        foreground = ShopWiseColors.search;
        background = ShopWiseColors.surfaceSoft;
        label = 'NEW ORDER';
        break;
      default:
        foreground = textSecondary;
        background = ShopWiseColors.background;
        label = 'STATUS UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }

  String _shortId(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
  }
}
