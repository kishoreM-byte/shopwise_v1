import 'package:flutter/material.dart';

import '../../../services/travel_cost_service.dart';
import '../../../theme/design_tokens.dart';

class TravelCostCard extends StatefulWidget {
  final double? routeDistanceKm;
  final bool isRouteDistanceLoading;
  final String? routeDistanceError;
  final ValueChanged<double?>? onCostChanged;

  const TravelCostCard({
    super.key,
    this.routeDistanceKm,
    this.isRouteDistanceLoading = false,
    this.routeDistanceError,
    this.onCostChanged,
  });

  @override
  State<TravelCostCard> createState() => _TravelCostCardState();
}

class _TravelCostCardState extends State<TravelCostCard> {
  VehicleType _vehicleType = VehicleType.car;

  final TextEditingController _distanceController = TextEditingController();

  final TextEditingController _efficiencyController = TextEditingController();

  final TextEditingController _energyPriceController = TextEditingController();

  final TextEditingController _tollController = TextEditingController(
    text: '0',
  );

  TravelCostResult? _result;
  bool _usingRouteDistance = false;

  final TravelCostService _service = const TravelCostService();

  @override
  void initState() {
    super.initState();

    _applyVehicleDefaults(_vehicleType);
    _applyRouteDistance();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _calculateResult();
    });
  }

  void _applyVehicleDefaults(VehicleType type) {
    final VehicleProfile profile = TravelCostService.vehicleProfiles.firstWhere(
      (profile) => profile.type == type,
    );

    _efficiencyController.text = profile.defaultEfficiency.toString();
    _energyPriceController.text = profile.defaultEnergyPrice.toString();
  }

  @override
  void didUpdateWidget(covariant TravelCostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.routeDistanceKm != widget.routeDistanceKm ||
        oldWidget.isRouteDistanceLoading != widget.isRouteDistanceLoading ||
        oldWidget.routeDistanceError != widget.routeDistanceError) {
      _applyRouteDistance();
      _calculateResult();
    }
  }

  void _applyRouteDistance() {
    if (widget.isRouteDistanceLoading || widget.routeDistanceError != null) {
      if (_usingRouteDistance) {
        _distanceController.clear();
      }
      _usingRouteDistance = false;
      return;
    }

    final double? routeDistance = widget.routeDistanceKm;

    if (routeDistance != null && routeDistance.isFinite && routeDistance >= 0) {
      final String value = routeDistance.toStringAsFixed(2);

      if (_distanceController.text != value) {
        _distanceController.text = value;
      }

      _usingRouteDistance = true;
      return;
    }

    if (_usingRouteDistance) {
      _distanceController.clear();
    }
    _usingRouteDistance = false;
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _efficiencyController.dispose();
    _energyPriceController.dispose();
    _tollController.dispose();
    super.dispose();
  }

  void _calculateResult() {
    if (widget.isRouteDistanceLoading) {
      setState(() => _result = null);
      widget.onCostChanged?.call(null);
      return;
    }

    final double? routeDistance = widget.routeDistanceError == null
        ? widget.routeDistanceKm
        : null;
    final bool hasValidRouteDistance =
        routeDistance != null && routeDistance.isFinite && routeDistance >= 0;

    final double? distance = hasValidRouteDistance
        ? routeDistance
        : double.tryParse(_distanceController.text.trim());

    if (distance == null || !distance.isFinite || distance < 0) {
      setState(() => _result = null);
      widget.onCostChanged?.call(null);
      return;
    }

    final double efficiency =
        double.tryParse(_efficiencyController.text.trim()) ?? 1;

    final double energyPrice =
        double.tryParse(_energyPriceController.text.trim()) ?? 0;

    final double toll = double.tryParse(_tollController.text.trim()) ?? 0;

    final TravelCostResult result = _service.calculate(
      vehicleType: _vehicleType,
      distanceKm: distance,
      efficiency: efficiency,
      energyPrice: energyPrice,
      tollCost: toll,
    );

    setState(() {
      _result = result;
    });

    widget.onCostChanged?.call(result.totalCost);
  }

  String _vehicleLabel(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.car:
        return 'Car';
      case VehicleType.electricBike:
        return 'EV Bike';
      case VehicleType.electricCar:
        return 'EV Car';
    }
  }

  String _vehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return '🏍️';
      case VehicleType.car:
        return '🚗';
      case VehicleType.electricBike:
        return '⚡🏍️';
      case VehicleType.electricCar:
        return '⚡🚗';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TravelCostResult? result = _result;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ShopWiseColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ShopWiseColors.oliveSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ShopWiseColors.border),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: ShopWiseColors.olive,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Travel Cost',
                style: TextStyle(
                  color: ShopWiseColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Estimate what travelling to the shop adds to your purchase.',
            style: TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<VehicleType>(
            initialValue: _vehicleType,
            decoration: InputDecoration(
              labelText: 'Vehicle',
              prefixIcon: const Icon(Icons.electric_car_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: VehicleType.values.map((VehicleType type) {
              return DropdownMenuItem<VehicleType>(
                value: type,
                child: Text('${_vehicleIcon(type)}  ${_vehicleLabel(type)}'),
              );
            }).toList(),
            onChanged: (VehicleType? value) {
              if (value == null) return;

              setState(() {
                _vehicleType = value;
                _applyVehicleDefaults(value);
              });

              _calculateResult();
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _distanceController,
                  label: _usingRouteDistance ? 'Actual road km' : 'One-way km',
                  icon: _usingRouteDistance
                      ? Icons.route_rounded
                      : Icons.route_outlined,
                  enabled: !_usingRouteDistance,
                  onChanged: (_) => _calculateResult(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  controller: _efficiencyController,
                  label: _result?.isElectric == true
                      ? 'km / kWh'
                      : 'km / litre',
                  icon: Icons.speed_outlined,
                  onChanged: (_) => _calculateResult(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _energyPriceController,
                  label: _result?.isElectric == true ? '₹ / kWh' : '₹ / litre',
                  icon: Icons.payments_outlined,
                  onChanged: (_) => _calculateResult(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  controller: _tollController,
                  label: 'Toll ₹',
                  icon: Icons.toll_outlined,
                  onChanged: (_) => _calculateResult(),
                ),
              ),
            ],
          ),

          if (widget.isRouteDistanceLoading) ...[
            const SizedBox(height: 12),
            _buildRouteStatus(
              icon: Icons.route_outlined,
              message: 'Calculating the actual road distance…',
            ),
          ] else if (_usingRouteDistance) ...[
            const SizedBox(height: 12),
            _buildRouteStatus(
              icon: Icons.check_circle_outline_rounded,
              message:
                  'Travel cost is based on the actual drivable road distance.',
            ),
          ] else if (widget.routeDistanceError != null) ...[
            const SizedBox(height: 12),
            _buildRouteStatus(
              icon: Icons.info_outline_rounded,
              message:
                  'Using manual distance because the road route is unavailable.',
            ),
          ],

          if (result == null && !widget.isRouteDistanceLoading) ...[
            const SizedBox(height: 12),
            _buildRouteStatus(
              icon: Icons.edit_road_outlined,
              message: 'Enter a one-way distance to estimate travel cost.',
            ),
          ],

          if (result != null) ...[
            const SizedBox(height: 18),
            _buildResult(result),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteStatus({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ShopWiseColors.oliveSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ShopWiseColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: ShopWiseColors.olive),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildResult(TravelCostResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _resultRow(
            'Round-trip distance',
            '${result.roundTripDistanceKm.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 9),
          _resultRow(
            result.isElectric ? 'Energy cost' : 'Fuel cost',
            '₹${result.energyCost.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 9),
          _resultRow('Toll', '₹${result.tollCost.toStringAsFixed(0)}'),
          const Divider(height: 20),
          _resultRow(
            'Estimated travel cost',
            '₹${result.totalCost.toStringAsFixed(0)}',
            strong: true,
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool strong = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 12,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: ShopWiseColors.textPrimary,
            fontSize: strong ? 16 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
