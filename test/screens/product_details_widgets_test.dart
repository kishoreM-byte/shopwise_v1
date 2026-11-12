import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/screens/customer/widgets/product_gallery.dart';
import 'package:shopwise_v1/screens/customer/widgets/product_info.dart';
import 'package:shopwise_v1/screens/customer/widgets/travel_cost_card.dart';
import 'package:shopwise_v1/screens/customer/widgets/smart_score_card.dart';

Product _product({int reviewCount = 0}) => Product(
  id: 'p1',
  shopId: 's1',
  ownerId: 'o1',
  name: 'Classic oak dining table with an extendable leaf',
  category: 'Dining',
  description: 'Solid oak.',
  price: 24999,
  originalPrice: 29999,
  stock: 2,
  isAvailable: true,
  imageUrls: const [],
  rating: 0,
  reviewCount: reviewCount,
  hasOffer: false,
);

void main() {
  testWidgets('product summary fits narrow screens and labels no reviews', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductInfo(product: _product()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('No reviews yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty product gallery uses a responsive branded placeholder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductGallery(imageUrls: [' ', ''])),
      ),
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.getSize(find.byIcon(Icons.inventory_2_outlined)).height, 64);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product gallery ignores malformed image URLs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductGallery(
            imageUrls: ['javascript:alert(1)', 'https:///missing-host.jpg'],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product gallery returns to first image when URLs change', (
    tester,
  ) async {
    const firstImages = [
      'https://images.example/first-a.jpg',
      'https://images.example/first-b.jpg',
    ];
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductGallery(imageUrls: firstImages)),
      ),
    );
    await tester.pump();

    final initialController = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    initialController.jumpToPage(1);
    await tester.pump();
    expect(initialController.page, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductGallery(
            imageUrls: [
              'https://images.example/second-a.jpg',
              'https://images.example/second-b.jpg',
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final updatedController = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(updatedController.page, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('travel cost stays unavailable until distance is supplied', (
    tester,
  ) async {
    double? reportedCost = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelCostCard(onCostChanged: (cost) => reportedCost = cost),
        ),
      ),
    );
    await tester.pump();

    expect(reportedCost, isNull);
    expect(
      find.text('Enter a one-way distance to estimate travel cost.'),
      findsOneWidget,
    );
    expect(find.text('Estimated travel cost'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'One-way km'), '12');
    await tester.pump();

    expect(reportedCost, isNotNull);
    expect(find.text('Estimated travel cost'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed route clears stale automatic distance and cost', (
    tester,
  ) async {
    double? reportedCost = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelCostCard(
            routeDistanceKm: 12,
            onCostChanged: (cost) => reportedCost = cost,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(reportedCost, isNotNull);
    expect(find.text('Actual road km'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelCostCard(
            routeDistanceError: 'Route unavailable',
            onCostChanged: (cost) => reportedCost = cost,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(reportedCost, isNull);
    expect(
      find.text('Enter a one-way distance to estimate travel cost.'),
      findsOneWidget,
    );
    expect(find.text('Estimated travel cost'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading route clears previously reported travel cost', (
    tester,
  ) async {
    double? reportedCost = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelCostCard(
            routeDistanceKm: 12,
            onCostChanged: (cost) => reportedCost = cost,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(reportedCost, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelCostCard(
            routeDistanceKm: 12,
            isRouteDistanceLoading: true,
            onCostChanged: (cost) => reportedCost = cost,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(reportedCost, isNull);
    expect(find.text('Calculating the actual road distance…'), findsOneWidget);
    expect(find.text('Estimated travel cost'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual distance remains usable when route lookup fails', (
    tester,
  ) async {
    double? reportedCost;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TravelCostCard(
            routeDistanceError: 'Route unavailable',
            onCostChanged: (cost) => reportedCost = cost,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'One-way km'), '8');
    await tester.pump();

    expect(reportedCost, isNotNull);
    expect(
      find.text('Using manual distance because the road route is unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Estimated travel cost'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('true cost is marked incomplete without route or shop inputs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SmartScoreCard(product: _product()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Known subtotal'), findsOneWidget);
    expect(find.text('Incomplete'), findsOneWidget);
    expect(
      find.text('Some costs are unavailable, so this is a subtotal.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
