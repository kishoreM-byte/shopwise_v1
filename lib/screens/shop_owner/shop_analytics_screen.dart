import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/design_tokens.dart';

class ShopAnalyticsScreen extends StatefulWidget {
  const ShopAnalyticsScreen({super.key, this.watchProducts});

  final Stream<List<Product>> Function()? watchProducts;

  @override
  State<ShopAnalyticsScreen> createState() => _ShopAnalyticsScreenState();
}

class _ShopAnalyticsScreenState extends State<ShopAnalyticsScreen> {
  late Stream<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _watchProducts();
  }

  Stream<List<Product>> _watchProducts() =>
      widget.watchProducts?.call() ?? ProductService().watchMyProducts();

  void _retry() => setState(() => _products = _watchProducts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        title: Text('Analytics', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _products,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _AnalyticsMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Analytics unavailable',
              message: 'Your catalogue could not be loaded.',
              action: 'Try again',
              onAction: _retry,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: ShopWiseColors.emerald),
            );
          }

          final products = snapshot.data ?? const <Product>[];
          final available = products
              .where((product) => product.isAvailable && product.stock > 0)
              .length;
          final offers = products.where((product) => product.hasOffer).length;
          final outOfStock = products
              .where((product) => product.stock <= 0)
              .length;

          if (products.isEmpty) {
            return const _AnalyticsMessage(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              message: 'Add products to see your catalogue activity here.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Text(
                'Store overview',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'A quick view of your current product catalogue.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  final columns = constraints.maxWidth < 360 || largeText
                      ? 1
                      : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1
                        ? (largeText ? 2.0 : 4.2)
                        : 1.28,
                    children: [
                      _Metric(
                        title: 'Products',
                        value: '${products.length}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _Metric(
                        title: 'Available',
                        value: '$available',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      _Metric(
                        title: 'Offers',
                        value: '$offers',
                        icon: Icons.local_offer_outlined,
                      ),
                      _Metric(
                        title: 'Out of stock',
                        value: '$outOfStock',
                        icon: Icons.remove_shopping_cart_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ShopWiseColors.surface,
                  borderRadius: BorderRadius.circular(ShopWiseRadius.large),
                  border: Border.all(color: ShopWiseColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights_outlined,
                      color: ShopWiseColors.emerald,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Keep prices, offers and stock updated to help customers make informed decisions.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

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
          Icon(icon, color: ShopWiseColors.emerald, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ShopWiseColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMessage extends StatelessWidget {
  const _AnalyticsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: ShopWiseColors.emerald),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
