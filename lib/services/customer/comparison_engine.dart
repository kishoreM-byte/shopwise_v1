import '../../models/product.dart';
import '../../models/shop.dart';
import '../smart_score_service.dart';
import '../true_cost_service.dart';

class ComparisonShopCosts {
  const ComparisonShopCosts({
    required this.deliveryCost,
    required this.installationCost,
  });

  final double? deliveryCost;
  final double? installationCost;

  bool get isComplete => deliveryCost != null && installationCost != null;

  factory ComparisonShopCosts.fromShop(Shop shop) {
    double? knownCharge({
      required bool available,
      required bool isKnown,
      required double charge,
    }) {
      if (!available) return 0;
      if (!isKnown || !charge.isFinite || charge < 0) return null;
      return charge;
    }

    return ComparisonShopCosts(
      deliveryCost: knownCharge(
        available: shop.deliveryAvailable,
        isKnown: shop.deliveryChargeIsKnown,
        charge: shop.deliveryCharge,
      ),
      installationCost: knownCharge(
        available: shop.installationAvailable,
        isKnown: shop.installationChargeIsKnown,
        charge: shop.installationCharge,
      ),
    );
  }
}

class ComparisonProduct {
  const ComparisonProduct({
    required this.product,
    required this.smartScore,
    required this.trueCost,
    this.distanceKm,
    this.hasReliablePrice = false,
    this.hasReliableTravelCost = false,
    this.hasReliableShopCostData = false,
    this.hasReliableDeliveryCost = false,
    this.hasReliableInstallationCost = false,
  });

  final Product product;
  final SmartScoreResult smartScore;
  final double trueCost;
  final double? distanceKm;
  final bool hasReliablePrice;
  final bool hasReliableTravelCost;
  final bool hasReliableShopCostData;
  final bool hasReliableDeliveryCost;
  final bool hasReliableInstallationCost;
}

class ComparisonResult {
  const ComparisonResult({
    required this.products,
    required this.lowestPriceProductId,
    required this.highestRatedProductId,
    required this.bestAvailabilityProductId,
    required this.bestOfferProductId,
    required this.bestSmartScoreProductId,
    required this.lowestTrueCostProductId,
  });

  final List<ComparisonProduct> products;

  final String? lowestPriceProductId;
  final String? highestRatedProductId;
  final String? bestAvailabilityProductId;
  final String? bestOfferProductId;
  final String? bestSmartScoreProductId;
  final String? lowestTrueCostProductId;

  bool get hasReliableTravelCosts =>
      products.every((item) => item.hasReliableTravelCost);

  bool get hasReliableShopCostData =>
      products.every((item) => item.hasReliableShopCostData);

  bool get hasComparableDeliveryCosts =>
      products.every((item) => item.hasReliableDeliveryCost);

  bool get hasComparableInstallationCosts =>
      products.every((item) => item.hasReliableInstallationCost);

  bool get hasReliablePrices => products.every((item) => item.hasReliablePrice);

  String get trueCostUnavailableReason {
    final missing = <String>[];

    if (!hasReliablePrices) missing.add('listed price');
    if (!hasReliableTravelCosts) missing.add('travel route or estimate');
    if (!hasComparableDeliveryCosts) missing.add('delivery charge');
    if (!hasComparableInstallationCosts) missing.add('installation charge');

    if (missing.isEmpty) {
      return 'True cost is unavailable because a complete estimate could not be calculated.';
    }

    return 'True cost is unavailable: ${missing.join(', ')} '
        '${missing.length == 1 ? 'is' : 'are'} unknown for at least one shop.';
  }

  String get smartScoreCostSummary {
    final included = <String>[];
    final excluded = <String>[];

    if (hasReliableTravelCosts) {
      included.add('travel');
    } else {
      excluded.add('travel');
    }

    if (hasComparableDeliveryCosts) {
      included.add('delivery');
    } else {
      excluded.add('delivery');
    }

    if (hasComparableInstallationCosts) {
      included.add('installation');
    } else {
      excluded.add('installation');
    }

    final parts = <String>[];
    if (included.isNotEmpty) {
      parts.add('${included.join(', ')} costs included');
    }
    if (excluded.isNotEmpty) {
      parts.add(
        '${excluded.join(', ')} excluded because costs are unknown for at least one shop',
      );
    }

    return 'Smart Score: ${parts.join('; ')}.';
  }
}

class ComparisonEngine {
  const ComparisonEngine({
    this.smartScoreService = const SmartScoreService(),
    this.trueCostService = const TrueCostService(),
  });

  static const int minProducts = 2;
  static const int maxProducts = 4;

  final SmartScoreService smartScoreService;
  final TrueCostService trueCostService;

  ComparisonResult compare(
    List<Product> products, {
    Map<String, double> travelCosts = const {},
    Map<String, double> deliveryCosts = const {},
    Map<String, double> installationCosts = const {},
    Map<String, double> distancesKm = const {},
    Set<String>? reliableTravelCostProductIds,
    Set<String>? reliableShopCostDataProductIds,
  }) {
    if (products.length < minProducts) {
      throw ArgumentError(
        'At least $minProducts products are required for comparison.',
      );
    }

    if (products.length > maxProducts) {
      throw ArgumentError(
        'A maximum of $maxProducts products can be compared.',
      );
    }

    // Only apply a cost category to Smart Score when it is known for
    // every compared product. This prevents missing data from making one
    // product appear artificially cheaper than another.
    final comparableTravelCosts = products.every(
      (product) =>
          reliableTravelCostProductIds?.contains(product.id) ??
          travelCosts.containsKey(product.id),
    );
    final comparableDeliveryCosts = products.every(
      (product) => deliveryCosts.containsKey(product.id),
    );
    final comparableInstallationCosts = products.every(
      (product) => installationCosts.containsKey(product.id),
    );

    final comparisonProducts = products
        .map((product) {
          final hasReliableTravelCost =
              reliableTravelCostProductIds?.contains(product.id) ??
              travelCosts.containsKey(product.id);
          final hasReliableDeliveryCost = deliveryCosts.containsKey(product.id);
          final hasReliableInstallationCost = installationCosts.containsKey(
            product.id,
          );
          final hasReliableShopCostData =
              reliableShopCostDataProductIds?.contains(product.id) ??
              (hasReliableDeliveryCost && hasReliableInstallationCost);

          final double travelCost = travelCosts[product.id] ?? 0;
          final double deliveryCost = deliveryCosts[product.id] ?? 0;
          final double installationCost = installationCosts[product.id] ?? 0;

          // Unknown charges must not be treated as free when calculating a
          // comparable Smart Score. Keep the existing scoring weights, but
          // exclude the uncertain inputs from this product's cost impact.
          final smartScore = smartScoreService.calculate(
            product,
            travelCost: comparableTravelCosts ? travelCost : 0,
            deliveryCost: comparableDeliveryCosts ? deliveryCost : 0,
            installationCost: comparableInstallationCosts
                ? installationCost
                : 0,
          );

          final trueCostResult = trueCostService.calculate(
            productPrice: product.price,
            travelCost: travelCost,
            deliveryCost: deliveryCost,
            installationCost: installationCost,
          );

          return ComparisonProduct(
            product: product,
            smartScore: smartScore,
            trueCost: trueCostResult.totalCost,
            distanceKm: distancesKm[product.id],
            hasReliablePrice: product.price.isFinite && product.price > 0,
            hasReliableTravelCost: hasReliableTravelCost,
            hasReliableShopCostData: hasReliableShopCostData,
            hasReliableDeliveryCost: hasReliableDeliveryCost,
            hasReliableInstallationCost: hasReliableInstallationCost,
          );
        })
        .toList(growable: false);

    return ComparisonResult(
      products: comparisonProducts,
      lowestPriceProductId: _lowestPrice(comparisonProducts),
      highestRatedProductId: _highestRating(comparisonProducts),
      bestAvailabilityProductId: _bestAvailability(comparisonProducts),
      bestOfferProductId: _bestOffer(comparisonProducts),
      bestSmartScoreProductId: _bestSmartScore(comparisonProducts),
      lowestTrueCostProductId:
          comparisonProducts.every(
            (item) =>
                item.hasReliablePrice &&
                item.hasReliableTravelCost &&
                item.hasReliableShopCostData,
          )
          ? _lowestTrueCost(comparisonProducts)
          : null,
    );
  }

  double priceDifference(Product first, Product second) {
    return first.price - second.price;
  }

  double ratingDifference(Product first, Product second) {
    return first.rating - second.rating;
  }

  int stockDifference(Product first, Product second) {
    return first.stock - second.stock;
  }

  String? _lowestPrice(List<ComparisonProduct> products) {
    final priced = products.where((item) => item.hasReliablePrice).toList();
    if (priced.isEmpty) return null;

    return priced
        .reduce((a, b) => a.product.price <= b.product.price ? a : b)
        .product
        .id;
  }

  String? _highestRating(List<ComparisonProduct> products) {
    final rated = products
        .where(
          (item) =>
              item.product.rating.isFinite &&
              item.product.rating > 0 &&
              item.product.reviewCount > 0,
        )
        .toList(growable: false);
    if (rated.isEmpty) return null;

    return rated
        .reduce((a, b) => a.product.rating >= b.product.rating ? a : b)
        .product
        .id;
  }

  String? _bestAvailability(List<ComparisonProduct> products) {
    if (products.isEmpty) return null;

    return products
        .reduce(
          (a, b) =>
              a.smartScore.availabilityScore >= b.smartScore.availabilityScore
              ? a
              : b,
        )
        .product
        .id;
  }

  String? _bestOffer(List<ComparisonProduct> products) {
    final offered = products
        .where((item) => item.product.hasOffer)
        .toList(growable: false);
    if (offered.isEmpty) return null;

    return offered
        .reduce(
          (a, b) => a.smartScore.offerScore >= b.smartScore.offerScore ? a : b,
        )
        .product
        .id;
  }

  String? _bestSmartScore(List<ComparisonProduct> products) {
    final priced = products.where((item) => item.hasReliablePrice).toList();
    if (priced.isEmpty) return null;

    return priced
        .reduce((a, b) => a.smartScore.score >= b.smartScore.score ? a : b)
        .product
        .id;
  }

  String? _lowestTrueCost(List<ComparisonProduct> products) {
    if (products.isEmpty) return null;

    return products
        .reduce((a, b) => a.trueCost <= b.trueCost ? a : b)
        .product
        .id;
  }
}
