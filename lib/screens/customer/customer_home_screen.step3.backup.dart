import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/customer/wishlist_service.dart';
import '../../services/customer/compare_service.dart';

import '../profile/profile_screen.dart';
import 'product_details_screen.dart';
import 'best_deals_screen.dart';
import 'nearby_shops_screen.dart';
import 'smart_score_screen.dart';
import 'smart_trip_screen.dart';
import 'notifications_screen.dart';
import 'my_enquiries_screen.dart';

class _PremiumPressable extends StatefulWidget {
  const _PremiumPressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PremiumPressable> createState() => _PremiumPressableState();
}

class _PremiumPressableState extends State<_PremiumPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: ShopWiseMotion.micro,
      curve: ShopWiseMotion.standardCurve,
      child: Listener(
        onPointerDown: (_) {
          if (mounted) setState(() => _pressed = true);
        },
        onPointerUp: (_) {
          if (mounted) setState(() => _pressed = false);
        },
        onPointerCancel: (_) {
          if (mounted) setState(() => _pressed = false);
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ShopWiseRadius.large),
          child: InkWell(
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  String _searchQuery = '';

  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  bool _availableOnly = false;

  List<String> _cachedProductCategories = <String>[];

  final TextEditingController _searchController = TextEditingController();

  final WishlistService _wishlistService = WishlistService();
  final CompareService _compareService = CompareService();

  Set<String> _wishlistIds = <String>{};
  Set<String> _compareIds = <String>{};

  Stream<Set<String>> get _wishlistStream =>
      _wishlistService.watchWishlistIds();

  Stream<Set<String>> get _compareStream => _compareService.watchCompareIds();

  final List<String> _titles = const [
    'ShopWise',
    'Search',
    'Compare',
    'Wishlist',
    'Profile',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    // Profile is currently implemented as a separate screen.
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) {
        if (!mounted) return;

        setState(() {
          _currentIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ShopWiseColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openFeature(const NotificationsScreen()),
            icon: const Icon(
              Icons.notifications_none,
              color: ShopWiseColors.textPrimary,
            ),
          ),
        ],
      ),

      body: StreamBuilder<Set<String>>(
        stream: _wishlistStream,
        builder: (context, wishlistSnapshot) {
          _wishlistIds = wishlistSnapshot.data ?? <String>{};

          return StreamBuilder<Set<String>>(
            stream: _compareStream,
            builder: (context, compareSnapshot) {
              _compareIds = compareSnapshot.data ?? <String>{};
              return AnimatedSwitcher(
                duration: ShopWiseMotion.page,
                reverseDuration: ShopWiseMotion.fast,
                switchInCurve: ShopWiseMotion.entranceCurve,
                switchOutCurve: ShopWiseMotion.standardCurve,
                transitionBuilder: (child, animation) {
                  final bool movingForward = _currentIndex >= _previousIndex;

                  final Offset begin = movingForward
                      ? const Offset(0.035, 0)
                      : const Offset(-0.035, 0);

                  final Animation<Offset> slide =
                      Tween<Offset>(begin: begin, end: Offset.zero).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: ShopWiseMotion.entranceCurve,
                        ),
                      );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _buildBody(),
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationTap,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_outlined),
            selectedIcon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();

      case 1:
        return _buildSearch();

      case 2:
        return _buildCompare();

      case 3:
        return _buildWishlist();

      case 4:
        // Profile opens as a separate screen.
        return _buildHome();

      default:
        return _buildHome();
    }
  }

  // ---------------------------------------------------------------------------
  // HOME
  // ---------------------------------------------------------------------------

  Widget _buildHome() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),

            const SizedBox(height: 20),

            _buildSearchBar(),

            const SizedBox(height: 24),

            _buildSectionTitle(title: 'Quick Actions', actionText: null),

            const SizedBox(height: 12),

            _buildQuickActions(),

            const SizedBox(height: 28),

            _buildSectionTitle(title: 'Explore ShopWise', actionText: null),

            const SizedBox(height: 12),

            _buildFeatureGrid(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to ShopWise 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ShopWiseColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find the best product, price and deal.',
          style: TextStyle(fontSize: 14, color: ShopWiseColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return InkWell(
      borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
      onTap: () {
        setState(() {
          _currentIndex = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: ShopWiseColors.surface,
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          border: Border.all(color: ShopWiseColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: ShopWiseColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search products, shops...',
                style: TextStyle(color: ShopWiseColors.textMuted, fontSize: 14),
              ),
            ),
            Icon(Icons.tune, color: ShopWiseColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.compare_arrows,
            title: 'Compare',
            subtitle: 'Prices',
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.favorite,
            title: 'Wishlist',
            subtitle: 'Saved items',
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.mark_email_unread_outlined,
            title: 'Enquiries',
            subtitle: 'Track requests',
            onTap: () => _openFeature(const MyEnquiriesScreen()),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ShopWiseColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                ),
                child: Icon(icon, color: ShopWiseColors.emerald),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ShopWiseColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FUTURE FEATURES
  // ---------------------------------------------------------------------------

  Widget _buildFeatureGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _featureCard(
          icon: Icons.storefront_outlined,
          title: 'Nearby Shops',
          subtitle: 'Find shops around you',
          onTap: () => _openFeature(const NearbyShopsScreen()),
        ),
        _featureCard(
          icon: Icons.local_offer_outlined,
          title: 'Best Deals',
          subtitle: 'Discover active offers',
          onTap: () => _openFeature(const BestDealsScreen()),
        ),
        _featureCard(
          icon: Icons.analytics_outlined,
          title: 'Smart Score',
          subtitle: 'Rank products intelligently',
          onTap: () => _openFeature(const SmartScoreScreen()),
        ),
        _featureCard(
          icon: Icons.route_outlined,
          title: 'Smart Trip',
          subtitle: 'Compare travel cost',
          onTap: () => _openFeature(const SmartTripScreen()),
        ),
        _featureCard(
          icon: Icons.forum_outlined,
          title: 'My Enquiries',
          subtitle: 'Track your product requests',
          onTap: () => _openFeature(const MyEnquiriesScreen()),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: ShopWiseColors.surface,
      borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
        onTap: onTap ?? _showComingSoon,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: ShopWiseColors.search),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ShopWiseColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  Widget _buildSearch() {
    final ProductService productService = ProductService();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<Product>>(
          stream: productService.watchAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: ShopWiseColors.emerald),
              );
            }

            if (snapshot.hasError) {
              return _emptyState(
                icon: Icons.error_outline,
                title: 'Unable to load products',
                subtitle: 'Please try again later.',
              );
            }

            final products = snapshot.data ?? const <Product>[];

            _cachedProductCategories =
                products
                    .map((product) => product.category.trim())
                    .where((category) => category.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products or shops...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () => _showSearchFilters(context),
                      icon: const Icon(Icons.tune),
                    ),
                    filled: true,
                    fillColor: ShopWiseColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(child: _buildProductResults(products)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductResults(List<Product> products) {
    final query = _searchQuery;

    final filteredProducts = products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == null ||
          product.category.toLowerCase() == _selectedCategory!.toLowerCase();

      final matchesMinPrice = _minPrice == null || product.price >= _minPrice!;

      final matchesMaxPrice = _maxPrice == null || product.price <= _maxPrice!;

      final matchesAvailability =
          !_availableOnly || (product.isAvailable && product.stock > 0);

      return matchesQuery &&
          matchesCategory &&
          matchesMinPrice &&
          matchesMaxPrice &&
          matchesAvailability;
    }).toList();

    if (filteredProducts.isEmpty) {
      final hasFilters =
          _selectedCategory != null ||
          _minPrice != null ||
          _maxPrice != null ||
          _availableOnly;

      return _emptyState(
        icon: Icons.search_off,
        title: query.isEmpty && !hasFilters
            ? 'No products available'
            : 'No matching products',
        subtitle: query.isEmpty && !hasFilters
            ? 'Products added by shop owners will appear here.'
            : 'Try changing your search or filters.',
      );
    }

    return ListView.separated(
      itemCount: filteredProducts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];

        return Card(
          elevation: 0,
          color: ShopWiseColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(product: product),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: ShopWiseColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                    ),
                    child: product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                            child: Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) {
                                return const Icon(
                                  Icons.inventory_2_outlined,
                                  color: ShopWiseColors.emerald,
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: ShopWiseColors.emerald,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ShopWiseColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ShopWiseColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ShopWiseColors.emerald,
                              ),
                            ),
                            if (product.isAvailable && product.stock > 0) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: ShopWiseColors.emerald,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ShopWiseColors.emerald,
                                ),
                              ),
                            ],
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: ShopWiseColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // COMPARE
  // ---------------------------------------------------------------------------

  Widget _buildCompare() {
    return _buildSavedProducts(
      ids: _compareIds,
      icon: Icons.compare_arrows_rounded,
      title: 'Compare Products',
      emptySubtitle: 'Add products using Compare to see them here.',
    );
  }

  // ---------------------------------------------------------------------------
  // WISHLIST
  // ---------------------------------------------------------------------------

  Widget _buildWishlist() {
    return _buildSavedProducts(
      ids: _wishlistIds,
      icon: Icons.favorite_rounded,
      title: 'Your Wishlist',
      emptySubtitle: 'Products you save will appear here.',
    );
  }

  Widget _buildSavedProducts({
    required Set<String> ids,
    required IconData icon,
    required String title,
    required String emptySubtitle,
  }) {
    if (ids.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _emptyState(icon: icon, title: title, subtitle: emptySubtitle),
        ),
      );
    }

    return StreamBuilder<List<Product>>(
      stream: ProductService().watchAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = (snapshot.data ?? const <Product>[])
            .where((product) => ids.contains(product.id))
            .toList();

        if (products.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _emptyState(
                icon: Icons.inventory_2_outlined,
                title: title,
                subtitle: 'The saved products are no longer available.',
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];

            return _buildSavedProductCard(
              product,
              isCompared: _compareIds.contains(product.id),
              isWishlisted: _wishlistIds.contains(product.id),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedProductCard(
    Product product, {
    required bool isCompared,
    required bool isWishlisted,
  }) {
    return Card(
      elevation: 0,
      color: ShopWiseColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        side: const BorderSide(color: ShopWiseColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: ShopWiseColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                ),
                child: product.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                        child: Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_outlined,
                            color: ShopWiseColors.emerald,
                            size: 30,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: ShopWiseColors.emerald,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ShopWiseColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShopWiseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ShopWiseColors.emerald,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : isCompared
                              ? Icons.compare_arrows_rounded
                              : Icons.chevron_right_rounded,
                          color: isWishlisted || isCompared
                              ? ShopWiseColors.emerald
                              : ShopWiseColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: ShopWiseColors.emerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: ShopWiseColors.emerald),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: ShopWiseColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, String? actionText}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (actionText != null)
          TextButton(onPressed: _showComingSoon, child: Text(actionText)),
      ],
    );
  }

  void _showSearchFilters(BuildContext context) {
    String? category = _selectedCategory;
    double? minPrice = _minPrice;
    double? maxPrice = _maxPrice;
    bool availableOnly = _availableOnly;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ShopWiseColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ShopWiseRadius.sheet)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categories = <String>{
              'All',
              ..._cachedProductCategories,
            }.toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search filters',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ShopWiseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Refine products by category, price and availability.',
                        style: TextStyle(
                          fontSize: 13,
                          color: ShopWiseColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),

                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ShopWiseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((item) {
                          final selected = item == 'All'
                              ? category == null
                              : category == item;

                          return ChoiceChip(
                            label: Text(item),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                category = item == 'All' ? null : item;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Price range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ShopWiseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        initialValue: _priceRangeLabel(minPrice, maxPrice),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ShopWiseColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                            borderSide: const BorderSide(
                              color: ShopWiseColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                            borderSide: const BorderSide(
                              color: ShopWiseColors.border,
                            ),
                          ),
                        ),
                        hint: const Text('Any price'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Any price',
                            child: Text('Any price'),
                          ),
                          DropdownMenuItem(
                            value: 'Under ₹1,000',
                            child: Text('Under ₹1,000'),
                          ),
                          DropdownMenuItem(
                            value: '₹1,000 – ₹5,000',
                            child: Text('₹1,000 – ₹5,000'),
                          ),
                          DropdownMenuItem(
                            value: '₹5,000 – ₹10,000',
                            child: Text('₹5,000 – ₹10,000'),
                          ),
                          DropdownMenuItem(
                            value: 'Above ₹10,000',
                            child: Text('Above ₹10,000'),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            switch (value) {
                              case 'Under ₹1,000':
                                minPrice = 0;
                                maxPrice = 1000;
                                break;
                              case '₹1,000 – ₹5,000':
                                minPrice = 1000;
                                maxPrice = 5000;
                                break;
                              case '₹5,000 – ₹10,000':
                                minPrice = 5000;
                                maxPrice = 10000;
                                break;
                              case 'Above ₹10,000':
                                minPrice = 10000;
                                maxPrice = null;
                                break;
                              default:
                                minPrice = null;
                                maxPrice = null;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Available products only',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Hide products that are out of stock.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: availableOnly,
                        onChanged: (value) {
                          setSheetState(() {
                            availableOnly = value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _availableOnly = false;
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                                ),
                              ),
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = category;
                                  _minPrice = minPrice;
                                  _maxPrice = maxPrice;
                                  _availableOnly = availableOnly;
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: ShopWiseColors.emerald,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ShopWiseRadius.small),
                                ),
                              ),
                              child: const Text('Apply filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _priceRangeLabel(double? min, double? max) {
    if (min == null && max == null) return 'Any price';
    if (min == 0 && max == 1000) return 'Under ₹1,000';
    if (min == 1000 && max == 5000) return '₹1,000 – ₹5,000';
    if (min == 5000 && max == 10000) return '₹5,000 – ₹10,000';
    if (min == 10000 && max == null) return 'Above ₹10,000';
    return null;
  }

  void _openFeature(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showComingSoon() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This ShopWise feature will be connected next.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
