import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/role_service.dart';
import '../../theme/design_tokens.dart';
import 'role_selection_screen.dart';
import '../customer/customer_home_screen.dart';
import '../shop_owner/shop_owner_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: ShopWiseMotion.page,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: ShopWiseMotion.entranceCurve,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: ShopWiseMotion.entranceCurve,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: ShopWiseMotion.entranceCurve,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('ShopWise: Starting Google Sign-In...');

      final UserCredential? userCredential = await _authService
          .signInWithGoogle();

      if (userCredential == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In was not completed.')),
        );

        return;
      }

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase returned no authenticated user.');
      }

      debugPrint(
        'ShopWise: Firebase authentication successful. '
        'UID: ${user.uid}',
      );

      await _handleUserRole(user);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'ShopWise: Firebase Authentication Error\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Firebase authentication failed.')),
      );
    } catch (e) {
      debugPrint('ShopWise: Unexpected login error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUserRole(User user) async {
    final String? role = await RoleService().getCurrentUserRole();

    if (!mounted) return;

    // ------------------------------------------------------------
    // Existing user with CUSTOMER role
    // ------------------------------------------------------------

    if (role == 'customer') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (route) => false,
      );

      return;
    }

    // ------------------------------------------------------------
    // Existing user with SHOP OWNER role
    // ------------------------------------------------------------

    if (role == 'shop_owner') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ShopOwnerDashboard()),
        (route) => false,
      );

      return;
    }

    // ------------------------------------------------------------
    // New user / no role selected
    // ------------------------------------------------------------

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ShopWiseColors.emerald.withValues(alpha: 0.075),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ShopWiseColors.search.withValues(alpha: 0.035),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ShopWiseRadius.xLarge,
                  28,
                  ShopWiseRadius.xLarge,
                  24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ShopWiseColors.emerald,
                                  ShopWiseColors.emeraldDeep,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                ShopWiseRadius.large,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ShopWiseColors.emerald.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: ShopWiseColors.surface,
                              size: 36,
                            ),
                          ),

                          const SizedBox(height: 22),

                          Text(
                            'ShopWise',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 30,
                              letterSpacing: -1.1,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            'Compare smarter. Buy better.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ShopWiseColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 34),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            decoration: BoxDecoration(
                              color: ShopWiseColors.surface,
                              borderRadius: BorderRadius.circular(
                                ShopWiseRadius.xLarge,
                              ),
                              border: Border.all(color: ShopWiseColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: ShopWiseColors.textPrimary.withValues(
                                    alpha: 0.045,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: theme.textTheme.headlineLarge
                                      ?.copyWith(
                                        fontSize: 22,
                                        letterSpacing: -0.5,
                                      ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Sign in to continue to ShopWise',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: ShopWiseColors.textSecondary,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _continueWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          ShopWiseColors.textPrimary,
                                      backgroundColor: ShopWiseColors.surface,
                                      side: const BorderSide(
                                        color: ShopWiseColors.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          ShopWiseRadius.medium,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: ShopWiseMotion.fast,
                                      child: _isLoading
                                          ? const SizedBox(
                                              key: ValueKey('loading'),
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : Row(
                                              key: const ValueKey('google'),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: ShopWiseColors
                                                            .emeraldSoft,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.g_mobiledata_rounded,
                                                    color: ShopWiseColors
                                                        .emeraldDeep,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Continue with Google',
                                                  style: theme
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        color: ShopWiseColors
                                                            .textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: ShopWiseColors.border,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'SECURE SIGN-IN',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: ShopWiseColors.textMuted,
                                              fontSize: 9,
                                              letterSpacing: 1.1,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: ShopWiseColors.border,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: ShopWiseColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Your account is protected by Firebase Authentication',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: ShopWiseColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
