import 'package:flutter/material.dart';

import '../../services/role_service.dart';
import '../../theme/design_tokens.dart';
import '../customer/customer_home_screen.dart';
import '../shop_owner/shop_owner_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _loadingRole;

  Future<void> _selectRole(String role) async {
    if (_loadingRole != null) return;

    setState(() {
      _loadingRole = role;
    });

    try {
      await RoleService().createUserProfile(role: role);

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        _loadingRole = null;
      });

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
          onPressed: _loadingRole == null
              ? () => Navigator.maybePop(context)
              : null,
          icon: const Icon(Icons.arrow_back_rounded),
          color: ShopWiseColors.textPrimary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            ShopWiseRadius.xLarge,
            10,
            ShopWiseRadius.xLarge,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.86, end: 1),
                duration: ShopWiseMotion.smooth,
                curve: ShopWiseMotion.entranceCurve,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
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
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: ShopWiseMotion.page,
                curve: ShopWiseMotion.entranceCurve,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'How will you use\nShopWise?',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    height: 1.08,
                    letterSpacing: -1.1,
                  ),
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
              _RoleCard(
                icon: Icons.shopping_bag_rounded,
                title: 'I’m a Customer',
                subtitle:
                    'Compare products, discover better prices, '
                    'and make smarter buying decisions.',
                accent: ShopWiseColors.emerald,
                actionLabel: 'Continue as Customer',
                isLoading: _loadingRole == 'customer',
                isDisabled: _loadingRole != null &&
                    _loadingRole != 'customer',
                onTap: () => _selectRole('customer'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: 'I’m a Shop Owner',
                subtitle:
                    'Manage your products, prices, offers, '
                    'stock and customer enquiries.',
                accent: ShopWiseColors.compare,
                actionLabel: 'Continue as Shop Owner',
                isLoading: _loadingRole == 'shop_owner',
                isDisabled: _loadingRole != null &&
                    _loadingRole != 'shop_owner',
                onTap: () => _selectRole('shop_owner'),
              ),
              const SizedBox(height: 28),
              Center(
                child: AnimatedSwitcher(
                  duration: ShopWiseMotion.fast,
                  child: _loadingRole == null
                      ? Row(
                          key: const ValueKey('secure'),
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
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: ShopWiseColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('saving'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: ShopWiseColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Setting up your ShopWise experience...',
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: ShopWiseColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actionLabel,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String actionLabel;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isDisabled || widget.isLoading) return;

    if (mounted) {
      setState(() {
        _pressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = widget.isDisabled ? 0.48 : 1.0;

    return AnimatedOpacity(
      duration: ShopWiseMotion.micro,
      opacity: opacity,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: ShopWiseMotion.micro,
        curve: ShopWiseMotion.standardCurve,
        child: Material(
          color: ShopWiseColors.surface,
          borderRadius: BorderRadius.circular(
            ShopWiseRadius.xLarge,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(
              ShopWiseRadius.xLarge,
            ),
            onTap: widget.isDisabled || widget.isLoading
                ? null
                : widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            splashColor: widget.accent.withValues(alpha: 0.06),
            highlightColor: widget.accent.withValues(alpha: 0.025),
            child: AnimatedContainer(
              duration: ShopWiseMotion.standard,
              curve: ShopWiseMotion.standardCurve,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ShopWiseRadius.xLarge,
                ),
                border: Border.all(
                  color: widget.isLoading
                      ? widget.accent.withValues(alpha: 0.35)
                      : ShopWiseColors.border,
                  width: widget.isLoading ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(
                      alpha: widget.isLoading ? 0.08 : 0.035,
                    ),
                    blurRadius: widget.isLoading ? 30 : 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: ShopWiseMotion.standard,
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(
                            alpha: widget.isLoading ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            ShopWiseRadius.medium,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.accent,
                          size: 27,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: ShopWiseMotion.fast,
                        child: widget.isLoading
                            ? SizedBox(
                                key: const ValueKey('loading'),
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: widget.accent,
                                ),
                              )
                            : Container(
                                key: const ValueKey('arrow'),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: ShopWiseColors.surfaceSoft,
                                  borderRadius:
                                      BorderRadius.circular(
                                    ShopWiseRadius.small,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: ShopWiseColors.textSecondary,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 20,
                      letterSpacing: -0.35,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ShopWiseColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: ShopWiseMotion.fast,
                    child: widget.isLoading
                        ? Text(
                            'SETTING UP...',
                            key: const ValueKey('setting-up'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.accent,
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Text(
                            widget.actionLabel.toUpperCase(),
                            key: const ValueKey('action'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.accent,
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
