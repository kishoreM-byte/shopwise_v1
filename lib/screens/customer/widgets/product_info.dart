import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

import '../../../models/product.dart';

class ProductInfo extends StatelessWidget {
  final Product product;

  const ProductInfo({super.key, required this.product});

  static const Color primary = ShopWiseColors.emerald;
  static const Color dark = ShopWiseColors.textPrimary;
  static const Color secondary = ShopWiseColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount =
        product.originalPrice != null && product.originalPrice! > product.price;

    final int discountPercent = hasDiscount
        ? (((product.originalPrice! - product.price) / product.originalPrice!) *
                  100)
              .round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),

        // Category
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              color: ShopWiseColors.emeraldDeep,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Product name
        Text(
          product.name,
          style: const TextStyle(
            color: dark,
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 14),

        // Rating
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 9,
          runSpacing: 7,
          children: [
            if (product.reviewCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: ShopWiseColors.search,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              product.reviewCount > 0
                  ? '${product.reviewCount} reviews'
                  : 'No reviews yet',
              style: const TextStyle(
                color: secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Price
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 9,
          runSpacing: 3,
          children: [
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: dark,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            if (hasDiscount) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '₹${product.originalPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: ShopWiseColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$discountPercent% OFF',
                  style: const TextStyle(
                    color: ShopWiseColors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Offer
        if (product.hasOffer &&
            product.offerText != null &&
            product.offerText!.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ShopWiseColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: ShopWiseColors.search,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: ShopWiseColors.surface,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    product.offerText!,
                    style: const TextStyle(
                      color: ShopWiseColors.search,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Availability
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: product.isAvailable && product.stock > 0
                ? ShopWiseColors.success.withValues(alpha: 0.10)
                : ShopWiseColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                product.isAvailable && product.stock > 0
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: product.isAvailable && product.stock > 0
                    ? ShopWiseColors.success
                    : ShopWiseColors.error,
              ),
              const SizedBox(width: 9),
              Text(
                product.isAvailable && product.stock > 0
                    ? '${product.stock} available'
                    : 'Currently unavailable',
                style: TextStyle(
                  color: product.isAvailable && product.stock > 0
                      ? ShopWiseColors.success
                      : ShopWiseColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Description
        const Text(
          'About this product',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          product.description.trim().isEmpty
              ? 'No description available for this product.'
              : product.description.trim(),
          style: const TextStyle(
            color: secondary,
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
