import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/screens/customer/widgets/home/home_quick_actions.dart';
import 'package:shopwise_v1/screens/shop_owner/shop_owner_dashboard.dart';

void main() {
  testWidgets('home quick actions fit narrow screens and remain tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? selectedAction;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HomeQuickActions(
                onCompare: () => selectedAction = 'Compare',
                onWishlist: () => selectedAction = 'Wishlist',
                onEnquiries: () => selectedAction = 'Enquiries',
                onOrders: () => selectedAction = 'Orders',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Enquiries'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Orders'));
    expect(selectedAction, 'Orders');
  });

  testWidgets('dashboard shows a retry state when shop loading fails', (
    tester,
  ) async {
    var loadAttempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ShopOwnerDashboard(
          loadShop: () async {
            loadAttempts++;
            if (loadAttempts == 1) {
              throw StateError('offline');
            }

            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shop details unavailable'), findsOneWidget);
    expect(find.text('Set up your shop'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(loadAttempts, 2);
    expect(find.text('Set up your shop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
