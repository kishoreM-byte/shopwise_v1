import 'package:flutter/material.dart';

import '../../../services/travel_cost_service.dart';

class TravelCostCard extends StatefulWidget {
  final double? routeDistanceKm;
  final bool isRouteDistanceLoading;
  final String? routeDistanceError;
  final ValueChanged<double>? onCostChanged;

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

  final TextEditingController _distanceController = TextEditingController(
    text: '10',
  );

  final TextEditingController _efficiencyController = TextEditingController(
    text: '15',
  );

  final TextEditingController _energyPriceController = TextEditingController(
    text: '100',
  );

  final TextEditingController _tollController = TextEditingController(
    text: '0',
  );

  TravelCostResult? _result;
  bool _usingRouteDistance = false;

  final TravelCostService _service = const TravelCostService();

  @override
  void initState() {
    super.initState();

    _applyRouteDistance();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _calculateResult();
    });
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
    final double? routeDistance = widget.routeDistanceKm;

    if (routeDistance != null && routeDistance > 0) {
      final String value = routeDistance.toStringAsFixed(2);

      if (_distanceController.text != value) {
        _distanceController.text = value;
      }

      _usingRouteDistance = true;
      return;
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
    final double distance =
        widget.routeDistanceKm ??
        (double.tryParse(_distanceController.text.trim()) ?? 0);

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                color: Color(0xFF2563EB),
                size: 21,
              ),
              SizedBox(width: 9),
              Text(
                'Travel Cost',
                style: TextStyle(
                  color: Color(0xFF0F172A),
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
              color: Color(0xFF64748B),
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

                if (value == VehicleType.bike) {
                  _efficiencyController.text = '40';
                  _energyPriceController.text = '100';
                } else if (value == VehicleType.car) {
                  _efficiencyController.text = '15';
                  _energyPriceController.text = '100';
                } else if (value == VehicleType.electricBike) {
                  _efficiencyController.text = '35';
                  _energyPriceController.text = '8';
                } else {
                  _efficiencyController.text = '6';
                  _energyPriceController.text = '8';
                }
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
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF059669)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 11,
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
        color: const Color(0xFFF8FAFC),
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
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: strong ? 16 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
