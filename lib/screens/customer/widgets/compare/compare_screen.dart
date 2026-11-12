import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../models/product.dart';
import '../../../../models/shop.dart';
import 'components/compare_header.dart';
import 'components/comparison_hero.dart';
import 'components/product_comparison_strip.dart';
import '../../../../services/customer/comparison_engine.dart';
import '../../../../services/customer/compare_service.dart';
import '../../../../services/route_service.dart';
import '../../../../services/travel_cost_service.dart';

import '../../../../services/product_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../theme/design_tokens.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.compareIds});

  final Set<String> compareIds;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final ProductService _productService = ProductService();
  final CompareService _compareService = CompareService();
  final ComparisonEngine _comparisonEngine = const ComparisonEngine();
  final ShopService _shopService = ShopService();
  final RouteService _routeService = RouteService();
  final TravelCostService _travelCostService = const TravelCostService();

  bool _clearing = false;
  Map<String, Shop> _shopsById = <String, Shop>{};
  Set<String>? _loadedShopIds;
  Set<String>? _pendingShopIds;
  Future<Map<String, Shop>>? _shopsFuture;
  String? _comparisonKey;
  Future<ComparisonResult>? _comparisonFuture;

  @override
  Widget build(BuildContext context) {
    if (widget.compareIds.isEmpty) {
      return _CompareEmptyState(onBrowse: () => Navigator.maybePop(context));
    }

    return StreamBuilder<List<Product>>(
      stream: _productService.watchProductsByIds(widget.compareIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CompareLoadingState(
            message: 'Loading your saved comparison…',
          );
        }

        if (snapshot.hasError) {
          return _CompareErrorState(
            message: 'We couldn’t load your comparison products.',
            onRetry: () => setState(() {}),
          );
        }

        final products = (snapshot.data ?? const <Product>[])
            .where((product) => widget.compareIds.contains(product.id))
            .toList();

        if (products.length < ComparisonEngine.minProducts) {
          return _CompareNeedsProducts(
            productCount: products.length,
            onBack: () => Navigator.maybePop(context),
          );
        }

        final shopIds = products.map((product) => product.shopId).toSet();

        return FutureBuilder<Map<String, Shop>>(
          future: _shopsFutureFor(shopIds),
          builder: (context, shopSnapshot) {
            if (shopSnapshot.hasError) {
              return _CompareErrorState(
                message: 'We couldn’t load shop details for comparison.',
                onRetry: _retryComparison,
              );
            }

            final shops = shopSnapshot.data ?? _shopsById;

            return FutureBuilder<ComparisonResult>(
              future: _comparisonFutureFor(products, shops),
              builder: (context, comparisonSnapshot) {
                if (comparisonSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _CompareLoadingState(
                    message: 'Preparing your side-by-side view…',
                  );
                }

                if (comparisonSnapshot.hasError ||
                    comparisonSnapshot.data == null) {
                  return _CompareErrorState(
                    message: 'We couldn’t calculate the comparison costs.',
                    onRetry: _retryComparison,
                  );
                }

                return _CompareContent(
                  result: comparisonSnapshot.data!,
                  shopsById: shops,
                  onRemove: _removeProduct,
                  onClear: _clearAll,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, Shop>> _shopsFutureFor(Set<String> shopIds) {
    if (_loadedShopIds?.containsAll(shopIds) ?? false) {
      return Future<Map<String, Shop>>.value(_shopsById);
    }

    final pending = _pendingShopIds;
    if (pending != null &&
        pending.length == shopIds.length &&
        pending.containsAll(shopIds) &&
        _shopsFuture != null) {
      return _shopsFuture!;
    }

    _pendingShopIds = Set<String>.from(shopIds);
    return _shopsFuture = _loadShops(shopIds);
  }

  Future<ComparisonResult> _comparisonFutureFor(
    List<Product> products,
    Map<String, Shop> shops,
  ) {
    final productKey = products
        .map(
          (product) =>
              '${product.id}:${product.price}:${product.rating}:${product.reviewCount}:${product.stock}:${product.isAvailable}:${product.hasOffer}:${product.originalPrice}',
        )
        .join('|');
    final shopKey = shops.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    final key =
        '$productKey::${shopKey.map((shop) => '${shop.id}:${shop.latitude}:${shop.longitude}:${shop.deliveryAvailable}:${shop.deliveryCharge}:${shop.installationAvailable}:${shop.installationCharge}').join('|')}';

    if (_comparisonKey == key && _comparisonFuture != null) {
      return _comparisonFuture!;
    }

    _comparisonKey = key;
    return _comparisonFuture = _buildComparison(products, shops);
  }

  void _retryComparison() {
    setState(() {
      _comparisonKey = null;
      _comparisonFuture = null;
      _pendingShopIds = null;
      _shopsFuture = null;
      _loadedShopIds = null;
    });
  }

  Future<ComparisonResult> _buildComparison(
    List<Product> products,
    Map<String, Shop> shops,
  ) async {
    Position? position;

    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition();
        }
      }
    } catch (_) {
      position = null;
    }

    final Map<String, double> travelCosts = <String, double>{};
    final Map<String, double> deliveryCosts = <String, double>{};
    final Map<String, double> installationCosts = <String, double>{};
    final Map<String, double> distancesKm = <String, double>{};
    final Set<String> reliableTravelCostProductIds = <String>{};
    final Set<String> reliableShopCostDataProductIds = <String>{};

    await Future.wait(
      products.map((product) async {
        final shop = shops[product.shopId];

        if (shop == null) {
          return;
        }

        final distance = _distanceFromCustomer(position, shop);
        if (distance != null) distancesKm[product.id] = distance;

        if (position != null &&
            _validCoordinates(position.latitude, position.longitude) &&
            shop.latitude != null &&
            shop.longitude != null &&
            _validCoordinates(shop.latitude!, shop.longitude!)) {
          try {
            final route = await _routeService.getDrivingRoute(
              customerLatitude: position.latitude,
              customerLongitude: position.longitude,
              shopLatitude: shop.latitude!,
              shopLongitude: shop.longitude!,
            );

            if (!route.distanceKm.isFinite || route.distanceKm < 0) {
              return;
            }

            final vehicle = TravelCostService.vehicleProfiles.firstWhere(
              (profile) => profile.type == VehicleType.car,
            );

            final travel = _travelCostService.calculate(
              vehicleType: vehicle.type,
              distanceKm: route.distanceKm,
              efficiency: vehicle.defaultEfficiency,
              energyPrice: vehicle.defaultEnergyPrice,
            );

            travelCosts[product.id] = travel.totalCost;
            reliableTravelCostProductIds.add(product.id);
          } catch (_) {
            // Keep the route cost unknown; zero would imply free travel.
          }
        } else {
          // Keep the route cost unknown until a location and route are available.
        }

        final shopCosts = ComparisonShopCosts.fromShop(shop);
        if (shopCosts.deliveryCost != null) {
          deliveryCosts[product.id] = shopCosts.deliveryCost!;
        }
        if (shopCosts.installationCost != null) {
          installationCosts[product.id] = shopCosts.installationCost!;
        }
        if (shopCosts.isComplete) {
          reliableShopCostDataProductIds.add(product.id);
        }
      }),
    );

    // Keep the Smart Score comparable across products: if any route is
    // missing, omit route costs for every option and label them unavailable.
    if (reliableTravelCostProductIds.length != products.length) {
      travelCosts.clear();
      reliableTravelCostProductIds.clear();
    }

    return _comparisonEngine.compare(
      products,
      travelCosts: travelCosts,
      deliveryCosts: deliveryCosts,
      installationCosts: installationCosts,
      distancesKm: distancesKm,
      reliableTravelCostProductIds: reliableTravelCostProductIds,
      reliableShopCostDataProductIds: reliableShopCostDataProductIds,
    );
  }

  double? _distanceFromCustomer(Position? position, Shop shop) {
    final latitude = shop.latitude;
    final longitude = shop.longitude;
    if (position == null || latitude == null || longitude == null) return null;
    if (!_validCoordinates(position.latitude, position.longitude) ||
        !_validCoordinates(latitude, longitude)) {
      return null;
    }

    const earthRadiusKm = 6371.0;
    final latitudeDelta = (latitude - position.latitude) * math.pi / 180;
    final longitudeDelta = (longitude - position.longitude) * math.pi / 180;
    final latitude1 = position.latitude * math.pi / 180;
    final latitude2 = latitude * math.pi / 180;
    final a =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(latitude1) *
            math.cos(latitude2) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final boundedA = a.clamp(0.0, 1.0);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(boundedA), math.sqrt(1 - boundedA));
  }

  bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  Future<Map<String, Shop>> _loadShops(Set<String> shopIds) async {
    if (_loadedShopIds != null && _loadedShopIds!.containsAll(shopIds)) {
      return _shopsById;
    }

    final entries = await Future.wait(
      shopIds.map((shopId) async {
        final shop = await _shopService.getShopById(shopId);
        return MapEntry(shopId, shop);
      }),
    );

    final loaded = <String, Shop>{
      for (final entry in entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    if (mounted) {
      _shopsById = {..._shopsById, ...loaded};
      _loadedShopIds = {...shopIds};
    }

    return _shopsById;
  }

  Future<void> _removeProduct(String productId) async {
    try {
      await _compareService.remove(productId);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t remove this product.')),
      );
    }
  }

  Future<void> _clearAll() async {
    if (_clearing) return;

    setState(() => _clearing = true);

    try {
      await _compareService.clear();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t clear comparison.')),
      );
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }
}

class _CompareContent extends StatelessWidget {
  const _CompareContent({
    required this.result,
    required this.shopsById,
    required this.onRemove,
    required this.onClear,
  });

  final ComparisonResult result;
  final Map<String, Shop> shopsById;
  final Future<void> Function(String productId) onRemove;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CompareHeader(
                    productCount: result.products.length,
                    onClear: onClear,
                  ),
                  const SizedBox(height: 20),
                  ComparisonHero(result: result),
                  const SizedBox(height: 25),
                  const _CompareSectionHeading(
                    title: 'Your options',
                    subtitle: 'Swipe to see every saved product',
                  ),
                  const SizedBox(height: 12),
                  ProductComparisonStrip(
                    result: result,
                    shopsById: shopsById,
                    onRemove: onRemove,
                  ),
                  const SizedBox(height: 22),
                  const _CompareSectionHeading(
                    title: 'Side-by-side details',
                    subtitle: 'A quick read of the differences that matter',
                  ),
                  const SizedBox(height: 12),
                  _ComparisonTable(result: result),
                  const SizedBox(height: 24),
                  _DecisionCard(result: result),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareSectionHeading extends StatelessWidget {
  const _CompareSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ShopWiseColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: ShopWiseColors.textSecondary),
        ),
      ],
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final tableWidth = math
        .max(
          MediaQuery.sizeOf(context).width - 40,
          184 + result.products.length * 116,
        )
        .toDouble();
    return Container(
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        border: Border.all(color: ShopWiseColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              const _TableTitle(),
              _ProductColumnHeadings(products: result.products),
              _ComparisonRow(
                label: 'Price',
                icon: Icons.sell_outlined,
                values: result.products
                    .map((item) => '₹${item.product.price.toStringAsFixed(0)}')
                    .toList(),
                winnerId: result.lowestPriceProductId,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Travel / Fuel',
                icon: Icons.local_gas_station_outlined,
                values: result.products
                    .map(
                      (item) => item.hasReliableTravelCost
                          ? '₹${item.smartScore.travelCost.toStringAsFixed(0)}'
                          : 'Unavailable',
                    )
                    .toList(),
                winnerId: null,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Delivery',
                icon: Icons.local_shipping_outlined,
                values: result.products
                    .map(
                      (item) => item.hasReliableDeliveryCost
                          ? '₹${item.smartScore.deliveryCost.toStringAsFixed(0)}'
                          : 'Unavailable',
                    )
                    .toList(),
                winnerId: null,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Installation',
                icon: Icons.build_outlined,
                values: result.products
                    .map(
                      (item) => item.hasReliableInstallationCost
                          ? '₹${item.smartScore.installationCost.toStringAsFixed(0)}'
                          : 'Unavailable',
                    )
                    .toList(),
                winnerId: null,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Smart Score',
                icon: Icons.auto_awesome_outlined,
                values: result.products
                    .map(
                      (item) =>
                          '${item.smartScore.score.toStringAsFixed(0)}/100',
                    )
                    .toList(),
                winnerId: result.bestSmartScoreProductId,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Rating',
                icon: Icons.star_outline_rounded,
                values: result.products
                    .map(
                      (item) => item.product.rating > 0
                          ? item.product.rating.toStringAsFixed(1)
                          : 'No rating',
                    )
                    .toList(),
                winnerId: result.highestRatedProductId,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Distance · direct',
                icon: Icons.location_on_outlined,
                values: result.products
                    .map(
                      (item) => item.distanceKm == null
                          ? 'Unavailable'
                          : '${item.distanceKm!.toStringAsFixed(1)} km',
                    )
                    .toList(),
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Reviews',
                icon: Icons.reviews_outlined,
                values: result.products
                    .map((item) => '${item.product.reviewCount}')
                    .toList(),
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Availability',
                icon: Icons.inventory_2_outlined,
                values: result.products
                    .map(
                      (item) =>
                          item.product.isAvailable && item.product.stock > 0
                          ? '${item.product.stock} in stock'
                          : 'Unavailable',
                    )
                    .toList(),
                winnerId: result.bestAvailabilityProductId,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'Offer',
                icon: Icons.local_offer_outlined,
                values: result.products
                    .map(
                      (item) => item.product.hasOffer
                          ? (item.product.offerText?.trim().isNotEmpty ?? false)
                                ? item.product.offerText!
                                : 'Available'
                          : 'No offer',
                    )
                    .toList(),
                winnerId: result.bestOfferProductId,
                products: result.products,
              ),
              _ComparisonRow(
                label: 'True cost',
                icon: Icons.account_balance_wallet_outlined,
                values: result.products
                    .map(
                      (item) => result.lowestTrueCostProductId == null
                          ? 'Unavailable'
                          : '₹${item.trueCost.toStringAsFixed(0)}',
                    )
                    .toList(),
                winnerId: result.lowestTrueCostProductId,
                products: result.products,
                last: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableTitle extends StatelessWidget {
  const _TableTitle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: const BoxDecoration(color: ShopWiseColors.surfaceSoft),
      child: const Row(
        children: [
          Icon(Icons.compare_arrows_rounded, color: ShopWiseColors.emerald),
          SizedBox(width: 9),
          Text(
            'Side-by-side comparison',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProductColumnHeadings extends StatelessWidget {
  const _ProductColumnHeadings({required this.products});

  final List<ComparisonProduct> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ShopWiseColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 144,
            child: Text(
              'PRODUCT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ShopWiseColors.textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
          for (final item in products)
            SizedBox(
              width: 116,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.icon,
    required this.values,
    required this.products,
    this.winnerId,
    this.last = false,
  });

  final String label;
  final IconData icon;
  final List<String> values;
  final List<ComparisonProduct> products;
  final String? winnerId;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(top: BorderSide(color: ShopWiseColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 136,
            child: Row(
              children: [
                Icon(icon, size: 17, color: ShopWiseColors.olive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ShopWiseColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(products.length, (index) {
              final product = products[index];
              final isWinner = product.product.id == winnerId;

              return SizedBox(
                width: 116,
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: isWinner
                        ? BoxDecoration(
                            color: ShopWiseColors.oliveSoft,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Text(
                      values[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: isWinner
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isWinner
                            ? ShopWiseColors.olive
                            : ShopWiseColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final winner = result.products.firstWhere(
      (item) => item.product.id == result.bestSmartScoreProductId,
      orElse: () => result.products.first,
    );

    final lowestCost = result.products.firstWhere(
      (item) => item.product.id == result.lowestTrueCostProductId,
      orElse: () => result.products.first,
    );
    final lowestPrice = result.lowestPriceProductId == null
        ? null
        : result.products.firstWhere(
            (item) => item.product.id == result.lowestPriceProductId,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        border: Border.all(color: ShopWiseColors.border),
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ShopWiseColors.oliveSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: ShopWiseColors.olive,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'A clearer comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ShopWiseColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            result.bestSmartScoreProductId == null
                ? 'A Smart Pick is unavailable because comparable listed prices are missing.'
                : '${winner.product.name} leads on ShopWise Smart Score. '
                      '${winner.smartScore.componentSummary}. '
                      '${result.smartScoreCostSummary}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ShopWiseColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DecisionMetric(
                  label: result.bestSmartScoreProductId == null
                      ? 'Smart Pick'
                      : 'ShopWise Pick',
                  value: result.bestSmartScoreProductId == null
                      ? 'Unavailable'
                      : '${winner.smartScore.score.toStringAsFixed(0)}/100',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DecisionMetric(
                  label: 'Lowest listed price',
                  value: lowestPrice == null
                      ? 'Unavailable'
                      : '₹${lowestPrice.product.price.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (result.lowestTrueCostProductId != null)
            _DecisionMetric(
              label: 'Lowest true cost · Route calculated',
              value: '₹${lowestCost.trueCost.toStringAsFixed(0)}',
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: ShopWiseColors.oliveSoft.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
              ),
              child: Text(
                result.trueCostUnavailableReason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ShopWiseColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DecisionMetric extends StatelessWidget {
  const _DecisionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopWiseColors.oliveSoft.withValues(alpha: 0.55),
        border: Border.all(
          color: ShopWiseColors.border.withValues(alpha: 0.85),
        ),
        borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ShopWiseColors.textMuted,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ShopWiseColors.olive,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareLoadingState extends StatelessWidget {
  const _CompareLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
          decoration: BoxDecoration(
            color: ShopWiseColors.surface,
            borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
            border: Border.all(color: ShopWiseColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: ShopWiseColors.oliveSoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  size: 32,
                  color: ShopWiseColors.olive,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'BUILDING YOUR COMPARISON',
                style: TextStyle(
                  color: ShopWiseColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Finding your best match',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ShopWiseColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ShopWiseColors.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 132,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: ShopWiseColors.oliveSoft,
                  color: ShopWiseColors.olive,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareEmptyState extends StatelessWidget {
  const _CompareEmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.compare_arrows_rounded,
      title: 'Nothing to compare yet',
      subtitle:
          'Add two to four products to see price, ratings, availability and Smart Score side by side.',
      actionLabel: 'Browse products',
      onAction: onBrowse,
    );
  }
}

class _CompareNeedsProducts extends StatelessWidget {
  const _CompareNeedsProducts({
    required this.productCount,
    required this.onBack,
  });

  final int productCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.compare_arrows_rounded,
      title: 'Add one more product',
      subtitle:
          'Comparison becomes useful when you have at least two available products.',
      actionLabel: 'Back',
      onAction: onBack,
    );
  }
}

class _CompareErrorState extends StatelessWidget {
  const _CompareErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      subtitle: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ShopWiseColors.emeraldSoft,
                      ShopWiseColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
                  border: Border.all(
                    color: ShopWiseColors.emerald.withValues(alpha: .15),
                  ),
                ),
                child: Icon(icon, size: 36, color: ShopWiseColors.emerald),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ShopWiseColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: ShopWiseColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
