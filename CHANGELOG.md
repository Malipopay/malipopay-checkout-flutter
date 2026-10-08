## 0.1.0

- First release. `MalipopayCheckout.open` opens the Malipopay hosted checkout (card and mobile money) full screen and returns a `CheckoutResult` (successful, partial, pending, failed or cancelled, with the payment reference and receipt).
- `MalipopayCheckoutView` places the checkout in your own layout.
- Signed links (`SignedLink`), payer details, language, production and UAT environments.
- Only the checkout's own page can end the checkout; the bank's 3-D Secure page loads inside the same WebView.
