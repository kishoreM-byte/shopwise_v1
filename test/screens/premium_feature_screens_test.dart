import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/screens/customer/best_deals_screen.dart';
import 'package:shopwise_v1/screens/shop_owner/shop_analytics_screen.dart';
import 'package:shopwise_v1/theme/app_theme.dart';

void main() {
  testWidgets('Best Deals distinguishes stream failure and retries', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BestDealsScreen(
          watchProducts: () {
            attempts++;
            return attempts == 1
                ? Stream<List<Product>>.error(StateError('offline'))
                : Stream.value([]);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Deals are unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('No active deals'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Analytics shows an empty catalogue state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ShopAnalyticsScreen(
          watchProducts: () => Stream<List<Product>>.value(const []),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No products yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Analytics exposes retry after a stream failure', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ShopAnalyticsScreen(
          watchProducts: () {
            attempts++;
            return attempts == 1
                ? Stream<List<Product>>.error(StateError('offline'))
                : Stream<List<Product>>.value(const []);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Analytics unavailable'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('No products yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Analytics metrics fit narrow screens at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const product = Product(
      id: 'table-1',
      shopId: 'shop-1',
      ownerId: 'owner-1',
      name: 'Oak table',
      category: 'Table',
      description: '',
      price: 1000,
      stock: 2,
      isAvailable: true,
      imageUrls: [],
      rating: 0,
      reviewCount: 0,
      hasOffer: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: ShopAnalyticsScreen(
          watchProducts: () => Stream<List<Product>>.value(const [product]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
