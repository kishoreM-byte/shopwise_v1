import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/shop.dart';
import '../../services/shop_service.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  final ShopService _shopService = ShopService();

  Position? _position;
  bool _loadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location services are turned off.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required to find nearby shops.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _position = position;
        _loadingLocation = false;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double? _distanceKm(Shop shop) {
    final position = _position;

    if (position == null || shop.latitude == null || shop.longitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shop.latitude!,
          shop.longitude!,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        title: const Text(
          'Nearby Shops',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Shop>>(
        stream: _shopService.watchAllShops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final shops = [...(snapshot.data ?? const <Shop>[])];

          shops.sort((a, b) {
            final da = _distanceKm(a) ?? double.infinity;
            final db = _distanceKm(b) ?? double.infinity;
            return da.compareTo(db);
          });

          return RefreshIndicator(
            onRefresh: _loadLocation,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _buildLocationHeader(),
                const SizedBox(height: 18),
                if (shops.isEmpty)
                  _emptyState()
                else
                  ...shops.map(_buildShopCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ShopWiseColors.olive, ShopWiseColors.emerald],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.near_me_rounded,
            color: ShopWiseColors.surface,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shops around you',
                  style: TextStyle(
                    color: ShopWiseColors.surface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loadingLocation
                      ? 'Finding your location...'
                      : _locationError ?? 'Sorted by road proximity',
                  style: const TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadLocation,
            icon: const Icon(
              Icons.refresh_rounded,
              color: ShopWiseColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Shop shop) {
    final distance = _distanceKm(shop);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: ShopWiseColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ShopWiseColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: ShopWiseColors.emerald.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        shop.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.storefront_rounded,
                          color: ShopWiseColors.emerald,
                          size: 28,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
                      color: ShopWiseColors.emerald,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ShopWiseColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    shop.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ShopWiseColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        shop.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (distance != null)
                        Text(
                          '${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ShopWiseColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              shop.isOpen ? Icons.circle : Icons.circle_outlined,
              size: 11,
              color: shop.isOpen
                  ? ShopWiseColors.emerald
                  : ShopWiseColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 54,
            color: ShopWiseColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'No shops available yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Shop owners will appear here when their shops are published.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ShopWiseColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
