enum VehicleType {
  bike,
  car,
  electricBike,
  electricCar,
}

class TravelCostResult {
  final VehicleType vehicleType;
  final double oneWayDistanceKm;
  final double distanceKm;
  final double efficiency;
  final double energyPrice;
  final double energyRequired;
  final double energyCost;
  final double tollCost;

  const TravelCostResult({
    required this.vehicleType,
    required this.oneWayDistanceKm,
    required this.distanceKm,
    required this.efficiency,
    required this.energyPrice,
    required this.energyRequired,
    required this.energyCost,
    required this.tollCost,
  });

  double get totalCost => energyCost + tollCost;

  double get roundTripDistanceKm => distanceKm;

  bool get isElectric =>
      vehicleType == VehicleType.electricBike ||
      vehicleType == VehicleType.electricCar;
}

class VehicleProfile {
  final VehicleType type;
  final String name;
  final String shortName;
  final String energyUnit;
  final double defaultEfficiency;
  final double defaultEnergyPrice;

  const VehicleProfile({
    required this.type,
    required this.name,
    required this.shortName,
    required this.energyUnit,
    required this.defaultEfficiency,
    required this.defaultEnergyPrice,
  });

  bool get isElectric =>
      type == VehicleType.electricBike ||
      type == VehicleType.electricCar;
}

class TravelCostService {
  const TravelCostService();

  static const List<VehicleProfile> vehicleProfiles = [
    VehicleProfile(
      type: VehicleType.bike,
      name: 'Petrol Bike',
      shortName: 'Bike',
      energyUnit: 'L',
      defaultEfficiency: 45,
      defaultEnergyPrice: 105,
    ),
    VehicleProfile(
      type: VehicleType.car,
      name: 'Petrol Car',
      shortName: 'Car',
      energyUnit: 'L',
      defaultEfficiency: 15,
      defaultEnergyPrice: 105,
    ),
    VehicleProfile(
      type: VehicleType.electricBike,
      name: 'Electric Bike',
      shortName: 'E-Bike',
      energyUnit: 'kWh',
      defaultEfficiency: 35,
      defaultEnergyPrice: 10,
    ),
    VehicleProfile(
      type: VehicleType.electricCar,
      name: 'Electric Car',
      shortName: 'E-Car',
      energyUnit: 'kWh',
      defaultEfficiency: 6,
      defaultEnergyPrice: 10,
    ),
  ];

  TravelCostResult calculate({
    required VehicleType vehicleType,
    required double distanceKm,
    required double efficiency,
    required double energyPrice,
    double tollCost = 0,
    bool roundTrip = true,
  }) {
    final double safeOneWayDistance =
        distanceKm < 0 ? 0 : distanceKm;

    final double safeDistance =
        roundTrip ? safeOneWayDistance * 2 : safeOneWayDistance;

    final double safeEfficiency =
        efficiency <= 0 ? 1 : efficiency;

    final double safeEnergyPrice =
        energyPrice < 0 ? 0 : energyPrice;

    final double safeToll =
        tollCost < 0 ? 0 : tollCost;

    final double energyRequired =
        safeDistance / safeEfficiency;

    final double energyCost =
        energyRequired * safeEnergyPrice;

    return TravelCostResult(
      vehicleType: vehicleType,
      oneWayDistanceKm: safeOneWayDistance,
      distanceKm: safeDistance,
      efficiency: safeEfficiency,
      energyPrice: safeEnergyPrice,
      energyRequired: energyRequired,
      energyCost: energyCost,
      tollCost: safeToll,
    );
  }
}
