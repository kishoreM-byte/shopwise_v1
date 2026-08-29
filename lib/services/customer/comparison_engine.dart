import '../../models/product.dart';
import '../smart_score_service.dart';
import '../true_cost_service.dart';

class ComparisonProduct {
  const ComparisonProduct({
    required this.product,
    required this.smartScore,
    required this.trueCost,
  });

  final Product product;
  final SmartScoreResult smartScore;
  final double trueCost;
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

    final comparisonProducts = products
        .map((product) {
          final double travelCost = travelCosts[product.id] ?? 0;
          final double deliveryCost = deliveryCosts[product.id] ?? 0;
          final double installationCost = installationCosts[product.id] ?? 0;

          final smartScore = smartScoreService.calculate(
            product,
            travelCost: travelCost,
            deliveryCost: deliveryCost,
            installationCost: installationCost,
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
      lowestTrueCostProductId: _lowestTrueCost(comparisonProducts),
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
    if (products.isEmpty) return null;

    return products
        .reduce((a, b) => a.product.price <= b.product.price ? a : b)
        .product
        .id;
  }

  String? _highestRating(List<ComparisonProduct> products) {
    if (products.isEmpty) return null;

    return products
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
    if (products.isEmpty) return null;

    return products
        .reduce(
          (a, b) => a.smartScore.offerScore >= b.smartScore.offerScore ? a : b,
        )
        .product
        .id;
  }

  String? _bestSmartScore(List<ComparisonProduct> products) {
    if (products.isEmpty) return null;

    return products
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
