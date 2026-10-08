import 'package:flutter_test/flutter_test.dart';
import 'package:malipopay_checkout/malipopay_checkout.dart';

void main() {
  group('the checkout address', () {
    test('opens the embed path on the environment, with the merchant values', () {
      final uri = checkoutUri(
        base: checkoutBase(CheckoutEnvironment.production),
        integration: '6703f2c41f0a3b2d9c8e7a11',
        amount: 25000,
        order: 'ORDER-42',
      );
      // Same address the web embed script builds (src/embed/checkoutHelpers.js).
      expect(
        uri.toString(),
        'https://app.malipopay.co.tz/c/6703f2c41f0a3b2d9c8e7a11/embed?amount=25000&order=ORDER-42',
      );
    });

    test('UAT is the demo portal', () {
      expect(
        checkoutBase(CheckoutEnvironment.uat).host,
        'demo.malipopay.co.tz',
      );
    });

    test(
      'writes whole amounts without a decimal, because the server signs the text',
      () {
        final uri = checkoutUri(
          base: Uri.parse('https://x.test'),
          integration: 'abc',
          amount: 1500.0,
        );
        expect(uri.queryParameters['amount'], '1500');
        expect(
          checkoutUri(
            base: Uri.parse('https://x.test'),
            integration: 'abc',
            amount: 99.5,
          ).queryParameters['amount'],
          '99.5',
        );
      },
    );

    test(
      'carries a signed link, the payer and the language, and leaves out empties',
      () {
        final uri = checkoutUri(
          base: Uri.parse('https://app.malipopay.co.tz'),
          integration: 'abc',
          amount: 25000,
          order: '',
          returnUrl: 'https://shop.example/thanks',
          signed: const SignedLink(sig: 'deadbeef', exp: 1800000000),
          payer: const CheckoutPayer(name: 'Amina Juma', phone: '0712345678'),
          language: 'sw',
        );
        expect(uri.queryParameters, {
          'amount': '25000',
          'returnUrl': 'https://shop.example/thanks',
          'exp': '1800000000',
          'sig': 'deadbeef',
          'name': 'Amina Juma',
          'phone': '0712345678',
          'lang': 'sw',
        });
      },
    );

    test('refuses to build without a checkout id', () {
      expect(
        () => checkoutUri(base: Uri.parse('https://x.test'), integration: ' '),
        throwsArgumentError,
      );
    });
  });
}
