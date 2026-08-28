class TravelCost {
  final double distanceKm;
  final double fuelCost;
  final double tollCost;

  const TravelCost({
    this.distanceKm = 0,
    this.fuelCost = 0,
    this.tollCost = 0,
  });

  double get totalTravelCost => fuelCost + tollCost;

  bool get hasData =>
      distanceKm > 0 || fuelCost > 0 || tollCost > 0;
}
