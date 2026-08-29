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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$productCount of ${ComparisonEngine.maxProducts} products',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ShopWiseColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline_rounded, size: 19),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}
