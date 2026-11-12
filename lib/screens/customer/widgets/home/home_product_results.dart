import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import '../../../../models/shop.dart';
import '../../../../theme/design_tokens.dart';
import '../../product_details_screen.dart';

enum ProductSortOption {
  recommended('Recommended'),
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  rating('Top rated');

  const ProductSortOption(this.label);

  final String label;
}

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
    required this.sortOption,
    required this.onSortChanged,
    required this.onClearSearchAndFilters,
    required this.onEmptyState,
  });

  final List<Product> products;
  final Map<String, Shop> shopsById;
  final String searchQuery;
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final bool availableOnly;
  final ProductSortOption sortOption;
  final ValueChanged<ProductSortOption> onSortChanged;
  final VoidCallback onClearSearchAndFilters;

  final Widget Function({
    required IconData icon,
    required String title,
    required String subtitle,
  })
  onEmptyState;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final normalizedCategory = selectedCategory?.trim().toLowerCase();

    final filteredProducts = products.where((product) {
      final shop = shopsById[product.shopId];

      final productName = product.name.trim().toLowerCase();
      final category = product.category.trim().toLowerCase();
      final description = product.description.trim().toLowerCase();
      final shopName = shop?.name.trim().toLowerCase() ?? '';

      final matchesQuery =
          query.isEmpty ||
          productName.contains(query) ||
          category.contains(query) ||
          description.contains(query) ||
          shopName.contains(query);

      final matchesCategory =
          normalizedCategory == null ||
          product.category.trim().toLowerCase() == normalizedCategory;

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

    final indexedProducts = filteredProducts.asMap().entries.toList();
    indexedProducts.sort((a, b) {
      final comparison = _compareProducts(a.value, b.value, sortOption);
      return comparison == 0 ? a.key.compareTo(b.key) : comparison;
    });
    final sortedProducts = indexedProducts.map((entry) => entry.value).toList();
    final hasActiveSearchOrFilters =
        query.isNotEmpty ||
        (selectedCategory?.trim().isNotEmpty ?? false) ||
        minPrice != null ||
        maxPrice != null ||
        availableOnly;

    return Column(
      children: [
        _ResultsToolbar(
          resultCount: sortedProducts.length,
          sortOption: sortOption,
          onSortChanged: onSortChanged,
        ),
        if (sortedProducts.isEmpty) ...[
          Expanded(
            child: onEmptyState(
              icon: Icons.search_off_rounded,
              title: hasActiveSearchOrFilters
                  ? 'No matching products'
                  : 'No products available',
              subtitle: hasActiveSearchOrFilters
                  ? 'Try changing your search or filters.'
                  : 'Products added by shop owners will appear here.',
            ),
          ),
          if (hasActiveSearchOrFilters)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: onClearSearchAndFilters,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Clear search and filters'),
              ),
            ),
        ] else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: sortedProducts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = sortedProducts[index];
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
            ),
          ),
      ],
    );
  }

  int _compareProducts(
    Product first,
    Product second,
    ProductSortOption option,
  ) {
    switch (option) {
      case ProductSortOption.priceLowToHigh:
        return first.price.compareTo(second.price);
      case ProductSortOption.priceHighToLow:
        return second.price.compareTo(first.price);
      case ProductSortOption.rating:
        final firstHasRating = first.rating > 0 && first.reviewCount > 0;
        final secondHasRating = second.rating > 0 && second.reviewCount > 0;
        if (firstHasRating != secondHasRating) {
          return firstHasRating ? -1 : 1;
        }
        return firstHasRating ? second.rating.compareTo(first.rating) : 0;
      case ProductSortOption.recommended:
        return 0;
    }
  }
}

class _ResultsToolbar extends StatelessWidget {
  const _ResultsToolbar({
    required this.resultCount,
    required this.sortOption,
    required this.onSortChanged,
  });

  final int resultCount;
  final ProductSortOption sortOption;
  final ValueChanged<ProductSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$resultCount ${resultCount == 1 ? 'product' : 'products'}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ShopWiseColors.textSecondary,
              ),
            ),
          ),
          PopupMenuButton<ProductSortOption>(
            tooltip: 'Sort products',
            onSelected: onSortChanged,
            itemBuilder: (context) => ProductSortOption.values
                .map(
                  (option) => PopupMenuItem<ProductSortOption>(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, maxWidth: 190),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: ShopWiseColors.surface,
                borderRadius: BorderRadius.circular(ShopWiseRadius.pill),
                border: Border.all(color: ShopWiseColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: ShopWiseColors.emeraldDeep,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      sortOption.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ShopWiseColors.emeraldDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      elevation: ShopWiseElevation.subtle / 2,
      shadowColor: ShopWiseColors.textPrimary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        side: const BorderSide(color: ShopWiseColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        splashColor: ShopWiseColors.emeraldSoft,
        highlightColor: ShopWiseColors.emeraldSoft.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
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
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryPill(label: product.category),
                        if (hasRating)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                              Text(
                                '(${product.reviewCount})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ShopWiseColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: ShopWiseColors.emerald,
                          ),
                        ),
                        if (hasDiscount)
                          Text(
                            '₹${product.originalPrice!.toStringAsFixed(0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ShopWiseColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
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
                        Expanded(
                          child: Text(
                            available
                                ? product.stock <= 5
                                      ? 'Only ${product.stock} left'
                                      : 'Available'
                                : 'Currently unavailable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: available
                                  ? ShopWiseColors.success
                                  : ShopWiseColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasOffer) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.offerText!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: ShopWiseColors.olive,
                        ),
                      ),
                    ],
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
                  color: ShopWiseColors.search,
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
