import 'package:flutter/material.dart';

import '../../../../../services/customer/comparison_engine.dart';
import '../../../../../theme/design_tokens.dart';

class ComparisonHero extends StatelessWidget {
  const ComparisonHero({super.key, required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final winnerId = result.bestSmartScoreProductId;

    final winner = result.products.firstWhere(
      (item) => item.product.id == winnerId,
      orElse: () => result.products.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ShopWiseColors.emerald.withValues(alpha: 0.14),
            ShopWiseColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ShopWiseColors.emerald.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ShopWiseColors.emerald,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ShopWise pick',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ShopWiseColors.emerald,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  winner.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ShopWiseColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${winner.smartScore.score.toStringAsFixed(0)}/100 Smart Score',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ShopWiseColors.textSecondary,
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
