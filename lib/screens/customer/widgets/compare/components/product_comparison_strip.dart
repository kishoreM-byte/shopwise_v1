import 'package:flutter/material.dart';

import '../../../../../theme/design_tokens.dart';
import '../../../../../models/shop.dart';
import '../../../product_details_screen.dart';
import '../../../../../services/customer/comparison_engine.dart';

class ProductComparisonStrip extends StatelessWidget {
  const ProductComparisonStrip({
    super.key,
    required this.result,
    required this.shopsById,
    required this.onRemove,
  });

  final ComparisonResult result;
  final Map<String, Shop> shopsById;
  final Future<void> Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = (292 + ((textScale - 1).clamp(0, 1) * 112)).toDouble();

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: result.products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = result.products[index];

          return CompareProductCard(
            item: item,
            shopName: shopsById[item.product.shopId]?.name ?? 'Shop',
            isWinner: item.product.id == result.bestSmartScoreProductId,
            isLowestPrice: item.product.id == result.lowestPriceProductId,
            onRemove: () => onRemove(item.product.id),
          );
        },
      ),
    );
  }
}

class CompareProductCard extends StatelessWidget {
  const CompareProductCard({
    super.key,
    required this.item,
    required this.shopName,
    required this.isWinner,
    required this.isLowestPrice,
    required this.onRemove,
  });

  final ComparisonProduct item;
  final String shopName;
  final bool isWinner;
  final bool isLowestPrice;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final cardWidth = (MediaQuery.sizeOf(context).width - 40)
        .clamp(178.0, 220.0)
        .toDouble();
    final isAvailable = product.isAvailable && product.stock > 0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: ShopWiseElevation.subtle,
        color: ShopWiseColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.large),
          side: BorderSide(
            color: isWinner || isLowestPrice
                ? ShopWiseColors.olive.withValues(alpha: 0.55)
                : ShopWiseColors.border,
            width: isWinner || isLowestPrice ? 1.5 : 1,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const ProductImagePlaceholder(),
                            )
                          : const ProductImagePlaceholder(),
                    ),
                    if (isWinner || isLowestPrice)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLowestPrice)
                              const _CompareBadge(
                                label: 'LOWEST PRICE',
                                color: ShopWiseColors.emeraldDeep,
                              ),
                            if (isWinner) ...[
                              if (isLowestPrice) const SizedBox(height: 5),
                              const _CompareBadge(
                                label: 'SMART PICK',
                                color: ShopWiseColors.olive,
                              ),
                            ],
                          ],
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onRemove,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: ShopWiseColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ShopWiseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: ShopWiseColors.olive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: ShopWiseColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating > 0
                              ? product.rating.toStringAsFixed(1)
                              : 'New',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ShopWiseColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${product.reviewCount} reviews',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: ShopWiseColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isAvailable
                                ? 'In stock · ${product.stock}'
                                : 'Unavailable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvailable
                                  ? ShopWiseColors.success
                                  : ShopWiseColors.error,
                            ),
                          ),
                        ),
                        Icon(
                          product.hasOffer
                              ? Icons.local_offer_rounded
                              : Icons.local_offer_outlined,
                          color: product.hasOffer
                              ? ShopWiseColors.olive
                              : ShopWiseColors.textMuted,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.hasOffer ? 'Offer' : 'No offer',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: product.hasOffer
                                ? ShopWiseColors.olive
                                : ShopWiseColors.textSecondary,
                          ),
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

class _CompareBadge extends StatelessWidget {
  const _CompareBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ShopWiseRadius.pill),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: .45,
        ),
      ),
    );
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ShopWiseColors.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 34,
        color: ShopWiseColors.olive,
      ),
    );
  }
}
