import 'package:flutter/material.dart';

import '../../../../theme/design_tokens.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onCompare,
    required this.onWishlist,
    required this.onEnquiries,
    required this.onOrders,
  });

  final VoidCallback onCompare;
  final VoidCallback onWishlist;
  final VoidCallback onEnquiries;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.compare_arrows_rounded,
        title: 'Compare',
        subtitle: 'Compare saved products',
        accent: ShopWiseColors.compare,
        onTap: onCompare,
      ),
      _QuickActionData(
        icon: Icons.favorite_rounded,
        title: 'Wishlist',
        subtitle: 'Your saved products',
        accent: ShopWiseColors.wishlist,
        onTap: onWishlist,
      ),
      _QuickActionData(
        icon: Icons.email_rounded,
        title: 'Enquiries',
        subtitle: 'Track requests',
        accent: ShopWiseColors.enquiries,
        onTap: onEnquiries,
      ),
      _QuickActionData(
        icon: Icons.shopping_bag_rounded,
        title: 'Orders',
        subtitle: 'Track your purchases',
        accent: ShopWiseColors.emerald,
        onTap: onOrders,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        final spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: cardWidth,
                child: _ActionCard(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopWiseColors.surface,
      elevation: ShopWiseElevation.subtle / 2,
      shadowColor: ShopWiseColors.textPrimary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        side: const BorderSide(color: ShopWiseColors.border),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
                ),
                child: Icon(action.icon, color: action.accent, size: 20),
              ),
              const SizedBox(height: 11),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ShopWiseColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ShopWiseColors.textMuted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
