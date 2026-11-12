import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/screens/customer/widgets/home/home_product_results.dart';

void main() {
  testWidgets('product cards fit a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const product = Product(
      id: 'chair-1',
      shopId: 'shop-1',
      ownerId: 'owner-1',
      name: 'Classic solid wood dining chair with woven seat',
      category: 'Furniture',
      description: 'A crafted chair for everyday use.',
      price: 12999,
      originalPrice: 15999,
      stock: 4,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 4.8,
      reviewCount: 128,
      hasOffer: true,
      offerText: 'Delivery included this week',
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: MaterialApp(
          home: Scaffold(
            body: HomeProductResults(
              products: const <Product>[product],
              shopsById: const {},
              searchQuery: '',
              selectedCategory: null,
              minPrice: null,
              maxPrice: null,
              availableOnly: false,
              sortOption: ProductSortOption.recommended,
              onSortChanged: (_) {},
              onClearSearchAndFilters: () {},
              onEmptyState:
                  ({
                    required IconData icon,
                    required String title,
                    required String subtitle,
                  }) => Center(child: Text(title)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(product.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normalized search and category filters combine correctly', (
    tester,
  ) async {
    const matching = Product(
      id: 'chair',
      shopId: 'shop',
      ownerId: 'owner',
      name: '  Oak Chair  ',
      category: ' Furniture ',
      description: 'Solid timber',
      price: 300,
      stock: 2,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 4,
      reviewCount: 12,
      hasOffer: false,
    );
    const differentCategory = Product(
      id: 'lamp',
      shopId: 'shop',
      ownerId: 'owner',
      name: 'Oak lamp',
      category: 'Lighting',
      description: '',
      price: 150,
      stock: 2,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 0,
      reviewCount: 0,
      hasOffer: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeProductResults(
            products: const <Product>[matching, differentCategory],
            shopsById: const {},
            searchQuery: '  oAk  ',
            selectedCategory: ' furniture ',
            minPrice: 250,
            maxPrice: 350,
            availableOnly: true,
            sortOption: ProductSortOption.recommended,
            onSortChanged: (_) {},
            onClearSearchAndFilters: () {},
            onEmptyState:
                ({required icon, required title, required subtitle}) =>
                    Text(title),
          ),
        ),
      ),
    );

    expect(find.text('1 product'), findsOneWidget);
    expect(find.text('Oak Chair'), findsOneWidget);
    expect(find.text('Oak lamp'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('price and rating sorting keep unreviewed items last', (
    tester,
  ) async {
    const lowRated = Product(
      id: 'low-rated',
      shopId: 'shop',
      ownerId: 'owner',
      name: 'Oak Chair lower rated',
      category: 'Furniture',
      description: '',
      price: 300,
      stock: 1,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 3.5,
      reviewCount: 4,
      hasOffer: false,
    );
    const noRating = Product(
      id: 'unrated',
      shopId: 'shop',
      ownerId: 'owner',
      name: 'Oak Chair unrated',
      category: 'Furniture',
      description: '',
      price: 400,
      stock: 1,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 0,
      reviewCount: 0,
      hasOffer: false,
    );
    const highRated = Product(
      id: 'high-rated',
      shopId: 'shop',
      ownerId: 'owner',
      name: 'Oak Chair top rated',
      category: 'Furniture',
      description: '',
      price: 500,
      stock: 1,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 4.9,
      reviewCount: 20,
      hasOffer: false,
    );

    var sortOption = ProductSortOption.priceLowToHigh;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: HomeProductResults(
              products: const <Product>[noRating, highRated, lowRated],
              shopsById: const {},
              searchQuery: '',
              selectedCategory: null,
              minPrice: null,
              maxPrice: null,
              availableOnly: false,
              sortOption: sortOption,
              onSortChanged: (option) => setState(() => sortOption = option),
              onClearSearchAndFilters: () {},
              onEmptyState:
                  ({required icon, required title, required subtitle}) =>
                      Text(title),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double top(String name) => tester.getTopLeft(find.text(name)).dy;

    expect(top('Oak Chair lower rated'), lessThan(top('Oak Chair unrated')));
    expect(top('Oak Chair unrated'), lessThan(top('Oak Chair top rated')));

    await tester.tap(find.byTooltip('Sort products'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: high to low'));
    await tester.pumpAndSettle();

    expect(top('Oak Chair top rated'), lessThan(top('Oak Chair unrated')));
    expect(top('Oak Chair unrated'), lessThan(top('Oak Chair lower rated')));

    await tester.tap(find.byTooltip('Sort products'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top rated'));
    await tester.pumpAndSettle();

    expect(top('Oak Chair top rated'), lessThan(top('Oak Chair lower rated')));
    expect(top('Oak Chair lower rated'), lessThan(top('Oak Chair unrated')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty filtered results offer a clear search action', (
    tester,
  ) async {
    var clearPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeProductResults(
            products: const <Product>[],
            shopsById: const {},
            searchQuery: 'desk',
            selectedCategory: null,
            minPrice: null,
            maxPrice: null,
            availableOnly: false,
            sortOption: ProductSortOption.recommended,
            onSortChanged: (_) {},
            onClearSearchAndFilters: () => clearPressed = true,
            onEmptyState:
                ({required icon, required title, required subtitle}) =>
                    Text(title),
          ),
        ),
      ),
    );

    expect(find.text('0 products'), findsOneWidget);
    expect(find.text('No matching products'), findsOneWidget);
    await tester.tap(find.text('Clear search and filters'));
    expect(clearPressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
