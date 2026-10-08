/// The one call most apps need.
library;

import 'package:flutter/material.dart';

import 'checkout_link.dart';
import 'checkout_result.dart';
import 'checkout_view.dart';

/// Builds the view the checkout route shows. Tests swap the WebView out.
typedef CheckoutViewBuilder =
    Widget Function(
      BuildContext context,
      Uri uri,
      ValueChanged<CheckoutResult> onResult,
    );

/// Opens the Malipopay hosted checkout.
abstract final class MalipopayCheckout {
  /// Opens the checkout for [integration] full screen and returns how it
  /// ended. The payer pays by card or mobile money on the Malipopay page;
  /// card numbers go straight to the bank and never pass through the app.
  ///
  /// - [amount] and [order]: what to charge and your own order id. Paying the
  ///   same [order] again continues the same payment instead of charging twice.
  /// - [signed]: required when the checkout only takes signed links. Make it
  ///   on your server; never ship the signing secret in an app.
  /// - [payer]: lets the page skip asking for name and phone.
  /// - [language]: `en` or `sw`.
  /// - [environment] or [baseUrl]: where the checkout is served.
  ///
  /// Closing the checkout or pressing back returns
  /// [CheckoutStatus.cancelled]. Confirm every payment on your server before
  /// you deliver.
  static Future<CheckoutResult> open(
    BuildContext context, {
    required String integration,
    num? amount,
    String? order,
    String? currency,
    String? description,
    String? returnUrl,
    SignedLink? signed,
    CheckoutPayer? payer,
    String? language,
    CheckoutEnvironment environment = CheckoutEnvironment.production,
    Uri? baseUrl,
    String title = 'Payment',
    @visibleForTesting CheckoutViewBuilder? viewBuilder,
  }) async {
    final uri = checkoutUri(
      base: baseUrl ?? checkoutBase(environment),
      integration: integration,
      amount: amount,
      order: order,
      currency: currency,
      description: description,
      returnUrl: returnUrl,
      signed: signed,
      payer: payer,
      language: language,
    );
    final result = await Navigator.of(context).push<CheckoutResult>(
      MaterialPageRoute<CheckoutResult>(
        fullscreenDialog: true,
        builder: (_) =>
            _CheckoutPage(uri: uri, title: title, viewBuilder: viewBuilder),
      ),
    );
    return result ?? const CheckoutResult.cancelled();
  }
}

class _CheckoutPage extends StatefulWidget {
  const _CheckoutPage({
    required this.uri,
    required this.title,
    this.viewBuilder,
  });

  final Uri uri;
  final String title;
  final CheckoutViewBuilder? viewBuilder;

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage> {
  final _view = GlobalKey<MalipopayCheckoutViewState>();
  bool _popped = false;

  void _done(CheckoutResult result) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(result);
  }

  void _close() {
    final view = _view.currentState;
    if (view != null) {
      view.close();
    } else {
      _done(const CheckoutResult.cancelled());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: _close,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: widget.viewBuilder != null
              ? widget.viewBuilder!(context, widget.uri, _done)
              : MalipopayCheckoutView(
                  key: _view,
                  uri: widget.uri,
                  onResult: _done,
                ),
        ),
      ),
    );
  }
}
