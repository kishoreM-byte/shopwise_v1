import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../models/product.dart';
import '../../../../../services/customer/compare/nearby_compare_service.dart';
import '../../../../../services/customer/comparison_engine.dart';
import '../../../../../theme/design_tokens.dart';

class NearbyAlternativesSection extends StatelessWidget {
  const NearbyAlternativesSection({
    super.key,
    required this.selectedProduct,
    required this.alternatives,
    this.analysis,
    required this.compareIds,
    required this.onCompare,
    this.onOpenProduct,
    this.onRetryEstimates,
  });

  final Product selectedProduct;
  final List<NearbyCompareItem> alternatives;
  final NearbyComparisonAnalysis? analysis;
  final Set<String> compareIds;
  final Future<bool> Function(Product product) onCompare;
  final ValueChanged<Product>? onOpenProduct;
  final VoidCallback? onRetryEstimates;

  @override
  Widget build(BuildContext context) {
    final items = analysis?.items ?? alternatives;
    final selected = items.where((item) => item.isSelected).firstOrNull;
    final options = items.where((item) => !item.isSelected).toList();
    final hasIncompleteCosts = items.any(
      (item) =>
          item.product.isAvailableForPurchase &&
          item.costEstimate != null &&
          !item.costEstimate!.isComplete,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final useStackedCards = textScale > 1.2;
    final cardHeight = 500.0;
    if (alternatives.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ShopWiseColors.surfaceSoft,
          borderRadius: BorderRadius.circular(ShopWiseRadius.large),
          border: Border.all(color: ShopWiseColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ShopWiseColors.emeraldSoft,
                borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: ShopWiseColors.emeraldDeep,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No nearby alternatives yet',
                    style: TextStyle(
                      color: ShopWiseColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selected == null
                        ? 'No close name match with a verified shop location was found within $_radiusLabel km.'
                        : 'Your selected product is shown above; no other verified in-stock match is within $_radiusLabel km. Shops without coordinates cannot be confirmed nearby.',
                    style: const TextStyle(
                      color: ShopWiseColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart nearby comparison',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: ShopWiseColors.textPrimary,
            letterSpacing: -.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Comparable, in-stock products within $_radiusLabel km',
          style: TextStyle(fontSize: 13, color: ShopWiseColors.textSecondary),
        ),
        const SizedBox(height: 3),
        const Text(
          'Shop distance is straight-line. Cost totals use a separate round-trip road estimate.',
          style: TextStyle(fontSize: 11, color: ShopWiseColors.textMuted),
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          Text(
            'Your selected product',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ShopWiseColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _ComparisonSummary(
            items: items,
            hasComparableCosts: analysis?.hasComparableCosts ?? false,
            hasBestValueTie: analysis?.hasBestValueTie ?? false,
          ),
          if (hasIncompleteCosts) ...[
            const SizedBox(height: 8),
            NearbyComparisonStatusCard(
              title: 'Some cost estimates are incomplete',
              message:
                  'A road route or applicable shop charge is unavailable. Retry can refresh routes; unknown charges will stay excluded until the shop provides them.',
              actionLabel: onRetryEstimates == null ? null : 'Retry estimates',
              onAction: onRetryEstimates,
            ),
          ],
          const SizedBox(height: 10),
          _AlternativeCard(
            item: selected,
            isCompared: true,
            onCompare: () {},
            onOpenProduct: onOpenProduct,
          ),
          if (options.isEmpty) ...[
            const SizedBox(height: 10),
            NearbyComparisonStatusCard(
              title: 'No other nearby shops',
              message:
                  'No other name-matched, in-stock product with a verified shop location was confirmed within $_radiusLabel km. Shops without coordinates cannot be ranked nearby.',
            ),
          ],
          const SizedBox(height: 16),
        ],
        if (options.isNotEmpty) const SizedBox(height: 14),
        if (options.isNotEmpty && useStackedCards)
          ...options.map((item) {
            final isCompared = compareIds.contains(item.product.id);
            final requiredSlots =
                (compareIds.contains(selectedProduct.id) ? 0 : 1) +
                (isCompared ? 0 : 1);
            final isCompareFull =
                compareIds.length + requiredSlots >
                ComparisonEngine.maxProducts;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlternativeCard(
                item: item,
                isCompared: isCompared,
                isCompareFull: isCompareFull,
                onCompare: () => onCompare(item.product),
                onOpenProduct: onOpenProduct,
                width: double.infinity,
              ),
            );
          }),
        if (options.isNotEmpty && !useStackedCards)
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = options[index];
                final isCompared = compareIds.contains(item.product.id);
                final requiredSlots =
                    (compareIds.contains(selectedProduct.id) ? 0 : 1) +
                    (isCompared ? 0 : 1);
                final isCompareFull =
                    compareIds.length + requiredSlots >
                    ComparisonEngine.maxProducts;

                return _AlternativeCard(
                  item: item,
                  isCompared: isCompared,
                  isCompareFull: isCompareFull,
                  onCompare: () => onCompare(item.product),
                  onOpenProduct: onOpenProduct,
                );
              },
            ),
          ),
      ],
    );
  }

  String get _radiusLabel =>
      (analysis?.radiusKm ?? NearbyCompareService.defaultRadiusKm)
          .toStringAsFixed(0);
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.item,
    required this.isCompared,
    this.isCompareFull = false,
    required this.onCompare,
    this.onOpenProduct,
    this.width = 245,
  });

  final NearbyCompareItem item;
  final bool isCompared;
  final bool isCompareFull;
  final VoidCallback onCompare;
  final ValueChanged<Product>? onOpenProduct;
  final double width;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onOpenProduct == null ? null : () => onOpenProduct!(product),
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.isSelected
                  ? const [ShopWiseColors.emeraldSoft, ShopWiseColors.surface]
                  : const [ShopWiseColors.surface, ShopWiseColors.surfaceSoft],
            ),
            borderRadius: BorderRadius.circular(ShopWiseRadius.large),
            border: Border.all(
              color: item.isSelected
                  ? ShopWiseColors.emerald.withValues(alpha: .35)
                  : ShopWiseColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A10251E),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.imageUrls.isNotEmpty)
                      Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const _ImagePlaceholder(loading: true),
                      )
                    else
                      const _ImagePlaceholder(),
                    if (item.isSelected ||
                        item.isLowestListedPrice ||
                        item.isBestValue ||
                        item.isLowestEstimatedTotal)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            if (item.isSelected)
                              const _ComparisonBadge(
                                label: 'Selected',
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            if (item.isLowestListedPrice)
                              const _ComparisonBadge(
                                label: 'Lowest listed',
                                icon: Icons.sell_outlined,
                              ),
                            if (item.isBestValue)
                              const _ComparisonBadge(
                                label: 'Smart Pick',
                                icon: Icons.auto_awesome_rounded,
                                emphasized: true,
                              ),
                            if (item.isLowestEstimatedTotal)
                              const _ComparisonBadge(
                                label: 'Lowest total',
                                icon: Icons.savings_outlined,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                    const SizedBox(height: 4),
                    Text(
                      item.shop?.name ?? 'Shop details unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShopWiseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.price.isFinite && product.price > 0
                              ? '₹${product.price.toStringAsFixed(0)}'
                              : 'Price unavailable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: ShopWiseColors.emerald,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: ShopWiseColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.distanceKm == null
                                    ? 'Distance unavailable'
                                    : '${item.distanceKm!.toStringAsFixed(1)} km straight-line',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ShopWiseColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item.costEstimate != null) ...[
                      const SizedBox(height: 8),
                      _CostEstimateDetails(item: item),
                    ],
                    if (item.smartScore != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Smart Score ${item.smartScore!.score.round()}/100',
                        style: const TextStyle(
                          color: ShopWiseColors.emeraldDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: ShopWiseColors.warning,
                        ),
                        Text(
                          product.rating.isFinite &&
                                  product.rating > 0 &&
                                  product.rating <= 5 &&
                                  product.reviewCount > 0
                              ? product.rating.toStringAsFixed(1)
                              : 'No rating',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ShopWiseColors.textPrimary,
                          ),
                        ),
                        Text(
                          product.reviewCount > 0
                              ? '(${product.reviewCount} reviews)'
                              : '(no reviews)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: ShopWiseColors.textSecondary,
                          ),
                        ),
                        Text(
                          product.isAvailableForPurchase
                              ? 'In stock · ${product.stock}'
                              : 'Unavailable',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: product.isAvailable && product.stock > 0
                                ? ShopWiseColors.emerald
                                : ShopWiseColors.error,
                          ),
                        ),
                      ],
                    ),
                    if (product.hasOffer) ...[
                      const SizedBox(height: 3),
                      Text(
                        (product.offerText?.trim().isNotEmpty ?? false)
                            ? product.offerText!
                            : 'Offer available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ShopWiseColors.emerald,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        onPressed: isCompared || isCompareFull
                            ? null
                            : onCompare,
                        style: FilledButton.styleFrom(
                          backgroundColor: ShopWiseColors.emerald,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: ShopWiseColors.emeraldSoft,
                          disabledForegroundColor: ShopWiseColors.emeraldDeep,
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ShopWiseRadius.medium,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCompared
                                  ? Icons.check_circle_rounded
                                  : isCompareFull
                                  ? Icons.block_rounded
                                  : Icons.add_rounded,
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                item.isSelected
                                    ? 'Selected product'
                                    : isCompared
                                    ? 'Already added'
                                    : isCompareFull
                                    ? 'Compare limit reached'
                                    : 'Add to compare',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isCompareFull && !isCompared) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Remove an item from Compare to add this pair.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ShopWiseColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShopWiseColors.background,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ShopWiseColors.emerald,
                ),
              )
            : const Icon(
                Icons.image_outlined,
                color: ShopWiseColors.textSecondary,
                size: 30,
              ),
      ),
    );
  }
}

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({
    required this.label,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: emphasized ? ShopWiseColors.emerald : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ShopWiseColors.emerald.withValues(alpha: .2)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: emphasized ? Colors.white : ShopWiseColors.emeraldDeep,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: emphasized ? Colors.white : ShopWiseColors.emeraldDeep,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CostEstimateDetails extends StatelessWidget {
  const _CostEstimateDetails({required this.item});

  final NearbyCompareItem item;

  @override
  Widget build(BuildContext context) {
    final estimate = item.costEstimate!;
    final total = estimate.estimatedTotalCost;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: ShopWiseColors.background,
        borderRadius: BorderRadius.circular(ShopWiseRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == null
                ? 'Cost incomplete'
                : 'Estimated total · ₹${total.toStringAsFixed(0)}',
            style: TextStyle(
              color: total == null
                  ? ShopWiseColors.textSecondary
                  : ShopWiseColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            estimate.roadDistanceKm == null
                ? 'Road route unavailable'
                : estimate.travelCost == null
                ? 'One-way road route ${estimate.roadDistanceKm!.toStringAsFixed(1)} km · travel estimate unavailable'
                : 'One-way road route ${estimate.roadDistanceKm!.toStringAsFixed(1)} km · '
                      'round-trip travel ₹${estimate.travelCost!.toStringAsFixed(0)}',
            style: const TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          Text(
            'Delivery ${_chargeLabel(item.shop?.deliveryAvailable, estimate.deliveryCost)} · '
            'Installation ${_chargeLabel(item.shop?.installationAvailable, estimate.installationCost)}',
            style: const TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          if (total == null)
            Text(
              'Missing ${estimate.missingComponents.join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ShopWiseColors.textMuted,
                fontSize: 10,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }

  String _chargeLabel(bool? available, double? cost) {
    if (available == false) return 'not offered';
    if (cost == null) return 'unknown';
    return '₹${cost.toStringAsFixed(0)}';
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({
    required this.items,
    required this.hasComparableCosts,
    required this.hasBestValueTie,
  });

  final List<NearbyCompareItem> items;
  final bool hasComparableCosts;
  final bool hasBestValueTie;

  @override
  Widget build(BuildContext context) {
    final pricedItems = items
        .where(
          (item) =>
              item.product.price.isFinite &&
              item.product.price > 0 &&
              item.product.isAvailableForPurchase,
        )
        .toList(growable: false);
    if (pricedItems.isEmpty) {
      return const _SummarySurface(
        child: Text(
          'Listed prices are unavailable, so price and overall-value rankings cannot be made.',
          style: TextStyle(fontSize: 12, color: ShopWiseColors.textPrimary),
        ),
      );
    }

    final lowestPrice = pricedItems
        .map((item) => item.product.price)
        .reduce(math.min);
    final listedPriceLeaders = pricedItems
        .where((item) => (item.product.price - lowestPrice).abs() < 0.01)
        .toList(growable: false);
    final complete = items
        .where((item) => item.costEstimate?.estimatedTotalCost != null)
        .toList(growable: false);
    final lowestTotal = complete.isEmpty
        ? null
        : complete
              .map((item) => item.costEstimate!.estimatedTotalCost!)
              .reduce(math.min);
    final totalLeaders = lowestTotal == null
        ? const <NearbyCompareItem>[]
        : complete
              .where(
                (item) =>
                    (item.costEstimate!.estimatedTotalCost! - lowestTotal)
                        .abs() <
                    0.01,
              )
              .toList(growable: false);
    final smartPick = items.where((item) => item.isBestValue).firstOrNull;
    final hasIncomplete = items.any(
      (item) =>
          item.product.isAvailableForPurchase &&
          item.costEstimate != null &&
          !item.costEstimate!.isComplete,
    );

    return _SummarySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lowest listed price',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ShopWiseColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            listedPriceLeaders.length > 1
                ? 'Tie · ${listedPriceLeaders.map((item) => item.product.name).join(' / ')} · ₹${lowestPrice.toStringAsFixed(0)}'
                : '${listedPriceLeaders.first.product.name} · ₹${lowestPrice.toStringAsFixed(0)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ShopWiseColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Lowest estimated total cost',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ShopWiseColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            totalLeaders.isEmpty
                ? 'Unavailable until at least two complete estimates are ready.'
                : totalLeaders.length > 1
                ? 'Tie · ${totalLeaders.map((item) => item.product.name).join(' / ')} · ₹${lowestTotal!.toStringAsFixed(0)}'
                : '${totalLeaders.single.product.name} · ₹${lowestTotal!.toStringAsFixed(0)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ShopWiseColors.textPrimary,
            ),
          ),
          if (totalLeaders.isNotEmpty && hasIncomplete) ...[
            const SizedBox(height: 3),
            const Text(
              'Among complete estimates only; options with unknown costs are excluded.',
              style: TextStyle(
                fontSize: 10,
                color: ShopWiseColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Best overall value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ShopWiseColors.emeraldDeep,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            smartPick != null
                ? '${smartPick.product.name} · Smart Score ${smartPick.smartScore!.score.round()}/100'
                : hasBestValueTie
                ? 'Tie on Smart Score; no single pick.'
                : 'Not ranked because comparable costs are incomplete.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ShopWiseColors.textPrimary,
            ),
          ),
          if (smartPick?.smartScoreExplanation != null) ...[
            const SizedBox(height: 3),
            Text(
              '${smartPick!.smartScoreExplanation}. Existing ShopWise score includes price value, quality/reviews, availability, offer and the estimated additional costs.',
              style: const TextStyle(
                fontSize: 10,
                height: 1.35,
                color: ShopWiseColors.textSecondary,
              ),
            ),
          ] else if (items.length < 2) ...[
            const SizedBox(height: 3),
            const Text(
              'A nearby comparable product is needed before an overall pick can be made.',
              style: TextStyle(
                fontSize: 10,
                height: 1.35,
                color: ShopWiseColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            hasComparableCosts
                ? 'Estimate assumptions: OSRM round-trip shop visit using ${NearbyCompareService.travelAssumptions}; toll charges are not included. Known delivery/installation fees are added when offered. Choose your service options at checkout; this is an estimate, not a quote.'
                : 'Overall value is withheld until route and applicable shop charges are known for every option. Route failures are not treated as free travel.',
            style: const TextStyle(
              fontSize: 10,
              height: 1.35,
              color: ShopWiseColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySurface extends StatelessWidget {
  const _SummarySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ShopWiseColors.emerald.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
      border: Border.all(color: ShopWiseColors.emerald.withValues(alpha: .12)),
    ),
    child: child,
  );
}

class NearbyComparisonStatusCard extends StatelessWidget {
  const NearbyComparisonStatusCard({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(ShopWiseRadius.large),
        border: Border.all(color: ShopWiseColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E382B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ShopWiseColors.emeraldSoft,
              borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: ShopWiseColors.emerald,
                    ),
                  )
                : const Icon(
                    Icons.location_on_outlined,
                    color: ShopWiseColors.emeraldDeep,
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: ShopWiseColors.emeraldDeep,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
