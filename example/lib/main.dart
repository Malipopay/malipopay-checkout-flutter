import 'package:flutter/material.dart';
import 'package:malipopay_checkout/malipopay_checkout.dart';

// Your checkout id is in the Malipopay portal under Settings, Checkout.
//   flutter run --dart-define=CHECKOUT_ID=<id> --dart-define=MALIPOPAY_ENV=uat
const checkoutId = String.fromEnvironment(
  'CHECKOUT_ID',
  defaultValue: 'YOUR_CHECKOUT_ID',
);
const environment = String.fromEnvironment(
  'MALIPOPAY_ENV',
  defaultValue: 'production',
);

void main() => runApp(const ExampleApp());

/// A shop screen with one order and a Pay button.
class ExampleApp extends StatelessWidget {
  /// Creates the example.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malipopay checkout example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0055E2),
        useMaterial3: true,
      ),
      home: const OrderScreen(),
    );
  }
}

/// One order, paid through the Malipopay checkout.
class OrderScreen extends StatefulWidget {
  /// Creates the order screen.
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // One order id per order: paying it again continues the same payment.
  final String _order = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
  CheckoutResult? _result;

  Future<void> _pay() async {
    final result = await MalipopayCheckout.open(
      context,
      integration: checkoutId,
      amount: 1000,
      order: _order,
      environment: environment == 'uat'
          ? CheckoutEnvironment.uat
          : CheckoutEnvironment.production,
    );
    if (!mounted) return;
    // The app shows what the payer saw. Your server confirms the payment
    // (webhook or GET /payment/verify/:reference) before you deliver.
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Your order')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Order $_order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('2 x Coffee beans, TZS 1,000'),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('pay'),
              onPressed: _pay,
              child: const Text('Pay TZS 1,000'),
            ),
            if (r != null) ...[
              const SizedBox(height: 24),
              Text(
                'Status: ${r.status.name}',
                key: const Key('status'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (r.reference != null)
                Text('Reference: ${r.reference}', key: const Key('reference')),
              if (r.receiptUrl != null) Text('Receipt: ${r.receiptUrl}'),
            ],
          ],
        ),
      ),
    );
  }
}
