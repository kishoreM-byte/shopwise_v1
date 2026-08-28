import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import '../../../../theme/design_tokens.dart';
import '../../product_details_screen.dart';

class HomeProductResults extends StatelessWidget {
  const HomeProductResults({
    super.key,
    required this.products,
    required this.searchQuery,
    required this.selectedCategory,
    required this.minPrice,
    required this.maxPrice,
    required this.availableOnly,
    required this.onEmptyState,
  });

  final List<Product> products;
  final String searchQuery;
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final bool availableOnly;
  final Widget Function({
    required IconData icon,
    required String title,
    required String subtitle,
  }) onEmptyState;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery;

    final filteredProducts = products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);

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
        icon: Icons.search_off,
        title: query.isEmpty && !hasFilters
            ? 'No products available'
            : 'No matching products',
        subtitle: query.isEmpty && !hasFilters
            ? 'Products added by shop owners will appear here.'
            : 'Try changing your search or filters.',
      );
    }

    return ListView.separated(
      itemCount: filteredProducts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];

        return Card(
          elevation: 0,
          color: ShopWiseColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: ShopWiseColors.surfaceSoft,
                      borderRadius:
                          BorderRadius.circular(ShopWiseRadius.small),
                    ),
                    child: product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(ShopWiseRadius.small),
                            child: Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) {
                                return const Icon(
                                  Icons.inventory_2_outlined,
                                  color: ShopWiseColors.emerald,
                                  size: 30,
                                );
                              },
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
                          maxLines: 1,
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
                            if (product.isAvailable && product.stock > 0) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: ShopWiseColors.emerald,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ShopWiseColors.emerald,
                                ),
                              ),
                            ],
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: ShopWiseColors.textMuted,
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
      },
    );
  }
}
