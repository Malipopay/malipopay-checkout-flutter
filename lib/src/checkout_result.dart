/// What the checkout tells the app when it closes.
library;

/// How the checkout ended.
enum CheckoutStatus {
  /// Paid in full.
  successful,

  /// Paid in part; the rest is still owed on the same reference.
  partial,

  /// Started but not confirmed yet (for example the payer left while the
  /// network was still confirming). Check on your server.
  pending,

  /// The payment did not go through.
  failed,

  /// The payer closed the checkout or chose to go back.
  cancelled,
}

/// The outcome the app gets back from [MalipopayCheckout.open].
///
/// This is what the payer's device saw. Always confirm on your server (the
/// webhook, or `GET /payment/verify/:reference`) before you deliver.
class CheckoutResult {
  /// Creates a result.
  const CheckoutResult({
    required this.status,
    this.reference,
    this.receiptUrl,
    this.redirectUrl,
  });

  /// A checkout the payer left before a payment was confirmed.
  const CheckoutResult.cancelled({this.reference})
    : status = CheckoutStatus.cancelled,
      receiptUrl = null,
      redirectUrl = null;

  /// How it ended.
  final CheckoutStatus status;

  /// The Malipopay payment reference, when a payment was started.
  final String? reference;

  /// The Malipopay receipt for a paid payment.
  final String? receiptUrl;

  /// The merchant's return address with the outcome added, when one is set.
  final String? redirectUrl;

  /// True only for [CheckoutStatus.successful].
  bool get isSuccessful => status == CheckoutStatus.successful;

  @override
  String toString() => 'CheckoutResult($status, reference: $reference)';
}

/// Reads the page's status word; anything unknown is treated as pending.
CheckoutStatus statusFromWire(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'successful':
      return CheckoutStatus.successful;
    case 'partial':
      return CheckoutStatus.partial;
    case 'failed':
      return CheckoutStatus.failed;
    case 'cancelled':
      return CheckoutStatus.cancelled;
    default:
      return CheckoutStatus.pending;
  }
}
