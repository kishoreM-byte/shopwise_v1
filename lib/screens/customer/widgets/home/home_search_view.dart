import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import '../../../../models/shop.dart';
import '../../../../services/product_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../theme/design_tokens.dart';
import 'home_empty_state.dart';
import 'home_product_results.dart';
import 'home_search_filters_sheet.dart';

class HomeSearchView extends StatefulWidget {
  const HomeSearchView({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategory,
    required this.minPrice,
    required this.maxPrice,
    required this.availableOnly,
    required this.categories,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onResetFilters,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final bool availableOnly;
  final List<String> categories;

  final ValueChanged<String> onSearchChanged;

  final void Function({
    required String? category,
    required double? minPrice,
    required double? maxPrice,
    required bool availableOnly,
  })
  onFiltersChanged;

  final VoidCallback onResetFilters;

  @override
  State<HomeSearchView> createState() => _HomeSearchViewState();
}

class _HomeSearchViewState extends State<HomeSearchView> {
  late final Stream<List<Product>> _productsStream;
  late final Stream<List<Shop>> _shopsStream;

  @override
  void initState() {
    super.initState();

    final ProductService productService = ProductService();
    final ShopService shopService = ShopService();

    _productsStream = productService.watchAllProducts();
    _shopsStream = shopService.watchAllShops();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<Product>>(
          stream: _productsStream,
          builder: (context, productSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: ShopWiseColors.emerald),
              );
            }

            if (productSnapshot.hasError) {
              return const HomeEmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load products',
                subtitle: 'Please try again later.',
              );
            }

            return StreamBuilder<List<Shop>>(
              stream: _shopsStream,
              builder: (context, shopSnapshot) {
                if (shopSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ShopWiseColors.emerald,
                    ),
                  );
                }

                if (shopSnapshot.hasError) {
                  return const HomeEmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to load shops',
                    subtitle: 'Please try again later.',
                  );
                }

                final List<Product> products =
                    productSnapshot.data ?? const <Product>[];

                final List<Shop> shops = shopSnapshot.data ?? const <Shop>[];

                final Map<String, Shop> shopsById = {
                  for (final Shop shop in shops)
                    if (shop.id.trim().isNotEmpty) shop.id: shop,
                };

                final List<String> liveCategories =
                    products
                        .map((product) => product.category.trim())
                        .where((category) => category.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort();

                final List<String> effectiveCategories =
                    liveCategories.isNotEmpty
                    ? liveCategories
                    : widget.categories;

                return Column(
                  children: [
                    TextField(
                      key: const ValueKey<String>('customer_search_field'),
                      controller: widget.searchController,
                      onChanged: widget.onSearchChanged,
                      textInputAction: TextInputAction.search,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Search products or shops...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Filters',
                          onPressed: () =>
                              _showFilters(context, effectiveCategories),
                          icon: const Icon(Icons.tune),
                        ),
                        filled: true,
                        fillColor: ShopWiseColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ShopWiseRadius.medium,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: HomeProductResults(
                        products: products,
                        shopsById: shopsById,
                        searchQuery: widget.searchQuery,
                        selectedCategory: widget.selectedCategory,
                        minPrice: widget.minPrice,
                        maxPrice: widget.maxPrice,
                        availableOnly: widget.availableOnly,
                        onEmptyState:
                            ({
                              required IconData icon,
                              required String title,
                              required String subtitle,
                            }) {
                              return HomeEmptyState(
                                icon: icon,
                                title: title,
                                subtitle: subtitle,
                              );
                            },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    List<String> effectiveCategories,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ShopWiseColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShopWiseRadius.sheet),
        ),
      ),
      builder: (_) {
        return HomeSearchFiltersSheet(
          categories: effectiveCategories,
          initialCategory: widget.selectedCategory,
          initialMinPrice: widget.minPrice,
          initialMaxPrice: widget.maxPrice,
          initialAvailableOnly: widget.availableOnly,
          onReset: widget.onResetFilters,
          onApply: widget.onFiltersChanged,
        );
      },
    );
  }
}
