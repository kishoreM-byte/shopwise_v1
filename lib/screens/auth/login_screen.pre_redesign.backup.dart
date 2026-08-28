import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isLoading = false;
  bool _googleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();

      _googleInitialized = true;

      debugPrint('ShopWise: Google Sign-In initialized successfully.');
    } catch (e) {
      debugPrint('ShopWise: Google Sign-In initialization failed: $e');
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('ShopWise: Starting Google Sign-In...');

      if (!_googleInitialized) {
        await _googleSignIn.initialize();
        _googleInitialized = true;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      debugPrint('ShopWise: Google account selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase returned no authenticated user.');
      }

      debugPrint('ShopWise: Firebase authentication successful.');

      debugPrint('ShopWise: UID: ${user.uid}');

      await _handleUserRole(user);
    } on GoogleSignInException catch (e) {
      debugPrint('ShopWise: Google Sign-In Error');

      debugPrint('Code: ${e.code}');

      debugPrint('Description: ${e.description}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.description ?? 'Google Sign-In failed.')),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('ShopWise: Firebase Authentication Error');

      debugPrint('Code: ${e.code}');

      debugPrint('Message: ${e.message}');

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
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ShopWiseRadius.xLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------------------------------------------------
                // Logo
                // ------------------------------------------------
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: ShopWiseColors.emerald,
                    borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: ShopWiseColors.surface,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // Title
                // ------------------------------------------------
                Text(
                  'ShopWise',
                  style: Theme.of(context).textTheme.displayLarge,
                ),

                const SizedBox(height: 8),

                Text(
                  'Compare smarter. Buy better.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 48),

                // ------------------------------------------------
                // Login Card
                // ------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ShopWiseRadius.xLarge),
                  decoration: BoxDecoration(
                    color: ShopWiseColors.surface,
                    borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to continue to ShopWise',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------
                      // Google Sign-In
                      // ------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _continueWithGoogle,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            _isLoading
                                ? 'Signing in...'
                                : 'Continue with Google',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ShopWiseColors.textPrimary,
                            side: BorderSide(color: ShopWiseColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'By continuing, you agree to use ShopWise '
                  'responsibly.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
