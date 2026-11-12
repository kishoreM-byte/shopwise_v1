import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/design_tokens.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      final String query = _searchQuery.trim().toLowerCase();

      final bool matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);

      final bool matchesFilter = switch (_selectedFilter) {
        'Available' => product.isAvailableForPurchase,
        'Out of stock' => product.stock <= 0,
        'Offers' => product.hasOffer,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _addProduct() async {
    final bool? added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (added == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _editProduct(Product product) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hide product?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Hide "${product.name}" from customers? Existing order records will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hide product'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _productService.deleteProduct(product.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product hidden from customers'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to hide product: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        elevation: 0,
        foregroundColor: ShopWiseColors.textPrimary,
        title: const Text(
          'Products',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Add product',
            onPressed: _addProduct,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.watchMyProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ShopWiseColors.emerald),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final List<Product> products = snapshot.data ?? const <Product>[];

          final List<Product> filteredProducts = _filterProducts(products);

          return RefreshIndicator(
            color: ShopWiseColors.emerald,
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 400));

              if (mounted) {
                setState(() {});
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                _buildSummary(products),

                const SizedBox(height: 20),

                _buildSearch(),

                const SizedBox(height: 14),

                _buildFilters(),

                const SizedBox(height: 20),

                if (products.isEmpty)
                  _buildEmptyState()
                else if (filteredProducts.isEmpty)
                  _buildNoResults()
                else
                  ...filteredProducts.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCard(product),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ShopWiseColors.emerald,
        foregroundColor: ShopWiseColors.surface,
        onPressed: _addProduct,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSummary(List<Product> products) {
    final int available = products
        .where((p) => p.isAvailableForPurchase)
        .length;
    final int outOfStock = products.where((p) => p.stock <= 0).length;
    final int offers = products.where((p) => p.hasOffer).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ShopWiseColors.olive.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ShopWiseColors.oliveSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: ShopWiseColors.olive,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Products',
                      style: TextStyle(
                        color: ShopWiseColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manage your shop inventory',
                      style: TextStyle(
                        color: ShopWiseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: ShopWiseColors.surface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${products.length} items',
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _dashboardStat(
                  value: '$available',
                  label: 'Available',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              _darkDivider(),
              Expanded(
                child: _dashboardStat(
                  value: '$outOfStock',
                  label: 'Out of stock',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              _darkDivider(),
              Expanded(
                child: _dashboardStat(
                  value: '$offers',
                  label: 'Offers',
                  icon: Icons.local_offer_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardStat({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: ShopWiseColors.olive),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: ShopWiseColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ShopWiseColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _darkDivider() {
    return Container(
      width: 1,
      height: 48,
      color: ShopWiseColors.olive.withValues(alpha: 0.20),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search products or categories...',
        hintStyle: const TextStyle(
          color: ShopWiseColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ShopWiseColors.textSecondary,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: ShopWiseColors.textMuted,
                ),
              )
            : null,
        filled: true,
        fillColor: ShopWiseColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ShopWiseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ShopWiseColors.olive, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const List<String> filters = ['All', 'Available', 'Out of stock', 'Offers'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final bool selected = filter == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              child: ChoiceChip(
                label: Text(filter),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                showCheckmark: false,
                selectedColor: ShopWiseColors.oliveSoft,
                backgroundColor: ShopWiseColors.surface,
                labelStyle: TextStyle(
                  color: selected
                      ? ShopWiseColors.olive
                      : ShopWiseColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected
                      ? ShopWiseColors.olive
                      : ShopWiseColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final bool outOfStock = product.stock <= 0;
    final bool hasDiscount =
        product.originalPrice != null && product.originalPrice! > product.price;

    int? discountPercent;

    if (hasDiscount) {
      discountPercent = ((1 - (product.price / product.originalPrice!)) * 100)
          .round();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
        onTap: () => _editProduct(product),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ShopWiseColors.surface,
            borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
            border: Border.all(color: ShopWiseColors.border),
            boxShadow: [
              BoxShadow(
                color: ShopWiseColors.textPrimary.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildProductImage(product),
                  if (product.hasOffer)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ShopWiseColors.olive,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OFFER',
                          style: TextStyle(
                            color: ShopWiseColors.surface,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ShopWiseColors.textPrimary,
                              fontSize: 16,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            tooltip: 'Product actions',
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editProduct(product);
                              } else if (value == 'delete') {
                                _deleteProduct(product);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: ShopWiseColors.olive,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_off_outlined,
                                      color: ShopWiseColors.error,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Hide'),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: ShopWiseColors.textMuted,
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ShopWiseColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: ShopWiseColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: ShopWiseColors.olive,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 7),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '₹${product.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: ShopWiseColors.textMuted,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          if (discountPercent != null &&
                              discountPercent > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ShopWiseColors.oliveSoft,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$discountPercent% OFF',
                                style: const TextStyle(
                                  color: ShopWiseColors.search,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statusBadge(
                          outOfStock
                              ? 'Out of stock'
                              : product.isAvailable
                              ? 'Available'
                              : 'Hidden',
                          outOfStock
                              ? ShopWiseColors.error.withValues(alpha: 0.12)
                              : product.isAvailable
                              ? ShopWiseColors.oliveSoft
                              : ShopWiseColors.surfaceSoft,
                          outOfStock
                              ? ShopWiseColors.error
                              : product.isAvailable
                              ? ShopWiseColors.olive
                              : ShopWiseColors.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            '${product.stock} in stock',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ShopWiseColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  Widget _buildProductImage(Product product) {
    if (product.imageUrls.isEmpty) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: ShopWiseColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: ShopWiseColors.textMuted,
          size: 30,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        product.imageUrls.first,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const SizedBox(
            width: 88,
            height: 88,
            child: ColoredBox(
              color: ShopWiseColors.surfaceSoft,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ShopWiseColors.emerald,
                  ),
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, error, stackTrace) {
          return Container(
            width: 88,
            height: 88,
            color: ShopWiseColors.surfaceSoft,
            child: const Icon(
              Icons.broken_image_outlined,
              color: ShopWiseColors.textMuted,
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _emptyContainer(
      icon: Icons.inventory_2_outlined,
      title: 'No products yet',
      subtitle:
          'Add your first product and start building your shop inventory.',
      buttonText: 'Add Product',
      onPressed: _addProduct,
    );
  }

  Widget _buildNoResults() {
    return _emptyContainer(
      icon: Icons.search_off_rounded,
      title: 'No products found',
      subtitle: 'Try changing your search or selected filter.',
    );
  }

  Widget _emptyContainer({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: ShopWiseColors.olive, size: 30),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ShopWiseColors.textPrimary,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: ShopWiseColors.textMuted,
            ),
          ),

          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: ShopWiseColors.olive,
                foregroundColor: ShopWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: ShopWiseColors.textMuted,
            ),

            const SizedBox(height: 14),

            const Text(
              'Unable to load products',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 8),

            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
