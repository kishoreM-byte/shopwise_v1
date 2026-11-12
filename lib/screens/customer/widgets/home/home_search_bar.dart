import 'package:flutter/material.dart';

import '../../../../theme/design_tokens.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        onTap: onTap,
        child: Ink(
          height: 62,
          decoration: BoxDecoration(
            color: ShopWiseColors.surface,
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
            border: Border.all(
              color: ShopWiseColors.border.withValues(alpha: 0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: ShopWiseColors.textPrimary.withValues(alpha: 0.055),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ShopWiseColors.olive.withValues(alpha: 0.16),
                        ShopWiseColors.emerald.withValues(alpha: 0.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: ShopWiseColors.olive,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What are you looking for?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ShopWiseColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Products • shops • deals',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ShopWiseColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ShopWiseColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: ShopWiseColors.textSecondary,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
