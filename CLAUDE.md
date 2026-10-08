# malipopay-checkout-flutter: Claude Context

**Flutter package `malipopay_checkout` on pub.dev.** Opens the Malipopay hosted checkout (`/c/<id>/embed`, served by malipopay-dashboard) in a WebView and returns the result.

The parent `Malipopay/CLAUDE.md` carries the naming, git flow and records rules.

- The page side lives in malipopay-dashboard: `src/screens/checkout/Hosted`, `src/models/hostedCheckout.js` (`postToParent` sends to the `MalipopayCheckoutApp` channel). Keep the channel name and the link keys (`checkoutUri`) in step with `src/embed/checkoutHelpers.js`.
- Backend: central-api `modules/hosted-checkout`. Signature canonical string: `integration|amount|currency|order|returnUrl|exp`.
- Test against UAT with `example/` and `--dart-define=CHECKOUT_ID=<id> --dart-define=MALIPOPAY_ENV=uat`. Never type card numbers into a deployed page from an automated session.
