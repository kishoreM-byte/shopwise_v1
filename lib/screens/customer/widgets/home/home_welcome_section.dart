import 'package:flutter/material.dart';

import '../../../../theme/design_tokens.dart';

class HomeWelcomeSection extends StatelessWidget {
  const HomeWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LOCAL SHOPPING GUIDE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ShopWiseColors.olive,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Find better.\nShop smarter.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 27,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Compare prices and discover better deals near you.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ShopWiseColors.textSecondary,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: ShopWiseColors.border.withValues(alpha: 0.8),
              ),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: ShopWiseColors.olive,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }
}
