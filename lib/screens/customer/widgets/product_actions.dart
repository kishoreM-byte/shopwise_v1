import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../theme/design_tokens.dart';

class ProductActions extends StatelessWidget {
  final Product product;
  final VoidCallback? onWishlist;
  final VoidCallback? onShare;
  final VoidCallback? onCompare;
  final VoidCallback? onBuyEnquire;
  final bool isWishlisted;
  final bool isCompared;
  final bool isLoading;

  const ProductActions({
    super.key,
    required this.product,
    this.onWishlist,
    this.onShare,
    this.onCompare,
    this.onBuyEnquire,
    this.isWishlisted = false,
    this.isCompared = false,
    this.isLoading = false,
  });

  static const Color primary = ShopWiseColors.emerald;
  static const Color dark = ShopWiseColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    final bool available = product.isAvailable && product.stock > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: ShopWiseColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            _ActionButton(
              icon: isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: const Color(0xFFB85C62),
              label: isWishlisted ? 'Saved' : 'Save',
              onTap: isLoading ? null : onWishlist,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: isCompared
                  ? Icons.check_circle_rounded
                  : Icons.compare_arrows_rounded,
              iconColor: const Color(0xFF687348),
              label: isCompared ? 'Added' : 'Compare',
              onTap: isLoading ? null : onCompare,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.ios_share_rounded,
              iconColor: const Color(0xFFB17B45),
              label: 'Share',
              onTap: isLoading ? null : onShare,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: available ? onBuyEnquire : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: ShopWiseColors.surfaceSoft,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: ShopWiseColors.textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ShopWiseRadius.large),
                    ),
                  ),
                  child: Text(
                    available ? 'Buy / Enquire' : 'Unavailable',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopWiseColors.surfaceSoft,
      borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
        child: SizedBox(
          width: 54,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: ShopWiseColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
