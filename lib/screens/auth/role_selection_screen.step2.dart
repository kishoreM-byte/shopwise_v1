import 'package:flutter/material.dart';

import '../../services/role_service.dart';
import '../../theme/design_tokens.dart';
import '../customer/customer_home_screen.dart';
import '../shop_owner/shop_owner_dashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    try {
      await RoleService().createUserProfile(role: role);

      if (!context.mounted) return;

      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerHomeScreen(),
          ),
        );
      } else if (role == 'shop_owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ShopOwnerDashboard(),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save role: ${e.toString()}'),
          duration: const Duration(seconds: 8),
        ),
      );

      debugPrint('ROLE SAVE ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: ShopWiseColors.textPrimary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ShopWiseRadius.xLarge,
            10,
            ShopWiseRadius.xLarge,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: ShopWiseColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(
                    ShopWiseRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: ShopWiseColors.emeraldDeep,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'How will you use\nShopWise?',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  height: 1.08,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose the experience that fits you. '
                'You can start exploring in seconds.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ShopWiseColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _roleCard(
                context,
                icon: Icons.shopping_bag_rounded,
                title: 'I’m a Customer',
                subtitle:
                    'Compare products, discover better prices, '
                    'and make smarter buying decisions.',
                role: 'customer',
                accent: ShopWiseColors.emerald,
                actionLabel: 'Continue as Customer',
              ),
              const SizedBox(height: 16),
              _roleCard(
                context,
                icon: Icons.storefront_rounded,
                title: 'I’m a Shop Owner',
                subtitle:
                    'Manage your products, prices, offers, '
                    'stock and customer enquiries.',
                role: 'shop_owner',
                accent: ShopWiseColors.compare,
                actionLabel: 'Continue as Shop Owner',
              ),
              const SizedBox(height: 28),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: ShopWiseColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Your choice is saved securely',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ShopWiseColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String role,
    required Color accent,
    required String actionLabel,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(
        ShopWiseRadius.xLarge,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ShopWiseRadius.xLarge,
        ),
        onTap: () => _selectRole(context, role),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ShopWiseRadius.xLarge,
            ),
            border: Border.all(
              color: ShopWiseColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: ShopWiseColors.textPrimary.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        ShopWiseRadius.medium,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: 27,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ShopWiseColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(
                        ShopWiseRadius.small,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: ShopWiseColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ShopWiseColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                actionLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.0,
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
