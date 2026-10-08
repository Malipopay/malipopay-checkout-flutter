/// Where the checkout lives, and the address the WebView opens.
library;

/// The Malipopay environment that serves the checkout page.
///
/// A sandbox (TEST) business on production still uses [production]: the page
/// itself says it is a sandbox and no money moves.
enum CheckoutEnvironment {
  /// app.malipopay.co.tz, the live merchant portal and its checkout.
  production,

  /// demo.malipopay.co.tz, Malipopay's UAT environment.
  uat,
}

/// The origin that serves the checkout page for [environment].
Uri checkoutBase(CheckoutEnvironment environment) {
  switch (environment) {
    case CheckoutEnvironment.production:
      return Uri.parse('https://app.malipopay.co.tz');
    case CheckoutEnvironment.uat:
      return Uri.parse('https://demo.malipopay.co.tz');
  }
}

/// The payer's details, so the page can skip asking for them.
class CheckoutPayer {
  /// Creates the payer's details. Every field is optional.
  const CheckoutPayer({this.name, this.phone, this.email});

  /// Full name, as the payer would write it.
  final String? name;

  /// Tanzanian mobile number, local (0712...) or international (255712...).
  final String? phone;

  /// Email address, when the checkout asks for one.
  final String? email;
}

/// A link signed by the merchant's own server.
///
/// When a checkout only accepts signed links, the server computes
/// HMAC-SHA256 with the checkout's signing secret over
/// `integration|amount|currency|order|returnUrl|exp` and hands the app the
/// result. Never put the signing secret in an app: anyone can read it there.
class SignedLink {
  /// Creates a signature made on the merchant's server.
  const SignedLink({required this.sig, required this.exp});

  /// The hex HMAC-SHA256 the server computed.
  final String sig;

  /// Unix seconds after which the link stops working.
  final int exp;
}

/// The app's checkout address: `/c/<integration>/embed` on [base].
///
/// The embed path, not a query flag, marks a held checkout: the bank's
/// 3-D Secure return keeps the path and drops the query, so the page still
/// knows to report back to the app after the challenge.
Uri checkoutUri({
  required Uri base,
  required String integration,
  num? amount,
  String? order,
  String? currency,
  String? description,
  String? returnUrl,
  SignedLink? signed,
  CheckoutPayer? payer,
  String? language,
}) {
  if (integration.trim().isEmpty) {
    throw ArgumentError.value(integration, 'integration', 'is required');
  }
  final query = <String, String>{};
  void put(String key, Object? value) {
    if (value == null) return;
    final text = value is num ? _amountText(value) : value.toString().trim();
    if (text.isNotEmpty) query[key] = text;
  }

  put('amount', amount);
  put('order', order);
  put('currency', currency);
  put('description', description);
  put('returnUrl', returnUrl);
  put('exp', signed?.exp);
  put('sig', signed?.sig);
  put('name', payer?.name);
  put('phone', payer?.phone);
  put('email', payer?.email);
  put('lang', language);

  return base.replace(
    path: '/c/${Uri.encodeComponent(integration.trim())}/embed',
    queryParameters: query.isEmpty ? null : query,
  );
}

// 25000 not 25000.0: the server signs and compares the amount as text.
String _amountText(num value) =>
    value == value.truncate() ? value.truncate().toString() : value.toString();
