class PurchaseCost {
  final double deliveryCost;
  final double installationCost;

  const PurchaseCost({
    this.deliveryCost = 0,
    this.installationCost = 0,
  });

  double get additionalCost =>
      deliveryCost + installationCost;

  PurchaseCost copyWith({
    double? deliveryCost,
    double? installationCost,
  }) {
    return PurchaseCost(
      deliveryCost: deliveryCost ?? this.deliveryCost,
      installationCost: installationCost ?? this.installationCost,
    );
  }
}
