class TrueCostResult {
  final double productPrice;
  final double travelCost;
  final double deliveryCost;
  final double installationCost;

  const TrueCostResult({
    required this.productPrice,
    required this.travelCost,
    required this.deliveryCost,
    required this.installationCost,
  });

  double get additionalCost =>
      travelCost + deliveryCost + installationCost;

  double get totalCost =>
      productPrice + additionalCost;
}

class TrueCostService {
  const TrueCostService();

  TrueCostResult calculate({
    required double productPrice,
    double travelCost = 0,
    double deliveryCost = 0,
    double installationCost = 0,
  }) {
    return TrueCostResult(
      productPrice: _safe(productPrice),
      travelCost: _safe(travelCost),
      deliveryCost: _safe(deliveryCost),
      installationCost: _safe(installationCost),
    );
  }

  double _safe(double value) {
    return value < 0 ? 0 : value;
  }
}
