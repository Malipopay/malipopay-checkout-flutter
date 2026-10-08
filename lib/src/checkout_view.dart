/// The WebView that shows the checkout.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout_result.dart';
import 'checkout_session.dart';

/// The Malipopay checkout page in a WebView, for apps that want to place it
/// in their own layout. Most apps call [MalipopayCheckout.open] instead.
class MalipopayCheckoutView extends StatefulWidget {
  /// Shows the checkout at [uri] and calls [onResult] once when it ends.
  const MalipopayCheckoutView({
    super.key,
    required this.uri,
    required this.onResult,
    this.loading,
  });

  /// The checkout address, from `checkoutUri`.
  final Uri uri;

  /// Called once with how the checkout ended.
  final ValueChanged<CheckoutResult> onResult;

  /// Shown while the page loads. A small progress indicator by default.
  final Widget? loading;

  @override
  State<MalipopayCheckoutView> createState() => MalipopayCheckoutViewState();
}

/// State for [MalipopayCheckoutView]. [close] ends the checkout as cancelled.
class MalipopayCheckoutViewState extends State<MalipopayCheckoutView> {
  late final CheckoutSession _session;
  late final WebViewController _controller;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _session = CheckoutSession(
      checkoutUri: widget.uri,
      onDone: widget.onResult,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(bridgeName, onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            return _session.onNavigation(
                      uri,
                      isMainFrame: request.isMainFrame,
                    ) ==
                    NavigationVerdict.allow
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageStarted: (_) => _setLoading(true),
          onPageFinished: (_) => _setLoading(false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() => _loadError = error.description);
            }
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  /// Ends the checkout as cancelled (the payer chose to leave).
  void close() => _session.close();

  Future<void> _onMessage(JavaScriptMessage message) async {
    final current = await _controller.currentUrl();
    _session.onBridgeMessage(
      message.message,
      currentUrl: current == null ? null : Uri.tryParse(current),
    );
  }

  void _setLoading(bool value) {
    if (mounted && _loading != value) setState(() => _loading = value);
  }

  void _retry() {
    setState(() => _loadError = null);
    _controller.loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _LoadError(onRetry: _retry);
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child:
                    widget.loading ??
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The payment page could not load.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check the connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
