import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/product.dart';
import '../../../models/shop.dart';
import '../../route_service.dart';
import '../../smart_score_service.dart';
import '../../travel_cost_service.dart';
import '../comparison_engine.dart';
import '../../true_cost_service.dart';

class NearbyCostEstimate {
  const NearbyCostEstimate({
    required this.productPrice,
    required this.roadDistanceKm,
    required this.travelCost,
    required this.deliveryCost,
    required this.installationCost,
  });

  final double? productPrice;
  final double? roadDistanceKm;
  final double? travelCost;
  final double? deliveryCost;
  final double? installationCost;

  bool get isComplete =>
      productPrice != null &&
      roadDistanceKm != null &&
      travelCost != null &&
      deliveryCost != null &&
      installationCost != null;

  double? get estimatedTotalCost {
    if (!isComplete) return null;
    return const TrueCostService()
        .calculate(
          productPrice: productPrice!,
          travelCost: travelCost!,
          deliveryCost: deliveryCost!,
          installationCost: installationCost!,
        )
        .totalCost;
  }

  List<String> get missingComponents => [
    if (roadDistanceKm == null || travelCost == null) 'road travel estimate',
    if (deliveryCost == null) 'delivery charge',
    if (installationCost == null) 'installation charge',
  ];
}

class NearbyCompareItem {
  const NearbyCompareItem({
    required this.product,
    required this.shop,
    required this.distanceKm,
    this.isSelected = false,
    this.costEstimate,
    this.smartScore,
    this.smartScoreExplanation,
    this.isLowestListedPrice = false,
    this.isLowestEstimatedTotal = false,
    this.isBestValue = false,
  });

  final Product product;
  final Shop? shop;

  /// Straight-line distance from the customer's location, in kilometres.
  final double? distanceKm;
  final bool isSelected;
  final NearbyCostEstimate? costEstimate;
  final SmartScoreResult? smartScore;
  final String? smartScoreExplanation;
  final bool isLowestListedPrice;
  final bool isLowestEstimatedTotal;
  final bool isBestValue;

  NearbyCompareItem copyWith({
    NearbyCostEstimate? costEstimate,
    SmartScoreResult? smartScore,
    String? smartScoreExplanation,
    bool clearSmartScore = false,
    bool? isLowestListedPrice,
    bool? isLowestEstimatedTotal,
    bool? isBestValue,
  }) => NearbyCompareItem(
    product: product,
    shop: shop,
    distanceKm: distanceKm,
    isSelected: isSelected,
    costEstimate: costEstimate ?? this.costEstimate,
    smartScore: clearSmartScore ? null : smartScore ?? this.smartScore,
    smartScoreExplanation: clearSmartScore
        ? null
        : smartScoreExplanation ?? this.smartScoreExplanation,
    isLowestListedPrice: isLowestListedPrice ?? this.isLowestListedPrice,
    isLowestEstimatedTotal:
        isLowestEstimatedTotal ?? this.isLowestEstimatedTotal,
    isBestValue: isBestValue ?? this.isBestValue,
  );
}

class NearbyComparisonAnalysis {
  const NearbyComparisonAnalysis({
    required this.items,
    required this.hasComparableCosts,
    required this.hasBestValueTie,
    required this.radiusKm,
  });

  final List<NearbyCompareItem> items;
  final bool hasComparableCosts;
  final bool hasBestValueTie;
  final double radiusKm;

  NearbyCompareItem? get bestValue =>
      items.where((item) => item.isBestValue).firstOrNull;
  NearbyCompareItem? get lowestEstimatedTotal =>
      items.where((item) => item.isLowestEstimatedTotal).firstOrNull;
}

class NearbyCompareService {
  NearbyCompareService({
    FirebaseFirestore? firestore,
    RouteService? routeService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _routeService = routeService ?? RouteService();

  final FirebaseFirestore _firestore;
  final RouteService _routeService;
  final TravelCostService _travelCostService = const TravelCostService();
  final ComparisonEngine _comparisonEngine = const ComparisonEngine();

  static const double defaultRadiusKm = 20.0;
  static const int maxResults = 3;
  static const int maxProductReads = 200;
  static const int maxShopReads = 100;

  static String get travelAssumptions {
    final car = TravelCostService.vehicleProfiles.firstWhere(
      (profile) => profile.type == VehicleType.car,
    );
    return '${car.shortName} (${car.defaultEfficiency} km/L at '
        '₹${car.defaultEnergyPrice}/L)';
  }

  Future<List<NearbyCompareItem>> findAlternatives({
    required Product selectedProduct,
    required double customerLatitude,
    required double customerLongitude,
    double radiusKm = defaultRadiusKm,
  }) async {
    final category = selectedProduct.category.trim().toLowerCase();

    if (!_validCoordinates(customerLatitude, customerLongitude) ||
        !radiusKm.isFinite ||
        radiusKm <= 0) {
      return const <NearbyCompareItem>[];
    }

    if (category.isEmpty || selectedProduct.id.trim().isEmpty) {
      return [
        NearbyCompareItem(
          product: selectedProduct,
          shop: null,
          distanceKm: null,
          isSelected: true,
        ),
      ];
    }

    // One bounded category read avoids requiring geospatial indexes or paid
    // services. Name matching and distance filtering happen locally.
    final snapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: selectedProduct.category.trim())
        .limit(maxProductReads)
        .get();

    final products = snapshot.docs
        .map(_readProduct)
        .whereType<Product>()
        .where(
          (product) =>
              product.id != selectedProduct.id &&
              product.shopId != selectedProduct.shopId &&
              product.shopId.trim().isNotEmpty &&
              product.name.trim().isNotEmpty &&
              product.price.isFinite &&
              product.price > 0 &&
              product.isAvailableForPurchase &&
              product.category.trim().toLowerCase() == category &&
              _namesAreComparable(selectedProduct.name, product.name),
        )
        .toList(growable: false);

    final shopIds = <String>{...products.map((product) => product.shopId)};
    if (selectedProduct.shopId.trim().isNotEmpty) {
      shopIds.add(selectedProduct.shopId);
    }

    final boundedShopIds = <String>[
      if (shopIds.contains(selectedProduct.shopId)) selectedProduct.shopId,
      ...shopIds.where((id) => id != selectedProduct.shopId),
    ].take(maxShopReads).toList(growable: false);
    final shops = <String, Shop>{};

    for (var i = 0; i < boundedShopIds.length; i += 10) {
      final chunk = boundedShopIds.sublist(
        i,
        math.min(i + 10, boundedShopIds.length),
      );
      final shopSnapshot = await _firestore
          .collection('shops')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in shopSnapshot.docs) {
        final shop = _readShop(doc);
        if (shop != null) shops[shop.id] = shop;
      }
    }

    final alternativesByShop = <String, NearbyCompareItem>{};
    for (final product in products) {
      final shop = shops[product.shopId];
      final distanceKm = _shopDistanceKm(
        shop,
        customerLatitude,
        customerLongitude,
      );
      if (shop == null || distanceKm == null || distanceKm > radiusKm) continue;

      final candidate = NearbyCompareItem(
        product: product,
        shop: shop,
        distanceKm: distanceKm,
      );
      final current = alternativesByShop[shop.id];
      if (current == null ||
          candidate.product.price < current.product.price ||
          (candidate.product.price == current.product.price &&
              candidate.product.id.compareTo(current.product.id) < 0)) {
        alternativesByShop[shop.id] = candidate;
      }
    }

    final alternatives = alternativesByShop.values.toList()
      ..sort((a, b) {
        final distanceCompare = a.distanceKm!.compareTo(b.distanceKm!);
        if (distanceCompare != 0) return distanceCompare;
        final priceCompare = a.product.price.compareTo(b.product.price);
        if (priceCompare != 0) return priceCompare;
        return a.product.id.compareTo(b.product.id);
      });

    final selectedShop = shops[selectedProduct.shopId];
    final selected = NearbyCompareItem(
      product: selectedProduct,
      shop: selectedShop,
      distanceKm: _shopDistanceKm(
        selectedShop,
        customerLatitude,
        customerLongitude,
      ),
      isSelected: true,
    );

    return [selected, ...alternatives.take(maxResults)];
  }

  /// Adds route-based cost estimates to the selected product and at most
  /// three nearby shops. The road route is one-way; the existing travel
  /// estimator applies its documented round-trip default.
  Future<NearbyComparisonAnalysis> analyzeCosts({
    required List<NearbyCompareItem> items,
    required double customerLatitude,
    required double customerLongitude,
    double radiusKm = defaultRadiusKm,
  }) async {
    final selected = items.where((item) => item.isSelected).firstOrNull;
    if (selected == null) {
      return NearbyComparisonAnalysis(
        items: items,
        hasComparableCosts: false,
        hasBestValueTie: false,
        radiusKm: radiusKm,
      );
    }

    final boundedItems = <NearbyCompareItem>[
      selected,
      ...items.where((item) => !item.isSelected).take(maxResults),
    ];

    final estimated = await Future.wait(
      boundedItems.map((item) async {
        final productPrice =
            item.product.price.isFinite && item.product.price > 0
            ? item.product.price
            : null;
        final shop = item.shop;
        double? roadDistanceKm;
        double? travelCost;
        if (shop != null &&
            _validCoordinates(customerLatitude, customerLongitude) &&
            shop.latitude != null &&
            shop.longitude != null &&
            _validCoordinates(shop.latitude!, shop.longitude!)) {
          try {
            final route = await _routeService.getDrivingRoute(
              customerLatitude: customerLatitude,
              customerLongitude: customerLongitude,
              shopLatitude: shop.latitude!,
              shopLongitude: shop.longitude!,
            );
            if (route.distanceKm.isFinite && route.distanceKm >= 0) {
              roadDistanceKm = route.distanceKm;
              final car = TravelCostService.vehicleProfiles.firstWhere(
                (profile) => profile.type == VehicleType.car,
              );
              final travel = _travelCostService.calculate(
                vehicleType: car.type,
                distanceKm: route.distanceKm,
                efficiency: car.defaultEfficiency,
                energyPrice: car.defaultEnergyPrice,
                roundTrip: true,
              );
              if (travel.totalCost.isFinite && travel.totalCost >= 0) {
                travelCost = travel.totalCost;
              }
            }
          } catch (_) {
            // Route failure remains unknown; it must never read as free travel.
          }
        }

        final deliveryCost = shop == null
            ? null
            : !shop.deliveryAvailable
            ? 0.0
            : shop.deliveryChargeIsKnown &&
                  shop.deliveryCharge.isFinite &&
                  shop.deliveryCharge >= 0
            ? shop.deliveryCharge
            : null;
        final installationCost = shop == null
            ? null
            : !shop.installationAvailable
            ? 0.0
            : shop.installationChargeIsKnown &&
                  shop.installationCharge.isFinite &&
                  shop.installationCharge >= 0
            ? shop.installationCharge
            : null;

        return item.copyWith(
          costEstimate: NearbyCostEstimate(
            productPrice: productPrice,
            roadDistanceKm: roadDistanceKm,
            travelCost: travelCost,
            deliveryCost: deliveryCost,
            installationCost: installationCost,
          ),
        );
      }),
    );

    final eligible = estimated
        .where(
          (item) =>
              item.product.price.isFinite &&
              item.product.price > 0 &&
              item.product.isAvailableForPurchase,
        )
        .toList(growable: false);
    final complete = eligible
        .where((item) => item.costEstimate?.isComplete ?? false)
        .toList(growable: false);
    String? lowestListedId;
    if (eligible.isNotEmpty) {
      final lowestPrice = eligible
          .map((item) => item.product.price)
          .reduce(math.min);
      final leaders = eligible
          .where((item) => (item.product.price - lowestPrice).abs() < 0.01)
          .toList(growable: false);
      if (leaders.length == 1) lowestListedId = leaders.single.product.id;
    }
    String? lowestTotalId;
    if (eligible.length >= 2 && complete.length == eligible.length) {
      final minTotal = complete
          .map((item) => item.costEstimate!.estimatedTotalCost!)
          .reduce(math.min);
      final lowest = complete
          .where(
            (item) =>
                (item.costEstimate!.estimatedTotalCost! - minTotal).abs() <
                0.01,
          )
          .toList(growable: false);
      if (lowest.length == 1) lowestTotalId = lowest.single.product.id;
    }

    var hasBestValueTie = false;
    final allCostsComplete =
        eligible.length >= 2 && complete.length == eligible.length;
    if (allCostsComplete) {
      final engineResult = _comparisonEngine.compare(
        eligible.map((item) => item.product).toList(growable: false),
        travelCosts: {
          for (final item in eligible)
            item.product.id: item.costEstimate!.travelCost!,
        },
        deliveryCosts: {
          for (final item in eligible)
            item.product.id: item.costEstimate!.deliveryCost!,
        },
        installationCosts: {
          for (final item in eligible)
            item.product.id: item.costEstimate!.installationCost!,
        },
        distancesKm: {
          for (final item in eligible)
            if (item.costEstimate!.roadDistanceKm != null)
              item.product.id: item.costEstimate!.roadDistanceKm!,
        },
        reliableTravelCostProductIds: eligible
            .map((item) => item.product.id)
            .toSet(),
        reliableShopCostDataProductIds: eligible
            .map((item) => item.product.id)
            .toSet(),
      );
      final scores = engineResult.products;
      final highestScore = scores
          .map((item) => item.smartScore.score)
          .reduce(math.max);
      final best = scores
          .where((item) => (item.smartScore.score - highestScore).abs() < 0.01)
          .toList(growable: false);
      hasBestValueTie = best.length > 1;
      final bestValueId = best.length == 1 ? best.single.product.id : null;
      final scoredItems = estimated
          .map((item) {
            final comparison = scores
                .where((score) => score.product.id == item.product.id)
                .firstOrNull;
            return item.copyWith(
              smartScore: comparison?.smartScore,
              smartScoreExplanation: comparison?.smartScore.componentSummary,
              clearSmartScore: comparison == null,
              isLowestListedPrice: item.product.id == lowestListedId,
              isLowestEstimatedTotal: item.product.id == lowestTotalId,
              isBestValue: item.product.id == bestValueId,
            );
          })
          .toList(growable: false);
      return NearbyComparisonAnalysis(
        items: scoredItems,
        hasComparableCosts: true,
        hasBestValueTie: hasBestValueTie,
        radiusKm: radiusKm,
      );
    }

    return NearbyComparisonAnalysis(
      items: estimated
          .map(
            (item) => item.copyWith(
              clearSmartScore: true,
              isLowestListedPrice: item.product.id == lowestListedId,
              isLowestEstimatedTotal: item.product.id == lowestTotalId,
              isBestValue: false,
            ),
          )
          .toList(growable: false),
      hasComparableCosts: false,
      hasBestValueTie: hasBestValueTie,
      radiusKm: radiusKm,
    );
  }

  Product? _readProduct(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return Product.fromMap({...doc.data(), 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  Shop? _readShop(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return Shop.fromMap({...doc.data(), 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  static bool _namesAreComparable(String selectedName, String candidateName) {
    final selectedTerms = _comparisonTerms(selectedName);
    final candidateTerms = _comparisonTerms(candidateName);
    if (selectedTerms.isEmpty || candidateTerms.isEmpty) return false;
    final shared = selectedTerms.intersection(candidateTerms);
    final selectedTypes = selectedTerms.intersection(_productTypes);
    final candidateTypes = candidateTerms.intersection(_productTypes);
    if (selectedTypes.isNotEmpty && candidateTypes.isNotEmpty) {
      if (selectedTypes.intersection(candidateTypes).isEmpty) return false;
      final selectedSubtypes = selectedTerms.intersection(_tableSubtypes);
      final candidateSubtypes = candidateTerms.intersection(_tableSubtypes);
      if (selectedSubtypes.isNotEmpty &&
          candidateSubtypes.isNotEmpty &&
          selectedSubtypes.intersection(candidateSubtypes).isEmpty) {
        return false;
      }
      return true;
    }
    if (shared.length >= 2) return true;
    return selectedTerms.length == 1 &&
        candidateTerms.length == 1 &&
        shared.length == 1;
  }

  static const _productTypes = <String>{
    'bed',
    'bench',
    'bookshelf',
    'cabinet',
    'chair',
    'couch',
    'desk',
    'dresser',
    'recliner',
    'shelf',
    'sofa',
    'stool',
    'table',
    'wardrobe',
  };
  static const _tableSubtypes = <String>{
    'coffee',
    'console',
    'dining',
    'end',
    'side',
  };

  static Set<String> _comparisonTerms(String value) {
    const genericTerms = <String>{
      'a',
      'an',
      'and',
      'best',
      'classic',
      'for',
      'furniture',
      'modern',
      'new',
      'of',
      'premium',
      'quality',
      'solid',
      'the',
      'with',
      'wood',
      'wooden',
    };
    final normalized = value.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );
    return normalized
        .split(' ')
        .where((term) => term.length > 1 && !genericTerms.contains(term))
        .toSet();
  }

  double? _shopDistanceKm(Shop? shop, double latitude, double longitude) {
    final shopLatitude = shop?.latitude;
    final shopLongitude = shop?.longitude;
    if (shopLatitude == null || shopLongitude == null) return null;
    if (!_validCoordinates(shopLatitude, shopLongitude)) return null;
    return _distanceKm(latitude, longitude, shopLatitude, shopLongitude);
  }

  bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final bounded = a.clamp(0.0, 1.0);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(bounded), math.sqrt(1 - bounded));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
