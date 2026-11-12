import 'package:flutter/material.dart';

import '../../../../../services/customer/comparison_engine.dart';
import '../../../../../theme/design_tokens.dart';

class CompareHeader extends StatelessWidget {
  const CompareHeader({
    super.key,
    required this.productCount,
    required this.onClear,
  });

  final int productCount;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compare products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ShopWiseColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.65,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ShopWiseColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(ShopWiseRadius.pill),
                ),
                child: Text(
                  '$productCount of ${ComparisonEngine.maxProducts} products',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ShopWiseColors.emeraldDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onClear,
          style: TextButton.styleFrom(
            foregroundColor: ShopWiseColors.textSecondary,
            backgroundColor: ShopWiseColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShopWiseRadius.pill),
              side: const BorderSide(color: ShopWiseColors.border),
            ),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 19),
          label: const Text('Clear', maxLines: 1),
        ),
      ],
    );
  }
}
