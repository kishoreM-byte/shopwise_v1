import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/screens/customer/widgets/home/home_saved_products.dart';
import 'package:shopwise_v1/services/product_service.dart';

class _SignedOutAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RetryProductService extends ProductService {
  _RetryProductService()
    : super(firestore: FakeFirebaseFirestore(), auth: _SignedOutAuth());

  int watchCount = 0;

  @override
  Stream<List<Product>> watchProductsByIds(Set<String> productIds) {
    watchCount++;
    if (watchCount == 1) return Stream.error(StateError('offline'));
    return Stream.value(<Product>[_savedProduct]);
  }
}

const _savedProduct = Product(
  id: 'chair-1',
  shopId: 'shop-1',
  ownerId: 'owner-1',
  name: 'Classic chair',
  category: 'Chair',
  description: '',
  price: 1200,
  stock: 2,
  isAvailable: true,
  imageUrls: <String>[],
  rating: 4.5,
  reviewCount: 3,
  hasOffer: false,
);

void main() {
  testWidgets('saved products can retry after an error and be removed', (
    tester,
  ) async {
    final productService = _RetryProductService();
    String? removedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSavedProducts(
            ids: const <String>{'chair-1'},
            icon: Icons.favorite_rounded,
            title: 'Your Wishlist',
            emptySubtitle: 'Products you save will appear here.',
            compareIds: const <String>{},
            wishlistIds: const <String>{'chair-1'},
            productService: productService,
            onRemoveWishlist: (id) async => removedId = id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved products unavailable'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Classic chair'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(removedId, 'chair-1');
  });
}
