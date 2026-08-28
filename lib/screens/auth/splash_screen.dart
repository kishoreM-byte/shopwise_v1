import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/role_service.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';
import '../customer/customer_home_screen.dart';
import '../shop_owner/shop_owner_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;

    // User is not logged in.
    // Role selection requires an authenticated Firebase user.
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    try {
      final String? role =
          await RoleService().getCurrentUserRole();

      if (!mounted) return;

      // No role selected yet.
      if (role == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSelectionScreen(),
          ),
        );
        return;
      }

      // Existing customer.
      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerHomeScreen(),
          ),
        );
        return;
      }

      // Existing shop owner.
      if (role == 'shop_owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ShopOwnerDashboard(),
          ),
        );
        return;
      }

      // Unknown role.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load user role: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      ),
    );
  }
}