import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import '../../../../models/shop.dart';
import '../../../../theme/design_tokens.dart';
import '../../product_details_screen.dart';

class HomeProductResults extends StatelessWidget {
  const HomeProductResults({
    super.key,
    required this.products,
    required this.shopsById,
    required this.searchQuery,
    required this.selectedCategory,
    required this.minPrice,
    required this.maxPrice,
    required this.availableOnly,
    required this.onEmptyState,
  });

  final List<Product> products;
  final Map<String, Shop> shopsById;
  final String searchQuery;
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final bool availableOnly;

  final Widget Function({
    required IconData icon,
    required String title,
    required String subtitle,
  })
  onEmptyState;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();

    final filteredProducts = products.where((product) {
      final shop = shopsById[product.shopId];

      final productName = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      final description = product.description.toLowerCase();
      final shopName = shop?.name.toLowerCase() ?? '';

      final matchesQuery =
          query.isEmpty ||
          productName.contains(query) ||
          category.contains(query) ||
          description.contains(query) ||
          shopName.contains(query);

      final matchesCategory =
          selectedCategory == null ||
          product.category.toLowerCase() == selectedCategory!.toLowerCase();

      final matchesMinPrice = minPrice == null || product.price >= minPrice!;

      final matchesMaxPrice = maxPrice == null || product.price <= maxPrice!;

      final matchesAvailability =
          !availableOnly || (product.isAvailable && product.stock > 0);

      return matchesQuery &&
          matchesCategory &&
          matchesMinPrice &&
          matchesMaxPrice &&
          matchesAvailability;
    }).toList();

    if (filteredProducts.isEmpty) {
      final hasFilters =
          selectedCategory != null ||
          minPrice != null ||
          maxPrice != null ||
          availableOnly;

      return onEmptyState(
        icon: Icons.search_off_rounded,
        title: query.isEmpty && !hasFilters
            ? 'No products available'
            : 'No matching products',
        subtitle: query.isEmpty && !hasFilters
            ? 'Products added by shop owners will appear here.'
            : 'Try changing your search or filters.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filteredProducts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final shop = shopsById[product.shopId];

        return _ProductResultCard(
          product: product,
          shop: shop,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({
    required this.product,
    required this.shop,
    required this.onTap,
  });

  final Product product;
  final Shop? shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool available = product.isAvailable && product.stock > 0;

    final bool hasDiscount =
        product.originalPrice != null && product.originalPrice! > product.price;

    final int discountPercent = hasDiscount
        ? (((product.originalPrice! - product.price) / product.originalPrice!) *
                  100)
              .round()
        : 0;

    final bool hasRating = product.rating > 0 && product.reviewCount > 0;

    final bool hasOffer =
        product.hasOffer &&
        product.offerText != null &&
        product.offerText!.trim().isNotEmpty;

    final String shopName = shop?.name.trim().isNotEmpty == true
        ? shop!.name.trim()
        : 'Shop details unavailable';

    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        splashColor: ShopWiseColors.emeraldSoft,
        highlightColor: ShopWiseColors.emeraldSoft.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(
                imageUrl: product.imageUrls.isNotEmpty
                    ? product.imageUrls.first
                    : null,
                discountPercent: discountPercent,
                hasOffer: hasOffer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 142,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.trim().isNotEmpty
                            ? product.name.trim()
                            : 'Unnamed product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: ShopWiseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: ShopWiseColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ShopWiseColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _CategoryPill(label: product.category),
                          if (hasRating) ...[
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: ShopWiseColors.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: ShopWiseColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '(${product.reviewCount})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ShopWiseColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: ShopWiseColors.emerald,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 7),
                            Text(
                              '₹${product.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ShopWiseColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 21,
                            color: ShopWiseColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            available
                                ? Icons.check_circle_rounded
                                : Icons.remove_circle_outline_rounded,
                            size: 14,
                            color: available
                                ? ShopWiseColors.success
                                : ShopWiseColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            available
                                ? product.stock <= 5
                                      ? 'Only ${product.stock} left'
                                      : 'Available'
                                : 'Currently unavailable',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: available
                                  ? ShopWiseColors.success
                                  : ShopWiseColors.textMuted,
                            ),
                          ),
                          if (hasOffer) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                product.offerText!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: ShopWiseColors.search,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.discountPercent,
    required this.hasOffer,
  });

  final String? imageUrl;
  final int discountPercent;
  final bool hasOffer;

  @override
  Widget build(BuildContext context) {
    final bool showBadge = discountPercent > 0 || hasOffer;

    return SizedBox(
      width: 82,
      height: 142,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 82,
            height: 142,
            decoration: BoxDecoration(
              color: ShopWiseColors.surfaceSoft,
              borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
              border: Border.all(
                color: ShopWiseColors.border.withValues(alpha: 0.7),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl!.trim().isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => const _ImageFallback(),
                  )
                : const _ImageFallback(),
          ),
          if (showBadge)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: ShopWiseColors.emerald,
                  borderRadius: BorderRadius.circular(ShopWiseRadius.pill),
                ),
                child: Text(
                  discountPercent > 0 ? '$discountPercent% OFF' : 'OFFER',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 30,
        color: ShopWiseColors.emerald,
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final String value = label.trim().isEmpty ? 'General' : label.trim();

    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(ShopWiseRadius.pill),
        border: Border.all(
          color: ShopWiseColors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: ShopWiseColors.textSecondary,
        ),
      ),
    );
  }
}
