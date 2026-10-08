/// Malipopay hosted checkout for Flutter.
///
/// ```dart
/// final result = await MalipopayCheckout.open(
///   context,
///   integration: 'YOUR_CHECKOUT_ID',
///   amount: 25000,
///   order: 'ORDER-42',
/// );
/// if (result.status == CheckoutStatus.successful) {
///   // Confirm on your server before you deliver.
/// }
/// ```
library;

export 'src/checkout_link.dart'
    show
        CheckoutEnvironment,
        CheckoutPayer,
        SignedLink,
        checkoutBase,
        checkoutUri;
export 'src/checkout_result.dart' show CheckoutResult, CheckoutStatus;
export 'src/checkout_view.dart'
    show MalipopayCheckoutView, MalipopayCheckoutViewState;
export 'src/malipopay_checkout.dart'
    show MalipopayCheckout, CheckoutViewBuilder;
