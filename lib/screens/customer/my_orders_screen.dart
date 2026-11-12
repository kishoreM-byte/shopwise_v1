import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/customer/order_service.dart';
import '../../theme/design_tokens.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Stream<List<ShopWiseOrder>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = OrderService().watchMyOrders();
  }

  void _retryLoading() {
    setState(() => _ordersStream = OrderService().watchMyOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        foregroundColor: ShopWiseColors.textPrimary,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<ShopWiseOrder>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load orders',
              message: 'Please try again.',
              onRetry: _retryLoading,
            );
          }

          final orders = snapshot.data ?? <ShopWiseOrder>[];

          if (orders.isEmpty) {
            return const _MessageState(
              icon: Icons.shopping_bag_outlined,
              title: 'No orders yet',
              message: 'Your online and offline purchases will appear here.',
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];

              return _OrderCard(
                order: order,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final ShopWiseOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOnline = order.purchaseMode == 'online';

    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
            border: Border.all(color: ShopWiseColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ShopWiseColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isOnline
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  color: ShopWiseColors.emerald,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ShopWiseColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${isOnline ? 'Online' : 'Offline'} • '
                      '${order.fulfillmentType == 'pickup' ? 'Pickup' : 'Delivery'}',
                      style: const TextStyle(
                        color: ShopWiseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.hasValidPriceBreakdown
                          ? 'Qty ${order.quantity} • ₹${order.totalAmount.toStringAsFixed(0)}'
                          : 'Qty ${order.quantity} • Total unavailable',
                      style: const TextStyle(
                        color: ShopWiseColors.emerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: ShopWiseColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ShopWiseColors.emerald),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ShopWiseColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: ShopWiseColors.emerald,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
