import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import '../../../../services/product_service.dart';
import '../../../../theme/design_tokens.dart';
import '../../product_details_screen.dart';

class HomeSavedProducts extends StatelessWidget {
  const HomeSavedProducts({
    super.key,
    required this.ids,
    required this.icon,
    required this.title,
    required this.emptySubtitle,
    required this.compareIds,
    required this.wishlistIds,
  });

  final Set<String> ids;
  final IconData icon;
  final String title;
  final String emptySubtitle;
  final Set<String> compareIds;
  final Set<String> wishlistIds;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return _emptyState(
        icon: icon,
        title: title,
        subtitle: emptySubtitle,
      );
    }

    return StreamBuilder<List<Product>>(
      stream: ProductService().watchAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final products = (snapshot.data ?? const <Product>[])
            .where((product) => ids.contains(product.id))
            .toList();

        if (products.isEmpty) {
          return _emptyState(
            icon: Icons.inventory_2_outlined,
            title: title,
            subtitle: 'The saved products are no longer available.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];

            return _SavedProductCard(
              product: product,
              isCompared: compareIds.contains(product.id),
              isWishlisted: wishlistIds.contains(product.id),
            );
          },
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: ShopWiseColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: ShopWiseColors.emerald,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ShopWiseColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedProductCard extends StatelessWidget {
  const _SavedProductCard({
    required this.product,
    required this.isCompared,
    required this.isWishlisted,
  });

  final Product product;
  final bool isCompared;
  final bool isWishlisted;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ShopWiseColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        side: const BorderSide(
          color: ShopWiseColors.border,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: ShopWiseColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(
                    ShopWiseRadius.small,
                  ),
                ),
                child: product.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          ShopWiseRadius.small,
                        ),
                        child: Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_outlined,
                            color: ShopWiseColors.emerald,
                            size: 30,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: ShopWiseColors.emerald,
                        size: 30,
                      ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ShopWiseColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShopWiseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ShopWiseColors.emerald,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : isCompared
                              ? Icons.compare_arrows_rounded
                              : Icons.chevron_right_rounded,
                          color: isWishlisted || isCompared
                              ? ShopWiseColors.emerald
                              : ShopWiseColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
