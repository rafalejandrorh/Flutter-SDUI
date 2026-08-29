import 'package:flutter/material.dart';

/// Host-replaceable loading/error UI, copies, and semantics for [SduiScreen].
class SduiViewPolicy {
  const SduiViewPolicy({
    this.loadingLabel = 'Loading',
    this.errorMessage = 'Could not load this screen.',
    this.retryLabel = 'Retry',
    this.showErrorDetails = true,
    this.includeSemantics = true,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// Default Material policy (English copies, semantics on).
  static const SduiViewPolicy material = SduiViewPolicy();

  /// Spoken while the first load is in progress.
  final String loadingLabel;

  /// Title / semantics for a failed load or render.
  final String errorMessage;

  /// Label on the retry control.
  final String retryLabel;

  /// When true, append `error.toString()` under [errorMessage].
  final bool showErrorDetails;

  /// Annotate default loading/error text for screen readers.
  final bool includeSemantics;

  final WidgetBuilder? loadingBuilder;

  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;

  Widget buildLoading(BuildContext context) {
    if (loadingBuilder != null) {
      return loadingBuilder!(context);
    }
    Widget indicator = const CircularProgressIndicator();
    if (includeSemantics) {
      indicator = Semantics(
        label: loadingLabel,
        liveRegion: true,
        child: indicator,
      );
    }
    return Scaffold(body: Center(child: indicator));
  }

  Widget buildError(BuildContext context, Object error, VoidCallback retry) {
    if (errorBuilder != null) {
      return errorBuilder!(context, error, retry);
    }
    final detail = showErrorDetails ? '\n$error' : '';
    Widget message = Text('$errorMessage$detail', textAlign: TextAlign.center);
    if (includeSemantics) {
      message = Semantics(liveRegion: true, child: message);
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(child: Icon(Icons.cloud_off, size: 48)),
              const SizedBox(height: 16),
              message,
              const SizedBox(height: 16),
              FilledButton(onPressed: retry, child: Text(retryLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
