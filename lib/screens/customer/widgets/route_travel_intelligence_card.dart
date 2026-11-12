import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

class RouteTravelIntelligenceCard extends StatelessWidget {
  final double? distanceKm;
  final int? durationMinutes;
  final int petrolStationCount;
  final int mechanicShopCount;
  final bool isLoadingPetrolStations;
  final String? petrolStationError;
  final VoidCallback? onRetry;

  const RouteTravelIntelligenceCard({
    super.key,
    required this.distanceKm,
    required this.durationMinutes,
    required this.petrolStationCount,
    this.mechanicShopCount = 0,
    this.isLoadingPetrolStations = false,
    this.petrolStationError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRoute = distanceKm != null && durationMinutes != null;

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
                  Icons.alt_route_rounded,
                  color: ShopWiseColors.olive,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Route Intelligence',
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
            'Useful trip information based on your actual driving route.',
            style: TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (!hasRoute)
            _status(
              icon: Icons.location_searching_rounded,
              text: 'Get your route to see travel intelligence.',
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _metric(
                    icon: Icons.straighten_rounded,
                    label: 'Road distance',
                    value: '${distanceKm!.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metric(
                    icon: Icons.schedule_rounded,
                    label: 'Drive time',
                    value: _durationLabel(durationMinutes!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoadingPetrolStations)
              _status(
                icon: Icons.place_outlined,
                text:
                    'Finding petrol bunks and mechanic shops along your route…',
              )
            else if (petrolStationError != null)
              _petrolStationSection()
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _petrolStationSection()),
                  const SizedBox(width: 10),
                  Expanded(child: _mechanicShopSection()),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _petrolStationSection() {
    if (isLoadingPetrolStations) {
      return _status(
        icon: Icons.local_gas_station_outlined,
        text: 'Finding petrol stations along your route…',
      );
    }

    if (petrolStationError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB45309),
              size: 19,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Petrol station information is temporarily unavailable.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 19,
                color: const Color(0xFFB45309),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopWiseColors.oliveSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ShopWiseColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: ShopWiseColors.emeraldDeep,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petrolStationCount == 1
                      ? '1 petrol station'
                      : '$petrolStationCount petrol stations',
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Found within 750 m of your driving route.',
                  style: TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 10,
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

  Widget _mechanicShopSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.car_repair_rounded,
              color: ShopWiseColors.olive,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mechanicShopCount == 1
                      ? '1 mechanic shop'
                      : '$mechanicShopCount mechanic shops',
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Found within 750 m of your driving route.',
                  style: TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 10,
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

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: ShopWiseColors.olive, size: 18),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: ShopWiseColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _status({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: ShopWiseColors.surface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: ShopWiseColors.olive),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;

    if (remaining == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remaining}m';
  }
}
