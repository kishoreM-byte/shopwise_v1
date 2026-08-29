import 'package:flutter/material.dart';

import '../../../../../theme/design_tokens.dart';
import '../../../product_details_screen.dart';
import '../../../../../services/customer/comparison_engine.dart';

class ProductComparisonStrip extends StatelessWidget {
  const ProductComparisonStrip({
    super.key,
    required this.result,
    required this.onRemove,
  });

  final ComparisonResult result;
  final Future<void> Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: result.products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = result.products[index];

          return CompareProductCard(
            item: item,
            isWinner: item.product.id == result.bestSmartScoreProductId,
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
    required this.isWinner,
    required this.onRemove,
  });

  final ComparisonProduct item;
  final bool isWinner;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return SizedBox(
      width: 190,
      child: Card(
        elevation: 0,
        color: ShopWiseColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isWinner
                ? ShopWiseColors.emerald.withValues(alpha: 0.5)
                : ShopWiseColors.border,
            width: isWinner ? 1.5 : 1,
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
                height: 105,
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
                    if (isWinner)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ShopWiseColors.emerald,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.48),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onRemove,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ShopWiseColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ShopWiseColors.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: ShopWiseColors.emerald,
      ),
    );
  }
}
