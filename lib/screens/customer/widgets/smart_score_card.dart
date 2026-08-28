import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../models/shop.dart';
import '../../../services/smart_score_service.dart';
import '../../../services/delivery_cost_service.dart';
import '../../../services/installation_cost_service.dart';
import 'travel_cost_card.dart';

class SmartScoreCard extends StatefulWidget {
  final Product product;
  final Shop? shop;
  final double? routeDistanceKm;
  final bool isRouteDistanceLoading;
  final String? routeDistanceError;

  const SmartScoreCard({
    super.key,
    required this.product,
    this.shop,
    this.routeDistanceKm,
    this.isRouteDistanceLoading = false,
    this.routeDistanceError,
  });

  @override
  State<SmartScoreCard> createState() => _SmartScoreCardState();
}

class _SmartScoreCardState extends State<SmartScoreCard> {
  double _travelCost = 0;
  double _deliveryCost = 0;
  double _installationCost = 0;

  DeliveryType _deliveryType = DeliveryType.selfPickup;
  InstallationType _installationType = InstallationType.notRequired;

  static const Color primary = Color(0xFF10B981);
  static const Color dark = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF64748B);

  SmartScoreResult get _result {
    const SmartScoreService service = SmartScoreService();

    return service.calculate(
      widget.product,
      travelCost: _travelCost,
      deliveryCost: _deliveryCost,
      installationCost: _installationCost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SmartScoreResult result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreCard(result),

        const SizedBox(height: 18),

        TravelCostCard(
          routeDistanceKm: widget.routeDistanceKm,
          isRouteDistanceLoading: widget.isRouteDistanceLoading,
          routeDistanceError: widget.routeDistanceError,
          onCostChanged: (cost) {
            setState(() {
              _travelCost = cost;
            });
          },
        ),

        const SizedBox(height: 18),

        _buildDeliveryCard(),

        const SizedBox(height: 18),

        _buildInstallationCard(),
      ],
    );
  }

  Widget _buildDeliveryCard() {
    final Shop? shop = widget.shop;

    if (shop == null) {
      return _buildServiceUnavailableCard(
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF2563EB),
        title: 'Delivery',
        message: 'Shop delivery information is unavailable.',
      );
    }

    if (!shop.deliveryAvailable) {
      return _buildServiceUnavailableCard(
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF2563EB),
        title: 'Delivery',
        message: 'Delivery is not available from this shop.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF2563EB),
                size: 21,
              ),
              SizedBox(width: 9),
              Text(
                'Delivery',
                style: TextStyle(
                  color: dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<DeliveryType>(
            initialValue: _deliveryType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: DeliveryType.selfPickup,
                child: Text('Self pickup'),
              ),
              DropdownMenuItem(
                value: DeliveryType.shopDelivery,
                child: Text(
                  'Shop delivery — ₹${shop.deliveryCharge.toStringAsFixed(0)}',
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              final result = DeliveryCostService().calculate(
                type: value,
                shopDeliveryCost: shop.deliveryCharge,
              );

              setState(() {
                _deliveryType = value;
                _deliveryCost = result.cost;
              });
            },
          ),

          const SizedBox(height: 9),

          Text(
            _deliveryCost > 0
                ? '₹${_deliveryCost.toStringAsFixed(0)} will be included in True Cost.'
                : 'No delivery charge added.',
            style: const TextStyle(
              color: secondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceUnavailableCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(width: 9),
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
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationCard() {
    final Shop? shop = widget.shop;

    if (shop == null) {
      return _buildServiceUnavailableCard(
        icon: Icons.handyman_outlined,
        iconColor: const Color(0xFF8B5CF6),
        title: 'Installation',
        message: 'Shop installation information is unavailable.',
      );
    }

    if (!shop.installationAvailable) {
      return _buildServiceUnavailableCard(
        icon: Icons.handyman_outlined,
        iconColor: const Color(0xFF8B5CF6),
        title: 'Installation',
        message: 'Installation is not available from this shop.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handyman_outlined, color: Color(0xFF8B5CF6), size: 21),
              SizedBox(width: 9),
              Text(
                'Installation',
                style: TextStyle(
                  color: dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<InstallationType>(
            initialValue: _installationType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: InstallationType.notRequired,
                child: Text('Not required'),
              ),
              DropdownMenuItem(
                value: InstallationType.shopInstallation,
                child: Text(
                  'Shop installation — ₹${shop.installationCharge.toStringAsFixed(0)}',
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              final result = InstallationCostService().calculate(
                type: value,
                shopInstallationCost: shop.installationCharge,
              );

              setState(() {
                _installationType = value;
                _installationCost = result.cost;
              });
            },
          ),

          const SizedBox(height: 9),

          Text(
            _installationCost > 0
                ? '₹${_installationCost.toStringAsFixed(0)} will be included in True Cost.'
                : 'No installation charge added.',
            style: const TextStyle(
              color: secondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(SmartScoreResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildScore(result),
          const SizedBox(height: 20),
          _buildBreakdown(result),
          const SizedBox(height: 20),
          _buildTrueCost(result),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: primary, size: 23),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Score',
                style: TextStyle(
                  color: dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Understand the real value before buying',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScore(SmartScoreResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.10), const Color(0xFFF0FDFA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: result.score / 100,
                    strokeWidth: 7,
                    backgroundColor: Colors.white,
                    color: primary,
                  ),
                ),
                Text(
                  '${result.score.round()}',
                  style: const TextStyle(
                    color: dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.scoreLabel,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  result.scoreDescription,
                  style: const TextStyle(
                    color: secondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(SmartScoreResult result) {
    return Column(
      children: [
        _buildScoreRow(Icons.payments_outlined, 'Value', result.valueScore),
        const SizedBox(height: 12),
        _buildScoreRow(
          Icons.star_outline_rounded,
          'Quality',
          result.qualityScore,
        ),
        const SizedBox(height: 12),
        _buildScoreRow(
          Icons.inventory_2_outlined,
          'Availability',
          result.availabilityScore,
        ),
        const SizedBox(height: 12),
        _buildScoreRow(Icons.local_offer_outlined, 'Offers', result.offerScore),
      ],
    );
  }

  Widget _buildScoreRow(IconData icon, String label, double score) {
    return Row(
      children: [
        Icon(icon, size: 18, color: secondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              color: primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${score.round()}',
          style: const TextStyle(
            color: secondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTrueCost(SmartScoreResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: Color(0xFF2563EB),
                size: 21,
              ),
              SizedBox(width: 9),
              Text(
                'True Cost',
                style: TextStyle(
                  color: dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Icon(Icons.info_outline_rounded, color: secondary, size: 17),
            ],
          ),

          const SizedBox(height: 14),

          _buildCostRow('Product price', result.productPrice),

          const SizedBox(height: 9),

          _buildCostRow('Travel', result.travelCost),

          const SizedBox(height: 9),

          _buildCostRow('Delivery', result.deliveryCost),

          const SizedBox(height: 9),

          _buildCostRow('Installation', result.installationCost),

          const SizedBox(height: 13),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          const SizedBox(height: 13),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'You actually spend',
                  style: TextStyle(
                    color: dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '₹${result.trueCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: dark,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          if (result.additionalCost > 0) ...[
            const SizedBox(height: 7),
            Text(
              '₹${result.additionalCost.toStringAsFixed(0)} added to the product price',
              style: const TextStyle(
                color: secondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const SizedBox(height: 7),
            const Text(
              'Travel, delivery and installation are not added yet.',
              style: TextStyle(
                color: secondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double amount) {
    final bool hasCost = amount > 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          hasCost ? '₹${amount.toStringAsFixed(0)}' : 'Not added',
          style: TextStyle(
            color: hasCost ? dark : secondary,
            fontSize: 12,
            fontWeight: hasCost ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
