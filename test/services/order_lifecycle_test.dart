import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/services/customer/order_lifecycle.dart';

void main() {
  group('OrderLifecycle', () {
    test('placed can become accepted', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.placed,
          OrderLifecycle.accepted,
        ),
        isTrue,
      );
    });

    test('placed can become cancelled', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.placed,
          OrderLifecycle.cancelled,
        ),
        isTrue,
      );
    });

    test('accepted can become completed', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.accepted,
          OrderLifecycle.completed,
        ),
        isTrue,
      );
    });

    test('accepted can become cancelled', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.accepted,
          OrderLifecycle.cancelled,
        ),
        isTrue,
      );
    });

    test('placed cannot become completed directly', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.placed,
          OrderLifecycle.completed,
        ),
        isFalse,
      );
    });

    test('completed cannot change status', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.completed,
          OrderLifecycle.accepted,
        ),
        isFalse,
      );

      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.completed,
          OrderLifecycle.cancelled,
        ),
        isFalse,
      );
    });

    test('cancelled cannot change status', () {
      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.cancelled,
          OrderLifecycle.accepted,
        ),
        isFalse,
      );

      expect(
        OrderLifecycle.canTransition(
          OrderLifecycle.cancelled,
          OrderLifecycle.completed,
        ),
        isFalse,
      );
    });

    test('invalid statuses are rejected', () {
      expect(
        OrderLifecycle.canTransition('pending', 'accepted'),
        isFalse,
      );

      expect(
        OrderLifecycle.canTransition('placed', 'pending'),
        isFalse,
      );
    });

    test('completed and cancelled are terminal', () {
      expect(OrderLifecycle.isTerminal('completed'), isTrue);
      expect(OrderLifecycle.isTerminal('cancelled'), isTrue);
      expect(OrderLifecycle.isTerminal('accepted'), isFalse);
      expect(OrderLifecycle.isTerminal('placed'), isFalse);
    });
  });
}
