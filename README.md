# malipopay_checkout

Malipopay hosted checkout for Flutter. One call opens your branded Malipopay payment page (card and mobile money) full screen and returns how it ended.

Card numbers go straight from the payer to the bank's hosted fields. They never pass through your app or your servers, so your app stays out of PCI scope.

## Before you start

1. In the Malipopay portal, open **Settings > Checkout** and create a checkout. Copy its id.
2. If your checkout only accepts signed links, sign them on your server (see [Signed links](#signed-links)).
3. Android: your app needs the internet permission in `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

## Install

```yaml
dependencies:
  malipopay_checkout: ^0.1.0
```

## Use

```dart
import 'package:malipopay_checkout/malipopay_checkout.dart';

final result = await MalipopayCheckout.open(
  context,
  integration: 'YOUR_CHECKOUT_ID',
  amount: 25000,
  order: 'ORDER-42',
);

switch (result.status) {
  case CheckoutStatus.successful:
    // Confirm on your server before you deliver (see below).
    break;
  case CheckoutStatus.cancelled:
    // The payer closed the checkout or went back.
    break;
  default:
    // pending, partial or failed: check on your server.
    break;
}
```

`result.reference` is the Malipopay payment reference, `result.receiptUrl` the receipt when it was paid.

### Always confirm on your server

The result is what the payer's phone saw. Before you deliver, confirm the payment on your server with the webhook Malipopay sends you, or `GET /api/v1/payment/verify/:reference`.

### One order, one payment

Pass your own order id as `order`. Opening the checkout again for the same order continues the same payment instead of charging twice. Opening it for the same order with a different amount is refused.

## Options

| Argument | What it does |
|---|---|
| `integration` | Your checkout id (required). |
| `amount` | What to charge, in TZS. Leave it out to let the payer enter it, if your checkout allows that. A checkout with a fixed amount ignores it. |
| `order` | Your order id. |
| `description` | A line shown under the amount. |
| `payer` | `CheckoutPayer(name:, phone:, email:)`, so the page can skip asking. |
| `language` | `'en'` or `'sw'`. The payer can switch on the page. |
| `signed` | `SignedLink(sig:, exp:)` from your server. |
| `returnUrl` | Only used on a signed link, and only if it is on one of your checkout's sites. |
| `environment` | `CheckoutEnvironment.production` (default) or `CheckoutEnvironment.uat`. A sandbox business on production uses `production`: the page shows "Test mode" and no money moves. |
| `baseUrl` | Override the checkout host (for a proxy). |
| `title` | The app bar title. `Payment` by default. |

To place the checkout in your own layout instead of a full-screen route, use `MalipopayCheckoutView(uri: checkoutUri(...), onResult: ...)`.

## Signed links

When **Only accept signed links** is on for your checkout, the amount and order cannot be changed on the phone. Your server computes:

```
HMAC-SHA256(signingSecret, "integration|amount|currency|order|returnUrl|exp")
```

Empty values stay empty between the bars. `exp` is a Unix time in seconds. Send `sig` and `exp` to the app and pass them as `signed: SignedLink(sig: sig, exp: exp)`.

Never put the signing secret in the app. Anyone can read it out of an app bundle.

## How it works

The package opens `https://app.malipopay.co.tz/c/<checkout>/embed` in a WebView and listens on a JavaScript channel. It believes the page's messages only while the WebView is on the checkout's own address, so no other page (such as the bank's 3-D Secure page) can end the checkout. The bank's 3-D Secure challenge loads inside the same WebView and returns to the checkout when done.

## Support

support@malipopay.co.tz · https://developers.malipopay.co.tz
