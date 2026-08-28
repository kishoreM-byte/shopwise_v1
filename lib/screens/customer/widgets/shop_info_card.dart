import 'package:flutter/material.dart';

import '../../../models/shop.dart';

class ShopInfoCard extends StatelessWidget {
  final Shop? shop;
  final bool isLoading;
  final String? errorMessage;

  const ShopInfoCard({
    super.key,
    required this.shop,
    this.isLoading = false,
    this.errorMessage,
  });

  static const Color primary = Color(0xFF10B981);
  static const Color dark = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoading();
    }

    if (shop == null) {
      return _buildUnavailable();
    }

    return _buildShop(context, shop!);
  }

  Widget _buildShop(BuildContext context, Shop shop) {
    final bool hasRating = shop.reviewCount > 0 && shop.rating > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShopAvatar(shop),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name.trim().isEmpty ? 'Shop' : shop.name.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (shop.category.trim().isNotEmpty)
                      Text(
                        shop.category.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              _buildOpenStatus(shop.isOpen),
            ],
          ),

          const SizedBox(height: 18),

          if (hasRating) ...[
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 19,
                ),
                const SizedBox(width: 5),
                Text(
                  shop.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${shop.reviewCount} reviews',
                  style: const TextStyle(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          if (shop.address.trim().isNotEmpty)
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              text: shop.address.trim(),
            ),

          if (shop.phone.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            _buildDetailRow(
              icon: Icons.phone_outlined,
              text: shop.phone.trim(),
            ),
          ],

          if (shop.description.trim().isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              shop.description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: secondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (shop.deliveryAvailable || shop.installationAvailable) ...[
            const SizedBox(height: 18),
            _buildServicesSection(shop),
          ],

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF059669),
                  size: 17,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sold by this local shop',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(Shop shop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer services',
            style: TextStyle(
              color: dark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          if (shop.deliveryAvailable)
            _buildServiceItem(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery available',
              charge: shop.deliveryCharge,
              iconColor: const Color(0xFF2563EB),
            ),

          if (shop.deliveryAvailable && shop.installationAvailable)
            const SizedBox(height: 9),

          if (shop.installationAvailable)
            _buildServiceItem(
              icon: Icons.handyman_outlined,
              title: 'Installation available',
              charge: shop.installationCharge,
              iconColor: const Color(0xFF8B5CF6),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required double charge,
    required Color iconColor,
  }) {
    final String chargeText = charge <= 0
        ? 'Free'
        : '₹${charge.toStringAsFixed(0)}';

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          chargeText,
          style: const TextStyle(
            color: Color(0xFF059669),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildShopAvatar(Shop shop) {
    final String imageUrl = shop.imageUrl?.trim() ?? '';

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const Icon(Icons.storefront_rounded, color: primary, size: 27)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.storefront_rounded,
                  color: primary,
                  size: 27,
                );
              },
            ),
    );
  }

  Widget _buildOpenStatus(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: secondary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
        ),
      ),
    );
  }

  Widget _buildUnavailable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: secondary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop details unavailable',
                  style: TextStyle(
                    color: dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Seller information could not be loaded for this product.',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11,
                    height: 1.35,
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
