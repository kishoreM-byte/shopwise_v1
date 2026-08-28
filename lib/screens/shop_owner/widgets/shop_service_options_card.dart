import 'package:flutter/material.dart';

class ShopServiceOptionsCard extends StatelessWidget {
  final bool deliveryAvailable;
  final double deliveryCharge;

  final bool installationAvailable;
  final double installationCharge;

  final ValueChanged<bool> onDeliveryChanged;
  final ValueChanged<double> onDeliveryChargeChanged;

  final ValueChanged<bool> onInstallationChanged;
  final ValueChanged<double> onInstallationChargeChanged;

  const ShopServiceOptionsCard({
    super.key,
    required this.deliveryAvailable,
    required this.deliveryCharge,
    required this.installationAvailable,
    required this.installationCharge,
    required this.onDeliveryChanged,
    required this.onDeliveryChargeChanged,
    required this.onInstallationChanged,
    required this.onInstallationChargeChanged,
  });

  static const Color dark = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color green = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF2563EB),
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Customer services',
                  style: TextStyle(
                    color: dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Tell customers which services your shop provides.',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          _buildServiceRow(
            icon: Icons.local_shipping_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Shop delivery',
            subtitle: deliveryAvailable
                ? 'Customers can request delivery'
                : 'Delivery is not available',
            value: deliveryAvailable,
            onChanged: onDeliveryChanged,
          ),

          if (deliveryAvailable) ...[
            const SizedBox(height: 12),
            _buildChargeField(
              label: 'Delivery charge',
              value: deliveryCharge,
              icon: Icons.currency_rupee_rounded,
              onChanged: onDeliveryChargeChanged,
            ),
          ],

          const SizedBox(height: 20),

          const Divider(height: 1, color: border),

          const SizedBox(height: 20),

          _buildServiceRow(
            icon: Icons.handyman_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Installation',
            subtitle: installationAvailable
                ? 'Customers can request installation'
                : 'Installation is not available',
            value: installationAvailable,
            onChanged: onInstallationChanged,
          ),

          if (installationAvailable) ...[
            const SizedBox(height: 12),
            _buildChargeField(
              label: 'Installation charge',
              value: installationCharge,
              icon: Icons.currency_rupee_rounded,
              onChanged: onInstallationChargeChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        Switch(
          value: value,
          activeThumbColor: green,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChargeField({
    required String label,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return TextFormField(
      initialValue: value > 0 ? value.toStringAsFixed(0) : '',
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: (text) {
        final double parsed = double.tryParse(text.trim()) ?? 0;
        onChanged(parsed < 0 ? 0 : parsed);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter amount',
        prefixIcon: Icon(icon, color: secondary, size: 19),
        prefixText: '₹ ',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: green,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
