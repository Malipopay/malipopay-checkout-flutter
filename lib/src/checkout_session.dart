/// The rules between the checkout page and the app, apart from the WebView
/// so they can be tested without one.
library;

import 'dart:convert';

import 'checkout_result.dart';

/// The JavaScript channel the checkout page reports to inside the app.
const String bridgeName = 'MalipopayCheckoutApp';

/// Every message from the checkout page carries this source.
const String messageSource = 'malipopay-checkout';

/// What to do with a navigation the WebView is about to make.
enum NavigationVerdict {
  /// Let it load (the checkout, the card fields, the bank's 3-D Secure page).
  allow,

  /// Stop it (a scheme a payment page has no business opening, or the
  /// merchant's return address, which ends the checkout instead).
  block,
}

/// One visit to the checkout: reads the page's messages and navigations and
/// finishes exactly once.
class CheckoutSession {
  /// Starts a session for the checkout at [checkoutUri].
  CheckoutSession({required this.checkoutUri, required this.onDone});

  /// The address the WebView opened. Only pages on its host are believed.
  final Uri checkoutUri;

  /// Called once, with how the checkout ended.
  final void Function(CheckoutResult result) onDone;

  bool _done = false;
  String? _reference;

  /// True once the session has finished.
  bool get isDone => _done;

  /// The payment reference, once the page has reported one.
  String? get reference => _reference;

  /// A message the page posted to [bridgeName]. [currentUrl] is where the
  /// WebView is when it arrives: a message from any other host (a bank's
  /// 3-D Secure page, say) is ignored, so no other page can end the checkout.
  void onBridgeMessage(String raw, {required Uri? currentUrl}) {
    if (_done || !isCheckoutPage(currentUrl)) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    if (decoded['source'] != messageSource) return;
    final reference = decoded['reference'];
    if (reference is String && reference.isNotEmpty) _reference = reference;

    switch (decoded['type']) {
      case 'result':
        _finish(
          CheckoutResult(
            status: statusFromWire(decoded['status'] as String?),
            reference: _reference,
            receiptUrl: _text(decoded['receiptUrl']),
            redirectUrl: _text(decoded['redirectUrl']),
          ),
        );
      case 'cancel':
        _finish(CheckoutResult.cancelled(reference: _reference));
      default:
        // resize and expand are for iframes; the app's page fills the screen.
        break;
    }
  }

  /// Decides a navigation. Sub-frames (the card fields) are always allowed
  /// over http(s). A main-frame jump to an address carrying the outcome
  /// (`status` and `ref`) off the checkout host is the merchant's return
  /// address: the checkout ends with that outcome instead of loading it.
  NavigationVerdict onNavigation(Uri uri, {required bool isMainFrame}) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'about' || scheme == 'blob' || scheme == 'data') {
      return isMainFrame ? NavigationVerdict.block : NavigationVerdict.allow;
    }
    if (scheme != 'https' && scheme != 'http') return NavigationVerdict.block;
    if (!isMainFrame || isCheckoutPage(uri)) return NavigationVerdict.allow;

    final status = uri.queryParameters['status'];
    final ref = uri.queryParameters['ref'] ?? uri.queryParameters['reference'];
    if (status != null && ref != null && ref.isNotEmpty) {
      _reference = ref;
      _finish(
        CheckoutResult(
          status: statusFromWire(status),
          reference: ref,
          redirectUrl: uri.toString(),
        ),
      );
      return NavigationVerdict.block;
    }
    return NavigationVerdict.allow;
  }

  /// The payer closed the checkout (close button or back).
  void close() => _finish(CheckoutResult.cancelled(reference: _reference));

  /// True for a page on the checkout's own origin.
  bool isCheckoutPage(Uri? uri) =>
      uri != null &&
      uri.scheme == checkoutUri.scheme &&
      uri.host == checkoutUri.host &&
      uri.port == checkoutUri.port;

  void _finish(CheckoutResult result) {
    if (_done) return;
    _done = true;
    onDone(result);
  }
}

String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
