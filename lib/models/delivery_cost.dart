class DeliveryCost {
  final double deliveryCharge;
  final double installationCharge;

  const DeliveryCost({
    this.deliveryCharge = 0,
    this.installationCharge = 0,
  });

  double get totalCost => deliveryCharge + installationCharge;

  bool get hasData => deliveryCharge > 0 || installationCharge > 0;
}
