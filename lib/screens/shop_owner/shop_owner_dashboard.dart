import 'package:flutter/material.dart';

import '../../models/shop.dart';
import '../../services/shop_service.dart';
import '../../theme/design_tokens.dart';
import '../profile/profile_screen.dart';
import 'add_product_screen.dart';
import 'products_screen.dart';
import 'shop_setup_screen.dart';
import 'shop_analytics_screen.dart';
import 'enquiries_screen.dart';
import 'orders_screen.dart';

class ShopOwnerDashboard extends StatefulWidget {
  const ShopOwnerDashboard({super.key, this.loadShop});

  final Future<Shop?> Function()? loadShop;

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  static const Color primaryDark = ShopWiseColors.emeraldDeep;
  static const Color background = ShopWiseColors.background;
  static const Color textPrimary = ShopWiseColors.textPrimary;
  static const Color textSecondary = ShopWiseColors.textSecondary;
  static const Color border = ShopWiseColors.border;

  late Future<Shop?> _shopFuture;

  @override
  void initState() {
    super.initState();
    _shopFuture = _loadShop();
  }

  Future<Shop?> _loadShop() {
    return widget.loadShop?.call() ?? ShopService().getMyShop();
  }

  void _retryShopLoad() {
    setState(() {
      _shopFuture = _loadShop();
    });
  }

  Future<void> _openShopSetup(BuildContext context, {Shop? shop}) async {
    final Shop? currentShop = shop ?? await ShopService().getMyShop();
    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopSetupScreen(shop: currentShop)),
    );

    if (mounted) _retryShopLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildShopCard(context),
                  const SizedBox(height: 26),
                  _buildSectionTitle(
                    'Quick actions',
                    'Manage your shop faster',
                  ),
                  const SizedBox(height: 14),
                  _buildQuickActions(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    'Shop management',
                    'Keep your store up to date',
                  ),
                  const SizedBox(height: 14),
                  _buildManagementCard(
                    context,
                    icon: Icons.inventory_2_rounded,
                    accent: ShopWiseColors.olive,
                    title: 'Manage Products',
                    subtitle: 'View, edit and manage your products',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    icon: Icons.storefront_rounded,
                    accent: ShopWiseColors.enquiries,
                    title: 'Shop Setup',
                    subtitle: 'Update your shop information',
                    onTap: () => _openShopSetup(context),
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    icon: Icons.analytics_rounded,
                    accent: ShopWiseColors.search,
                    title: 'Analytics',
                    subtitle: 'Track your shop performance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShopAnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    icon: Icons.shopping_bag_rounded,
                    accent: ShopWiseColors.emerald,
                    title: 'Orders',
                    subtitle: 'Review and manage customer orders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShopOwnerOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    icon: Icons.mark_email_unread_rounded,
                    accent: ShopWiseColors.wishlist,
                    title: 'Customer Enquiries',
                    subtitle: 'View customer product enquiries',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EnquiriesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  _buildTipCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ShopWise',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good day, Shop Owner 👋',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Profile',
            child: Material(
              color: ShopWiseColors.surface,
              elevation: ShopWiseElevation.subtle / 2,
              shadowColor: textPrimary.withValues(alpha: 0.06),
              shape: const CircleBorder(side: BorderSide(color: border)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.person_rounded,
                    color: primaryDark,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(BuildContext context) {
    return FutureBuilder(
      future: _shopFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShopCard();
        }

        if (snapshot.hasError) {
          return _buildShopErrorCard();
        }

        final shop = snapshot.data;

        if (shop == null) {
          return _buildEmptyShopCard(context);
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ShopWiseColors.surfaceSoft,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ShopWiseColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ShopWiseColors.oliveSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: ShopWiseColors.textPrimary,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: ShopWiseColors.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: shop.isOpen
                                ? ShopWiseColors.olive
                                : ShopWiseColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: ShopWiseColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                shop.name.isEmpty ? 'Your Shop' : shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ShopWiseColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                shop.category,
                style: const TextStyle(
                  color: ShopWiseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: ShopWiseColors.border),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildShopStat(
                    Icons.star_rounded,
                    shop.rating.toStringAsFixed(1),
                    'Rating',
                  ),
                  const SizedBox(width: 28),
                  _buildShopStat(
                    Icons.reviews_rounded,
                    '${shop.reviewCount}',
                    'Reviews',
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openShopSetup(context, shop: shop),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Row(
                        children: [
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: ShopWiseColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: ShopWiseColors.textPrimary,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: ShopWiseColors.textPrimary, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: ShopWiseColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyShopCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: ShopWiseColors.olive,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Set up your shop',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add your shop details before adding products.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopSetupScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ShopWiseColors.olive,
                foregroundColor: ShopWiseColors.surface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Set Up Shop',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShopCard() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: ShopWiseColors.olive,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildShopErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: ShopWiseColors.olive,
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'Shop details unavailable',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _retryShopLoad,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.inventory_2_rounded,
            accent: ShopWiseColors.olive,
            title: 'Products',
            subtitle: 'Manage',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.add_rounded,
            accent: ShopWiseColors.enquiries,
            title: 'Add Product',
            subtitle: 'Create new',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ShopWiseColors.surface,
      elevation: ShopWiseElevation.subtle / 2,
      shadowColor: textPrimary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        side: const BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ShopWiseColors.surface,
      elevation: ShopWiseElevation.subtle / 2,
      shadowColor: textPrimary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        side: const BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: ShopWiseColors.border,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: ShopWiseColors.olive,
            size: 26,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Keep your product prices and stock updated to help customers make better buying decisions.',
              style: TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
