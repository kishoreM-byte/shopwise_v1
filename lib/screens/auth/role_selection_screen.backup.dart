import 'package:flutter/material.dart';

import '../../services/role_service.dart';
import '../customer/customer_home_screen.dart';
import '../shop_owner/shop_owner_dashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    try {
      // Save user profile + selected role to Firestore.
      await RoleService().createUserProfile(role: role);

      if (!context.mounted) return;

      // Navigate according to selected role.
      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        );
      } else if (role == 'shop_owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ShopOwnerDashboard()),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roleCard(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'Customer',
              subtitle: 'Compare products and find the best deal',
              role: 'customer',
            ),
            const SizedBox(height: 16),
            _roleCard(
              context,
              icon: Icons.storefront_outlined,
              title: 'Shop Owner',
              subtitle: 'Manage your products and offers',
              role: 'shop_owner',
            ),
          ],
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
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
          child: Icon(icon, color: const Color(0xFF10B981), size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        onTap: () => _selectRole(context, role),
      ),
    );
  }
}
