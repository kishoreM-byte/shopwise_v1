import 'package:flutter/material.dart';

import '../../../../../services/customer/comparison_engine.dart';
import '../../../../../theme/design_tokens.dart';

class ComparisonHero extends StatelessWidget {
  const ComparisonHero({super.key, required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final winnerId = result.bestSmartScoreProductId;

    if (winnerId == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ShopWiseColors.surface,
          borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
          border: Border.all(color: ShopWiseColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: ShopWiseColors.olive),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'A Smart Pick is unavailable because comparable listed prices are missing.',
                style: TextStyle(
                  color: ShopWiseColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final winner = result.products.firstWhere(
      (item) => item.product.id == winnerId,
      orElse: () => result.products.first,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
        border: Border.all(color: ShopWiseColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D302C24),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: ShopWiseColors.olive,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHOPWISE PICK',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ShopWiseColors.olive,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  winner.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ShopWiseColors.oliveSoft,
                        borderRadius: BorderRadius.circular(
                          ShopWiseRadius.pill,
                        ),
                      ),
                      child: Text(
                        '${winner.smartScore.score.toStringAsFixed(0)}/100 Smart Score',
                        style: const TextStyle(
                          color: ShopWiseColors.olive,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (result.lowestPriceProductId == winner.product.id)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ShopWiseColors.emeraldSoft,
                          borderRadius: BorderRadius.circular(
                            ShopWiseRadius.pill,
                          ),
                        ),
                        child: const Text(
                          'LOWEST PRICE',
                          style: TextStyle(
                            color: ShopWiseColors.emeraldDeep,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Score components: ${winner.smartScore.componentSummary}. '
                  '${result.smartScoreCostSummary}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
