import 'package:flutter/material.dart';

import '../../../../theme/design_tokens.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({
    super.key,
    required this.onNearbyShops,
    required this.onBestDeals,
    required this.onSmartScore,
    required this.onSmartTrip,
    required this.onEnquiries,
  });

  final VoidCallback onNearbyShops;
  final VoidCallback onBestDeals;
  final VoidCallback onSmartScore;
  final VoidCallback onSmartTrip;
  final VoidCallback onEnquiries;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.storefront_rounded,
                title: 'Nearby Shops',
                subtitle: 'Find shops around you',
                accent: ShopWiseColors.trip,
                onTap: onNearbyShops,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: Icons.local_offer_rounded,
                title: 'Best Deals',
                subtitle: 'Discover active offers',
                accent: ShopWiseColors.warning,
                onTap: onBestDeals,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Smart Score',
                subtitle: 'Rank products intelligently',
                accent: ShopWiseColors.smart,
                onTap: onSmartScore,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: Icons.route_rounded,
                title: 'Smart Trip',
                subtitle: 'Compare travel cost',
                accent: ShopWiseColors.trip,
                onTap: onSmartTrip,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.forum_rounded,
          title: 'My Enquiries',
          subtitle: 'Track your product requests',
          accent: ShopWiseColors.enquiries,
          wide: true,
          onTap: onEnquiries,
        ),
      ],
    );
  
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.wide = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ShopWiseColors.surface,
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
            border: Border.all(color: ShopWiseColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ShopWiseColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ShopWiseColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (wide) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: ShopWiseColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
