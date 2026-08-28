enum InstallationType { notRequired, shopInstallation, externalInstallation }

class InstallationCostResult {
  final InstallationType type;
  final double cost;

  const InstallationCostResult({required this.type, required this.cost});

  bool get isFree => cost <= 0;

  String get label {
    switch (type) {
      case InstallationType.notRequired:
        return 'Not required';
      case InstallationType.shopInstallation:
        return 'Shop installation';
      case InstallationType.externalInstallation:
        return 'External installation';
    }
  }
}

class InstallationCostService {
  const InstallationCostService();

  InstallationCostResult calculate({
    required InstallationType type,
    double shopInstallationCost = 0,
    double externalInstallationCost = 0,
  }) {
    double cost;

    switch (type) {
      case InstallationType.notRequired:
        cost = 0;
        break;

      case InstallationType.shopInstallation:
        cost = shopInstallationCost;
        break;

      case InstallationType.externalInstallation:
        cost = externalInstallationCost;
        break;
    }

    return InstallationCostResult(type: type, cost: cost < 0 ? 0 : cost);
  }
}
