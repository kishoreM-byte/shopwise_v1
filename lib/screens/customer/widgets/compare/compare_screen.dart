import 'package:flutter/material.dart';

import '../../../../models/product.dart';
import 'components/compare_header.dart';
import 'components/comparison_hero.dart';
import 'components/product_comparison_strip.dart';
import '../../../../services/customer/comparison_engine.dart';
import '../../../../services/customer/compare_service.dart';
import '../../../../services/product_service.dart';
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

  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.compareIds.isEmpty) {
      return _CompareEmptyState(onBrowse: () => Navigator.maybePop(context));
    }

    return StreamBuilder<List<Product>>(
      stream: _productService.watchProductsByIds(widget.compareIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        final result = _comparisonEngine.compare(products);

        return _CompareContent(
          result: result,
          onRemove: _removeProduct,
          onClear: _clearAll,
        );
      },
    );
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
    required this.onRemove,
    required this.onClear,
  });

  final ComparisonResult result;
  final Future<void> Function(String productId) onRemove;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                const SizedBox(height: 24),
                ProductComparisonStrip(result: result, onRemove: onRemove),
                const SizedBox(height: 24),
                _ComparisonTable(result: result),
                const SizedBox(height: 24),
                _DecisionCard(result: result),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ShopWiseColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _TableTitle(),
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
            label: 'Smart Score',
            icon: Icons.auto_awesome_outlined,
            values: result.products
                .map(
                  (item) => '${item.smartScore.score.toStringAsFixed(0)}/100',
                )
                .toList(),
            winnerId: result.bestSmartScoreProductId,
            products: result.products,
          ),
          _ComparisonRow(
            label: 'Rating',
            icon: Icons.star_outline_rounded,
            values: result.products
                .map((item) => item.product.rating.toStringAsFixed(1))
                .toList(),
            winnerId: result.highestRatedProductId,
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
                  (item) => item.product.isAvailable
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
                .map((item) => '₹${item.trueCost.toStringAsFixed(0)}')
                .toList(),
            winnerId: result.lowestTrueCostProductId,
            products: result.products,
            last: true,
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: const BoxDecoration(color: ShopWiseColors.surfaceSoft),
      child: const Text(
        'Side-by-side comparison',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
            width: 104,
            child: Row(
              children: [
                Icon(icon, size: 17, color: ShopWiseColors.textMuted),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ShopWiseColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: List.generate(products.length, (index) {
                final product = products[index];
                final isWinner = product.product.id == winnerId;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
                    child: Text(
                      values[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isWinner
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: isWinner
                            ? ShopWiseColors.emerald
                            : ShopWiseColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.textPrimary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Make the smarter decision',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${winner.product.name} leads on overall Smart Score.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _DecisionMetric(
                  label: 'Best overall',
                  value: '${winner.smartScore.score.toStringAsFixed(0)}/100',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DecisionMetric(
                  label: 'Lowest true cost',
                  value: '₹${lowestCost.trueCost.toStringAsFixed(0)}',
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
                  color: ShopWiseColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
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
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
