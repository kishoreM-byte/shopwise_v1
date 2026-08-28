import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/product.dart';
import '../../models/shop.dart';
import '../../services/route_service.dart';
import '../../services/shop_service.dart';
import '../../services/customer/compare_service.dart';
import '../../services/customer/share_service.dart';
import '../../services/customer/wishlist_service.dart';
import 'widgets/product_gallery.dart';
import 'widgets/product_info.dart';
import 'widgets/shop_info_card.dart';
import 'widgets/smart_score_card.dart';
import 'widgets/shop_route_map.dart';
import 'widgets/product_actions.dart';
import 'buy_enquire_screen.dart';
import 'widgets/product_reviews.dart';
import 'widgets/review_composer.dart';
import '../../models/review.dart';
import '../../services/customer/review_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ShopService _shopService = ShopService();
  final RouteService _routeService = RouteService();
  final WishlistService _wishlistService = WishlistService();
  final CompareService _compareService = CompareService();
  final ShareService _shareService = ShareService();
  final ReviewService _reviewService = ReviewService();

  late Future<Shop?> _shopFuture;

  bool _isWishlisted = false;
  bool _isCompared = false;
  bool _isActionLoading = false;
  Position? _customerPosition;
  ShopRouteResult? _routeResult;
  String? _routeError;
  bool _isGettingCustomerLocation = false;
  bool _isLoadingRoute = false;
  ProductReview? _myReview;
  bool _isLoadingMyReview = true;

  @override
  void initState() {
    super.initState();
    _shopFuture = _loadShop();
    _loadProductActionState();
  }

  Future<void> _loadMyReview() async {
    try {
      final review = await _reviewService.getMyReview(widget.product.id);

      if (!mounted) return;

      setState(() {
        _myReview = review;
        _isLoadingMyReview = false;
      });
    } catch (e) {
      debugPrint('ShopWise review load error: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingMyReview = false;
      });
    }
  }

  Future<Shop?> _loadShop() async {
    final String shopId = widget.product.shopId.trim();

    if (shopId.isNotEmpty) {
      final Shop? shop = await _shopService.getShopById(shopId);

      if (shop != null) {
        return shop;
      }
    }

    final String ownerId = widget.product.ownerId.trim();

    if (ownerId.isEmpty) {
      return null;
    }

    return _shopService.getShopByOwnerId(ownerId);
  }

  Future<void> _getCustomerLocation() async {
    setState(() {
      _isGettingCustomerLocation = true;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showLocationMessage('Please turn on location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Location permission is permanently denied. Enable it from Settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _customerPosition = position;
      });

      await _loadRouteFromCustomerLocation(position);
    } catch (e) {
      if (!mounted) return;
      _showLocationMessage('Unable to get your location.');
    } finally {
      if (mounted) {
        setState(() {
          _isGettingCustomerLocation = false;
        });
      }
    }
  }

  Future<void> _loadRouteFromCustomerLocation(Position position) async {
    final Shop? shop = await _shopFuture;

    if (!mounted) return;

    if (shop?.latitude == null || shop?.longitude == null) {
      setState(() {
        _routeResult = null;
        _routeError = 'Shop location is unavailable.';
        _isLoadingRoute = false;
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    try {
      final ShopRouteResult route = await _routeService.getDrivingRoute(
        customerLatitude: position.latitude,
        customerLongitude: position.longitude,
        shopLatitude: shop!.latitude!,
        shopLongitude: shop.longitude!,
      );

      if (!mounted) return;

      setState(() {
        _routeResult = route;
        _routeError = null;
      });
    } catch (e) {
      debugPrint('ShopWise route error: $e');

      if (!mounted) return;

      setState(() {
        _routeResult = null;
        _routeError =
            'Unable to calculate the road route. You can still use manual travel distance below.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  Future<void> _retryRouteCalculation() async {
    final Position? position = _customerPosition;

    if (position == null || _isLoadingRoute) return;

    await _loadRouteFromCustomerLocation(position);
  }

  Future<void> _loadProductActionState() async {
    try {
      final results = await Future.wait<bool>([
        _wishlistService.isSaved(widget.product.id),
        _compareService.isCompared(widget.product.id),
      ]);

      if (!mounted) return;

      setState(() {
        _isWishlisted = results[0];
        _isCompared = results[1];
      });
    } catch (e) {
      debugPrint('ShopWise product action state error: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final saved = await _wishlistService.toggle(widget.product.id);

      if (!mounted) return;

      setState(() => _isWishlisted = saved);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              saved ? 'Added to your wishlist.' : 'Removed from your wishlist.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _toggleCompare() async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final added = await _compareService.toggle(widget.product.id);

      if (!mounted) return;

      setState(() => _isCompared = added);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              added ? 'Added to comparison.' : 'Removed from comparison.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _openBuyEnquire() async {
    final shop = await _shopFuture;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyEnquireScreen(product: widget.product, shop: shop),
      ),
    );
  }

  Future<void> _shareProduct() async {
    try {
      final shop = await _shopFuture;

      await _shareService.shareProduct(
        productName: widget.product.name,
        price: widget.product.price,
        shopName: shop?.name ?? 'Local Shop',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to share this product right now.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      bottomNavigationBar: ProductActions(
        product: product,
        isWishlisted: _isWishlisted,
        isCompared: _isCompared,
        isLoading: _isActionLoading,
        onWishlist: _toggleWishlist,
        onCompare: _toggleCompare,
        onShare: _shareProduct,
        onBuyEnquire: _openBuyEnquire,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductGallery(imageUrls: product.imageUrls),

            const SizedBox(height: 22),

            ProductInfo(product: product),

            const SizedBox(height: 24),

            FutureBuilder<Shop?>(
              future: _shopFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return SmartScoreCard(
                  product: product,
                  shop: snapshot.data,
                  routeDistanceKm: _routeResult?.distanceKm,
                  isRouteDistanceLoading: _isLoadingRoute,
                  routeDistanceError: _routeError,
                );
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Sold by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 10),

            FutureBuilder<Shop?>(
              future: _shopFuture,
              builder: (context, snapshot) {
                return ShopInfoCard(
                  shop: snapshot.data,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                );
              },
            ),

            const SizedBox(height: 24),

            FutureBuilder<Shop?>(
              future: _shopFuture,
              builder: (context, snapshot) {
                final shop = snapshot.data;

                if (shop?.latitude == null || shop?.longitude == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find this shop',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'See your location and the shop location on the map.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    if (_customerPosition == null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isGettingCustomerLocation
                              ? null
                              : _getCustomerLocation,
                          icon: _isGettingCustomerLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: Text(
                            _isGettingCustomerLocation
                                ? 'Getting your location...'
                                : 'Show Route From My Location',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    else
                      ShopRouteMap(
                        customerLatitude: _customerPosition!.latitude,
                        customerLongitude: _customerPosition!.longitude,
                        shopLatitude: shop!.latitude!,
                        shopLongitude: shop.longitude!,
                        shopName: shop.name,
                        route: _routeResult,
                        isLoading: _isLoadingRoute,
                        errorMessage: _routeError,
                        onRetry: _retryRouteCalculation,
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            const SizedBox(height: 28),

            if (!_isLoadingMyReview)
              ReviewComposer(
                productId: product.id,
                existingReview: _myReview,
                onSaved: _loadMyReview,
              ),

            const SizedBox(height: 28),

            ProductReviews(productId: product.id),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
