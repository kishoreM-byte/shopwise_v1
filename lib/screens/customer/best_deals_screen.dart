import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/design_tokens.dart';
import 'product_details_screen.dart';
import 'widgets/home/home_empty_state.dart';

class BestDealsScreen extends StatefulWidget {
  const BestDealsScreen({super.key, this.watchProducts});

  final Stream<List<Product>> Function()? watchProducts;

  @override
  State<BestDealsScreen> createState() => _BestDealsScreenState();
}

class _BestDealsScreenState extends State<BestDealsScreen> {
  late Stream<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _watchProducts();
  }

  Stream<List<Product>> _watchProducts() =>
      widget.watchProducts?.call() ?? ProductService().watchAllProducts();

  void _retry() => setState(() => _products = _watchProducts());

  double _discount(Product product) {
    final original = product.originalPrice;
    if (original == null || original <= product.price) return 0;
    return ((original - product.price) / original) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        title: Text(
          'Best Deals',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: ShopWiseColors.background,
      ),
      body: StreamBuilder<List<Product>>(
        stream: _products,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _RetryState(
              title: 'Deals are unavailable',
              message: 'Check your connection and try again.',
              onRetry: _retry,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: ShopWiseColors.emerald),
            );
          }

          final products =
              (snapshot.data ?? const <Product>[])
                  .where((product) => product.isAvailable && product.hasOffer)
                  .toList()
                ..sort((a, b) => _discount(b).compareTo(_discount(a)));

          if (products.isEmpty) {
            return const HomeEmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No active deals',
              subtitle: 'Check back soon for offers from nearby shops.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final discount = _discount(product);
              return Card(
                color: ShopWiseColors.surface,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
                  side: const BorderSide(color: ShopWiseColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _DealImage(
                          url: product.imageUrls.isEmpty
                              ? null
                              : product.imageUrls.first,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (discount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ShopWiseColors.oliveSoft,
                                    border: Border.all(
                                      color: ShopWiseColors.border,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      ShopWiseRadius.small,
                                    ),
                                  ),
                                  child: Text(
                                    '${discount.toStringAsFixed(0)}% OFF',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: ShopWiseColors.search,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              const SizedBox(height: 7),
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: ShopWiseColors.emeraldDeep,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  if (product.originalPrice != null &&
                                      product.originalPrice! > product.price)
                                    Text(
                                      '₹${product.originalPrice!.toStringAsFixed(0)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: ShopWiseColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DealImage extends StatelessWidget {
  const _DealImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const _DealImageFallback()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const _DealImageFallback(loading: true),
              errorBuilder: (_, _, _) => const _DealImageFallback(),
            ),
    );
  }
}

class _DealImageFallback extends StatelessWidget {
  const _DealImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShopWiseColors.emerald,
              ),
            )
          : const Icon(
              Icons.chair_outlined,
              color: ShopWiseColors.emerald,
              size: 30,
            ),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: ShopWiseColors.emerald,
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
