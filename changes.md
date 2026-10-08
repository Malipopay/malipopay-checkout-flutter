# Changes

Running log of releases, newest first.

## 2026-10-08 · 0.1.0 · First release
**Why.** Merchants with Flutter apps asked to take card and mobile money through the same branded Malipopay checkout their website uses.
**What changed.** `MalipopayCheckout.open` and `MalipopayCheckoutView` over `webview_flutter`, a JavaScript channel the page reports to (malipopay-dashboard #386), messages believed only from the checkout's own origin, return-address detection as a fallback, scheme allowlist. Verified on an iPhone 17 simulator against UAT: the real page loaded, card fields became ready, the page's cancel reached the app with the reference, and reopening the same order continued the same payment.
**Related:** LockwoodTech/malipopay-dashboard#386, lockwood-technology/malipopay-central-api#762
