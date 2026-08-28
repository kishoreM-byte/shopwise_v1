import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'widgets/home/home_saved_products.dart';
import 'widgets/home/home_section_title.dart';

import '../../services/customer/wishlist_service.dart';
import '../../services/customer/compare_service.dart';

import '../profile/profile_screen.dart';
import 'widgets/home/home_welcome_section.dart';
import 'widgets/home/home_quick_actions.dart';
import 'widgets/home/home_feature_grid.dart';
import 'widgets/home/home_search_bar.dart';
import 'widgets/home/home_search_view.dart';
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

  final List<String> _cachedProductCategories = <String>[];

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
          final wishlistIds = wishlistSnapshot.data ?? <String>{};

          return StreamBuilder<Set<String>>(
            stream: _compareStream,
            builder: (context, compareSnapshot) {
              final compareIds = compareSnapshot.data ?? <String>{};

              if (_wishlistIds != wishlistIds) {
                _wishlistIds = wishlistIds;
              }

              if (_compareIds != compareIds) {
                _compareIds = compareIds;
              }

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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 22),
            _buildSearchBar(),
            const SizedBox(height: 28),
            _buildSectionTitle(title: 'Quick Actions', actionText: null),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 30),
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
    return const HomeWelcomeSection();
  }

  Widget _buildSearchBar() {
    return HomeSearchBar(
      onTap: () {
        setState(() {
          _currentIndex = 1;
        });
      },
    );
  }

  Widget _buildQuickActions() {
    return HomeQuickActions(
      onCompare: () {
        setState(() {
          _previousIndex = _currentIndex;
          _currentIndex = 2;
        });
      },
      onWishlist: () {
        setState(() {
          _previousIndex = _currentIndex;
          _currentIndex = 3;
        });
      },
      onEnquiries: () => _openFeature(const MyEnquiriesScreen()),
    );
  }

  Widget _buildFeatureGrid() {
    return HomeFeatureGrid(
      onNearbyShops: () => _openFeature(const NearbyShopsScreen()),
      onBestDeals: () => _openFeature(const BestDealsScreen()),
      onSmartScore: () => _openFeature(const SmartScoreScreen()),
      onSmartTrip: () => _openFeature(const SmartTripScreen()),
      onEnquiries: () => _openFeature(const MyEnquiriesScreen()),
    );
  }

  Widget _buildSearch() {
    return HomeSearchView(
      searchController: _searchController,
      searchQuery: _searchQuery,
      selectedCategory: _selectedCategory,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      availableOnly: _availableOnly,
      categories: _cachedProductCategories,
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
      onFiltersChanged:
          ({
            required String? category,
            required double? minPrice,
            required double? maxPrice,
            required bool availableOnly,
          }) {
            setState(() {
              _selectedCategory = category;
              _minPrice = minPrice;
              _maxPrice = maxPrice;
              _availableOnly = availableOnly;
            });
          },
      onResetFilters: () {
        setState(() {
          _selectedCategory = null;
          _minPrice = null;
          _maxPrice = null;
          _availableOnly = false;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // COMPARE
  // ---------------------------------------------------------------------------

  Widget _buildCompare() {
    return HomeSavedProducts(
      ids: _compareIds,
      icon: Icons.compare_arrows_rounded,
      title: 'Compare Products',
      emptySubtitle: 'Add products using Compare to see them here.',
      compareIds: _compareIds,
      wishlistIds: _wishlistIds,
    );
  }

  Widget _buildWishlist() {
    return HomeSavedProducts(
      ids: _wishlistIds,
      icon: Icons.favorite_rounded,
      title: 'Your Wishlist',
      emptySubtitle: 'Products you save will appear here.',
      compareIds: _compareIds,
      wishlistIds: _wishlistIds,
    );
  }

  Widget _buildSectionTitle({required String title, String? actionText}) {
    return HomeSectionTitle(
      title: title,
      actionText: actionText,
      onAction: actionText == null ? null : _showComingSoon,
    );
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
