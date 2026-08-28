enum DeliveryType { selfPickup, shopDelivery, externalDelivery }

class DeliveryCostResult {
  final DeliveryType type;
  final double cost;

  const DeliveryCostResult({required this.type, required this.cost});

  bool get isFree => cost <= 0;

  String get label {
    switch (type) {
      case DeliveryType.selfPickup:
        return 'Self pickup';
      case DeliveryType.shopDelivery:
        return 'Shop delivery';
      case DeliveryType.externalDelivery:
        return 'External delivery';
    }
  }
}

class DeliveryCostService {
  const DeliveryCostService();

  DeliveryCostResult calculate({
    required DeliveryType type,
    double shopDeliveryCost = 0,
    double externalDeliveryCost = 0,
  }) {
    double cost;

    switch (type) {
      case DeliveryType.selfPickup:
        cost = 0;
        break;

      case DeliveryType.shopDelivery:
        cost = shopDeliveryCost;
        break;

      case DeliveryType.externalDelivery:
        cost = externalDeliveryCost;
        break;
    }

    return DeliveryCostResult(type: type, cost: cost < 0 ? 0 : cost);
  }
}
