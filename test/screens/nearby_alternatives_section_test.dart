import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/models/shop.dart';
import 'package:shopwise_v1/screens/customer/widgets/compare/components/nearby_alternatives_section.dart';
import 'package:shopwise_v1/services/customer/compare/nearby_compare_service.dart';
import 'package:shopwise_v1/services/smart_score_service.dart';

Product _product(String id, String shopId, double price) => Product(
  id: id,
  shopId: shopId,
  ownerId: 'owner-$shopId',
  name: id == 'selected' ? 'Oak Dining Table' : 'Modern Dining Table $id',
  category: 'Furniture',
  description: '',
  price: price,
  stock: 3,
  isAvailable: true,
  imageUrls: const [],
  rating: 4.2,
  reviewCount: 6,
  hasOffer: false,
);

Shop _shop(String id) => Shop(
  id: id,
  ownerId: 'owner-$id',
  name: 'Shop $id',
  category: 'Furniture',
  description: '',
  address: '',
  phone: '',
  latitude: 0,
  longitude: 0,
  rating: 4,
  reviewCount: 1,
  isOpen: true,
);

void main() {
  testWidgets('labels listed price and Smart Pick separately and adds item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selected = _product('selected', 'shop-1', 15000);
    final alternative = _product('alternative', 'shop-2', 12000);
    const scoreService = SmartScoreService();
    final selectedEstimate = NearbyCostEstimate(
      productPrice: selected.price,
      roadDistanceKm: 5,
      travelCost: 70,
      deliveryCost: 0,
      installationCost: 0,
    );
    final alternativeEstimate = NearbyCostEstimate(
      productPrice: alternative.price,
      roadDistanceKm: 8,
      travelCost: 112,
      deliveryCost: 0,
      installationCost: 0,
    );
    final score = scoreService.calculate(selected, travelCost: 70);
    var adds = 0;
    Product? openedProduct;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: NearbyAlternativesSection(
                selectedProduct: selected,
                alternatives: [
                  NearbyCompareItem(
                    product: selected,
                    shop: _shop('shop-1'),
                    distanceKm: 1.1,
                    isSelected: true,
                    costEstimate: selectedEstimate,
                    smartScore: score,
                    smartScoreExplanation: score.componentSummary,
                  ),
                  NearbyCompareItem(
                    product: alternative,
                    shop: _shop('shop-2'),
                    distanceKm: 2.2,
                    costEstimate: alternativeEstimate,
                  ),
                ],
                analysis: NearbyComparisonAnalysis(
                  items: [
                    NearbyCompareItem(
                      product: selected,
                      shop: _shop('shop-1'),
                      distanceKm: 1.1,
                      isSelected: true,
                      costEstimate: selectedEstimate,
                      smartScore: score,
                      smartScoreExplanation: score.componentSummary,
                      isLowestEstimatedTotal: true,
                      isBestValue: true,
                    ),
                    NearbyCompareItem(
                      product: alternative,
                      shop: _shop('shop-2'),
                      distanceKm: 2.2,
                      costEstimate: alternativeEstimate,
                      smartScore: scoreService.calculate(
                        alternative,
                        travelCost: 112,
                      ),
                      isLowestListedPrice: true,
                    ),
                  ],
                  hasComparableCosts: true,
                  hasBestValueTie: false,
                  radiusKm: 20,
                ),
                compareIds: const {},
                onCompare: (_) async {
                  adds++;
                  return true;
                },
                onOpenProduct: (product) => openedProduct = product,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lowest listed price'), findsOneWidget);
    expect(find.text('Best overall value'), findsOneWidget);
    expect(find.text('Lowest listed'), findsOneWidget);
    expect(find.textContaining('Smart Score'), findsWidgets);
    expect(find.textContaining('OSRM round-trip shop visit'), findsOneWidget);
    expect(find.text('2.2 km straight-line'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text(alternative.name));
    await tester.tap(find.text(alternative.name));
    expect(openedProduct, same(alternative));

    await tester.ensureVisible(find.text('Add to compare'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to compare'));
    await tester.pump();
    expect(adds, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disables add when the selected pair would exceed four products',
    (tester) async {
      final selected = _product('selected', 'shop-1', 15000);
      final alternative = _product('alternative', 'shop-2', 12000);
      var adds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NearbyAlternativesSection(
                selectedProduct: selected,
                alternatives: [
                  NearbyCompareItem(
                    product: selected,
                    shop: _shop('shop-1'),
                    distanceKm: 1,
                    isSelected: true,
                  ),
                  NearbyCompareItem(
                    product: alternative,
                    shop: _shop('shop-2'),
                    distanceKm: 2,
                  ),
                ],
                compareIds: const {'selected', 'other-1', 'other-2', 'other-3'},
                onCompare: (_) async {
                  adds++;
                  return true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Compare limit reached'),
      );
      expect(button.onPressed, isNull);
      expect(adds, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retryable status card invokes its retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NearbyComparisonStatusCard(
            title: 'Could not load nearby options',
            message: 'Check your connection and retry.',
            actionLabel: 'Try again',
            onAction: () => retries++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading status exposes progress without losing the message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NearbyComparisonStatusCard(
            title: 'Finding nearby shops',
            message: 'Calculating available route estimates.',
            isLoading: true,
          ),
        ),
      ),
    );
    expect(find.text('Finding nearby shops'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incomplete costs show a route retry affordance', (tester) async {
    final selected = _product('selected', 'shop-1', 15000);
    final alternative = _product('alternative', 'shop-2', 12000);
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NearbyAlternativesSection(
              selectedProduct: selected,
              alternatives: [
                NearbyCompareItem(
                  product: selected,
                  shop: _shop('shop-1'),
                  distanceKm: 1,
                  isSelected: true,
                  costEstimate: const NearbyCostEstimate(
                    productPrice: 15000,
                    roadDistanceKm: null,
                    travelCost: null,
                    deliveryCost: 0,
                    installationCost: 0,
                  ),
                ),
                NearbyCompareItem(
                  product: alternative,
                  shop: _shop('shop-2'),
                  distanceKm: 2,
                ),
              ],
              compareIds: const {},
              onCompare: (_) async => true,
              onRetryEstimates: () => retries++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cost incomplete'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry estimates'));
    await tester.tap(find.text('Retry estimates'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing travel cost with a known route does not crash', (
    tester,
  ) async {
    final selected = _product('selected', 'shop-1', 15000);
    final alternative = _product('alternative', 'shop-2', 12000);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NearbyAlternativesSection(
              selectedProduct: selected,
              alternatives: [
                NearbyCompareItem(
                  product: selected,
                  shop: _shop('shop-1'),
                  distanceKm: 1,
                  isSelected: true,
                  costEstimate: const NearbyCostEstimate(
                    productPrice: 15000,
                    roadDistanceKm: 5,
                    travelCost: null,
                    deliveryCost: 0,
                    installationCost: 0,
                  ),
                ),
                NearbyCompareItem(
                  product: alternative,
                  shop: _shop('shop-2'),
                  distanceKm: 2,
                ),
              ],
              compareIds: const {},
              onCompare: (_) async => true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('travel estimate unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows already-added feedback and disables duplicate action', (
    tester,
  ) async {
    final selected = _product('selected', 'shop-1', 15000);
    final alternative = _product('alternative', 'shop-2', 12000);
    var adds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NearbyAlternativesSection(
              selectedProduct: selected,
              alternatives: [
                NearbyCompareItem(
                  product: selected,
                  shop: _shop('shop-1'),
                  distanceKm: null,
                  isSelected: true,
                ),
                NearbyCompareItem(
                  product: alternative,
                  shop: _shop('shop-2'),
                  distanceKm: 2.2,
                ),
              ],
              compareIds: const {'alternative'},
              onCompare: (_) async {
                adds++;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Already added'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Distance unavailable'), findsOneWidget);
    expect(adds, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains when only the selected product is available', (
    tester,
  ) async {
    final selected = _product('selected', 'shop-1', 15000);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NearbyAlternativesSection(
              selectedProduct: selected,
              alternatives: [
                NearbyCompareItem(
                  product: selected,
                  shop: _shop('shop-1'),
                  distanceKm: 1,
                  isSelected: true,
                ),
              ],
              compareIds: const {},
              onCompare: (_) async => false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No other nearby shops'), findsOneWidget);
    expect(
      find.textContaining('A nearby comparable product is needed'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
