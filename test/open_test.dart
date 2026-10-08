import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malipopay_checkout/malipopay_checkout.dart';

void main() {
  testWidgets('returns what the page reports and closes', (tester) async {
    late Uri opened;
    CheckoutResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await MalipopayCheckout.open(
                context,
                integration: 'abc',
                amount: 25000,
                order: 'ORDER-42',
                environment: CheckoutEnvironment.uat,
                viewBuilder: (ctx, uri, onResult) {
                  opened = uri;
                  return TextButton(
                    onPressed: () => onResult(
                      const CheckoutResult(
                        status: CheckoutStatus.successful,
                        reference: 'MU00999',
                      ),
                    ),
                    child: const Text('page says paid'),
                  );
                },
              );
            },
            child: const Text('Pay'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(
      opened.toString(),
      'https://demo.malipopay.co.tz/c/abc/embed?amount=25000&order=ORDER-42',
    );

    await tester.tap(find.text('page says paid'));
    await tester.pumpAndSettle();
    expect(find.text('page says paid'), findsNothing);
    expect(result?.status, CheckoutStatus.successful);
    expect(result?.reference, 'MU00999');
  });

  testWidgets('the close button returns cancelled', (tester) async {
    CheckoutResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await MalipopayCheckout.open(
                context,
                integration: 'abc',
                viewBuilder: (ctx, uri, onResult) => const Text('checkout'),
              );
            },
            child: const Text('Pay'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('checkout'), findsNothing);
    expect(result?.status, CheckoutStatus.cancelled);
  });

  testWidgets('back returns cancelled', (tester) async {
    CheckoutResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await MalipopayCheckout.open(
                context,
                integration: 'abc',
                viewBuilder: (ctx, uri, onResult) => const Text('checkout'),
              );
            },
            child: const Text('Pay'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('checkout'), findsNothing);
    expect(result?.status, CheckoutStatus.cancelled);
  });
}
