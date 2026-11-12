import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import '../../../../services/product_service.dart';
import '../../../../theme/design_tokens.dart';
import '../../product_details_screen.dart';

class HomeSavedProducts extends StatefulWidget {
  const HomeSavedProducts({
    super.key,
    required this.ids,
    required this.icon,
    required this.title,
    required this.emptySubtitle,
    required this.compareIds,
    required this.wishlistIds,
    this.productService,
    this.onRemoveWishlist,
    this.onCompareNow,
  });

  final Set<String> ids;
  final IconData icon;
  final String title;
  final String emptySubtitle;
  final Set<String> compareIds;
  final Set<String> wishlistIds;
  final ProductService? productService;
  final Future<void> Function(String productId)? onRemoveWishlist;
  final VoidCallback? onCompareNow;

  @override
  State<HomeSavedProducts> createState() => _HomeSavedProductsState();
}

class _HomeSavedProductsState extends State<HomeSavedProducts> {
  late ProductService _productService;
  Stream<List<Product>>? _productsStream;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _subscribeToProducts();
  }

  @override
  void didUpdateWidget(covariant HomeSavedProducts oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.productService != widget.productService) {
      _productService = widget.productService ?? ProductService();
    }

    if (!setEquals(oldWidget.ids, widget.ids) ||
        oldWidget.productService != widget.productService) {
      _subscribeToProducts();
    }
  }

  void _subscribeToProducts() {
    final ids = widget.ids.toSet();
    _productsStream = ids.isEmpty
        ? null
        : _productService.watchProductsByIds(ids);
  }

  void _retryProductLoad() {
    setState(_subscribeToProducts);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ids.isEmpty) {
      return _statusState(
        icon: widget.icon,
        title: widget.title,
        subtitle: widget.emptySubtitle,
      );
    }

    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _statusState(
            icon: Icons.cloud_off_rounded,
            title: 'Saved products unavailable',
            subtitle: 'Check your connection, then try loading them again.',
            actionLabel: 'Try again',
            onAction: _retryProductLoad,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _statusState(
            icon: Icons.bookmark_outline_rounded,
            title: 'Loading saved products',
            subtitle: 'Your shopping shortlist will be ready in a moment.',
            isLoading: true,
          );
        }

        final products = (snapshot.data ?? const <Product>[])
            .where((product) => widget.ids.contains(product.id))
            .toList();

        if (products.isEmpty) {
          return _statusState(
            icon: Icons.inventory_2_outlined,
            title: widget.title,
            subtitle: 'The saved products are no longer available.',
          );
        }

        final showCompareAction = widget.onCompareNow != null;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: products.length + (showCompareAction ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (showCompareAction && index == 0) {
              return _compareAction();
            }

            final product = products[index - (showCompareAction ? 1 : 0)];

            return _SavedProductCard(
              product: product,
              isCompared: widget.compareIds.contains(product.id),
              isWishlisted: widget.wishlistIds.contains(product.id),
              onRemoveWishlist: widget.onRemoveWishlist,
            );
          },
        );
      },
    );
  }

  Widget _compareAction() {
    final canCompare = widget.ids.length >= 2;

    return Card(
      elevation: 0,
      color: ShopWiseColors.emeraldSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare your shortlisted furniture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ShopWiseColors.emeraldDeep,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              canCompare
                  ? 'View prices, quality, availability and estimated total cost side by side.'
                  : 'Add at least 2 products to start comparing.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ShopWiseColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canCompare ? widget.onCompareNow : null,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('Compare now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    bool isLoading = false,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.58,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: ShopWiseColors.emeraldSoft,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(21),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: ShopWiseColors.emerald,
                          ),
                        )
                      : Icon(icon, size: 32, color: ShopWiseColors.emerald),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ShopWiseColors.textSecondary,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedProductCard extends StatefulWidget {
  const _SavedProductCard({
    required this.product,
    required this.isCompared,
    required this.isWishlisted,
    required this.onRemoveWishlist,
  });

  final Product product;
  final bool isCompared;
  final bool isWishlisted;
  final Future<void> Function(String productId)? onRemoveWishlist;

  @override
  State<_SavedProductCard> createState() => _SavedProductCardState();
}

class _SavedProductCardState extends State<_SavedProductCard> {
  bool _isRemoving = false;

  Future<void> _removeFromWishlist() async {
    final callback = widget.onRemoveWishlist;
    if (callback == null || _isRemoving) return;

    setState(() => _isRemoving = true);
    try {
      await callback(widget.product.id);
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final unavailable = !product.isAvailable || product.stock <= 0;

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
                        borderRadius: BorderRadius.circular(
                          ShopWiseRadius.small,
                        ),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ShopWiseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: ShopWiseColors.emeraldDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (widget.isWishlisted &&
                            widget.onRemoveWishlist != null)
                          IconButton(
                            tooltip: 'Remove from wishlist',
                            onPressed: _isRemoving ? null : _removeFromWishlist,
                            icon: _isRemoving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ShopWiseColors.emerald,
                                    ),
                                  )
                                : const Icon(Icons.favorite_rounded),
                            color: ShopWiseColors.emerald,
                          )
                        else
                          Icon(
                            widget.isWishlisted
                                ? Icons.favorite_rounded
                                : widget.isCompared
                                ? Icons.compare_arrows_rounded
                                : Icons.chevron_right_rounded,
                            color: widget.isWishlisted || widget.isCompared
                                ? ShopWiseColors.emerald
                                : ShopWiseColors.textMuted,
                          ),
                      ],
                    ),
                    if (unavailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Currently unavailable',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: ShopWiseColors.error,
                                fontWeight: FontWeight.w700,
                              ),
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
}
