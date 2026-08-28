import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/role_service.dart';
import '../auth/login_screen.dart';
import '../customer/customer_home_screen.dart';
import '../shop_owner/shop_owner_dashboard.dart';
import '../shop_owner/shop_setup_screen.dart';
import '../../services/shop_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  Future<void> _switchRole(BuildContext context, String currentRole) async {
    final String newRole = currentRole == 'customer'
        ? 'shop_owner'
        : 'customer';

    final String newRoleName = newRole == 'customer'
        ? 'Customer'
        : 'Shop Owner';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Switch Role?'),
          content: Text(
            'Are you sure you want to switch to $newRoleName mode?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Switch'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await RoleService().saveRole(newRole);

      if (!context.mounted) return;

      if (newRole == 'customer') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ShopOwnerDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to switch role: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: RoleService().getCurrentUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            );
          }

          final String role = snapshot.data ?? 'customer';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile image
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF10B981),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, color: Colors.white, size: 48)
                      : null,
                ),

                const SizedBox(height: 16),

                Text(
                  user?.displayName ?? 'ShopWise User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 28),

                // Current role
                _buildInfoCard(
                  icon: Icons.badge_outlined,
                  title: 'Current Role',
                  value: role == 'shop_owner' ? 'Shop Owner' : 'Customer',
                ),

                const SizedBox(height: 12),

                // Switch role
                _buildMenuCard(
                  icon: Icons.swap_horiz,
                  title: 'Switch Role',
                  subtitle: role == 'shop_owner'
                      ? 'Switch to Customer mode'
                      : 'Switch to Shop Owner mode',
                  onTap: () {
                    _switchRole(context, role);
                  },
                ),

                const SizedBox(height: 12),

                if (role == 'shop_owner') ...[
                  _buildMenuCard(
                    icon: Icons.storefront_outlined,
                    title: 'Shop Setup',
                    subtitle: 'Create or update your shop details',
                    onTap: () async {
                      final shop = await ShopService().getMyShop();

                      if (!context.mounted) return;

                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopSetupScreen(shop: shop),
                        ),
                      );

                      if (updated == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shop details updated'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Logout
                _buildMenuCard(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out from this account',
                  iconColor: Colors.red,
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout from ShopWise?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _logout(context);
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.badge_outlined, color: Color(0xFF10B981)),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF10B981),
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
