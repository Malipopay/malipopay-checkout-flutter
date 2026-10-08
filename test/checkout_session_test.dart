import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:malipopay_checkout/malipopay_checkout.dart';
import 'package:malipopay_checkout/src/checkout_session.dart';

void main() {
  final checkout = Uri.parse(
    'https://app.malipopay.co.tz/c/abc/embed?amount=25000&order=O1',
  );
  final onPage = Uri.parse(
    'https://app.malipopay.co.tz/c/abc/embed?ref=MU00999&card=declined',
  );
  final bank = Uri.parse('https://acs.bank.example/challenge');

  late List<CheckoutResult> results;
  late CheckoutSession session;

  setUp(() {
    results = [];
    session = CheckoutSession(checkoutUri: checkout, onDone: results.add);
  });

  String msg(Map<String, Object?> body) =>
      jsonEncode({'source': 'malipopay-checkout', ...body});

  group('messages from the page', () {
    test('a paid result ends the checkout with the reference and receipt', () {
      session.onBridgeMessage(
        msg({
          'type': 'result',
          'reference': 'MU00999',
          'status': 'successful',
          'receiptUrl': 'https://app.malipopay.co.tz/r/x',
          'redirectUrl': null,
        }),
        currentUrl: onPage,
      );
      expect(results, hasLength(1));
      expect(results.single.status, CheckoutStatus.successful);
      expect(results.single.isSuccessful, isTrue);
      expect(results.single.reference, 'MU00999');
      expect(results.single.receiptUrl, 'https://app.malipopay.co.tz/r/x');
    });

    test(
      'cancel ends it as cancelled, keeping the reference the page already reported',
      () {
        session.onBridgeMessage(
          msg({'type': 'resize', 'height': 600}),
          currentUrl: onPage,
        );
        session.onBridgeMessage(
          msg({'type': 'cancel', 'reference': 'MU00999'}),
          currentUrl: onPage,
        );
        expect(results.single.status, CheckoutStatus.cancelled);
        expect(results.single.reference, 'MU00999');
      },
    );

    test(
      'only the checkout page can end it: a bank page posting the same message is ignored',
      () {
        session.onBridgeMessage(
          msg({'type': 'result', 'status': 'successful', 'reference': 'FAKE'}),
          currentUrl: bank,
        );
        session.onBridgeMessage(
          msg({'type': 'result', 'status': 'successful'}),
          currentUrl: null,
        );
        session.onBridgeMessage(
          msg({'type': 'result', 'status': 'successful'}),
          currentUrl: Uri.parse('http://app.malipopay.co.tz/c/abc/embed'),
        );
        expect(results, isEmpty);
      },
    );

    test('ignores anything that is not a Malipopay checkout message', () {
      session.onBridgeMessage('not json', currentUrl: onPage);
      session.onBridgeMessage('[1,2]', currentUrl: onPage);
      session.onBridgeMessage(
        jsonEncode({'type': 'result', 'status': 'successful'}),
        currentUrl: onPage,
      );
      session.onBridgeMessage(
        msg({'type': 'resize', 'height': 900}),
        currentUrl: onPage,
      );
      session.onBridgeMessage(msg({'type': 'expand'}), currentUrl: onPage);
      expect(results, isEmpty);
    });

    test('finishes exactly once', () {
      session.onBridgeMessage(
        msg({'type': 'result', 'status': 'failed'}),
        currentUrl: onPage,
      );
      session.onBridgeMessage(
        msg({'type': 'result', 'status': 'successful'}),
        currentUrl: onPage,
      );
      session.close();
      expect(results.single.status, CheckoutStatus.failed);
      expect(session.isDone, isTrue);
    });

    test(
      'reads every status the page sends; an unknown word is pending, never paid',
      () {
        for (final entry in {
          'successful': CheckoutStatus.successful,
          'partial': CheckoutStatus.partial,
          'failed': CheckoutStatus.failed,
          'pending': CheckoutStatus.pending,
          'weird': CheckoutStatus.pending,
        }.entries) {
          final got = <CheckoutResult>[];
          CheckoutSession(
            checkoutUri: checkout,
            onDone: got.add,
          ).onBridgeMessage(
            msg({'type': 'result', 'status': entry.key}),
            currentUrl: onPage,
          );
          expect(got.single.status, entry.value, reason: entry.key);
        }
      },
    );
  });

  group('navigation', () {
    test(
      'lets the checkout, the card fields and the bank 3-D Secure page load',
      () {
        expect(
          session.onNavigation(checkout, isMainFrame: true),
          NavigationVerdict.allow,
        );
        expect(
          session.onNavigation(bank, isMainFrame: true),
          NavigationVerdict.allow,
        );
        expect(
          session.onNavigation(
            Uri.parse('https://nmbbank.gateway.mastercard.com/form/x'),
            isMainFrame: false,
          ),
          NavigationVerdict.allow,
        );
        expect(
          session.onNavigation(Uri.parse('about:blank'), isMainFrame: false),
          NavigationVerdict.allow,
        );
        expect(results, isEmpty);
      },
    );

    test('blocks schemes a payment page has no business opening', () {
      for (final u in [
        'javascript:alert(1)',
        'intent://x#Intent;end',
        'file:///etc/hosts',
        'tel:0712345678',
        'about:blank',
      ]) {
        expect(
          session.onNavigation(Uri.parse(u), isMainFrame: true),
          NavigationVerdict.block,
          reason: u,
        );
      }
    });

    test(
      "the merchant's return address ends the checkout with its outcome instead of loading",
      () {
        final ret = Uri.parse(
          'https://shop.example/thanks?ref=MU00999&status=successful&order=O1',
        );
        expect(
          session.onNavigation(ret, isMainFrame: true),
          NavigationVerdict.block,
        );
        expect(results.single.status, CheckoutStatus.successful);
        expect(results.single.reference, 'MU00999');
        expect(results.single.redirectUrl, ret.toString());
      },
    );

    test(
      'the checkout reloading itself after 3-D Secure is not mistaken for a return',
      () {
        final back = Uri.parse(
          'https://app.malipopay.co.tz/c/abc/embed?ref=MU00999&status=successful',
        );
        expect(
          session.onNavigation(back, isMainFrame: true),
          NavigationVerdict.allow,
        );
        expect(results, isEmpty);
      },
    );
  });

  test('closing ends it as cancelled', () {
    session.close();
    expect(results.single.status, CheckoutStatus.cancelled);
    expect(results.single.isSuccessful, isFalse);
  });
}
