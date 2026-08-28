import 'package:flutter/material.dart';

import '../../../models/product.dart';

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

  static const Color primary = Color(0xFF10B981);
  static const Color dark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final bool available = product.isAvailable && product.stock > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
              label: isWishlisted ? 'Saved' : 'Save',
              onTap: isLoading ? null : onWishlist,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: isCompared
                  ? Icons.check_circle_rounded
                  : Icons.compare_arrows_rounded,
              label: isCompared ? 'Added' : 'Compare',
              onTap: isLoading ? null : onCompare,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.ios_share_rounded,
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
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
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
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 54,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF334155)),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
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
