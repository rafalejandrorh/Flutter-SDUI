import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import 'sdui.dart';

/// Loads a named Stac screen and renders it.
class DynamicScreen extends StatefulWidget {
  const DynamicScreen({
    super.key,
    required this.name,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String name;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder;

  @override
  State<DynamicScreen> createState() => _DynamicScreenState();
}

class _DynamicScreenState extends State<DynamicScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Sdui.loader.load(widget.name);
  }

  @override
  void didUpdateWidget(covariant DynamicScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _future = Sdui.loader.load(widget.name);
    }
  }

  void _retry() {
    setState(() {
      _future = Sdui.loader.load(widget.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingBuilder?.call(context) ??
              const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
        }
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(
                context,
                snapshot.error!,
                _retry,
              ) ??
              _DefaultError(error: snapshot.error!, onRetry: _retry);
        }
        final json = snapshot.data;
        if (json == null) {
          return widget.errorBuilder?.call(
                context,
                StateError('Empty screen JSON for ${widget.name}'),
                _retry,
              ) ??
              _DefaultError(
                error: StateError('Empty screen JSON for ${widget.name}'),
                onRetry: _retry,
              );
        }
        return Stac.fromJson(json, context) ??
            const Scaffold(body: Center(child: Text('Unable to render screen')));
      },
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load this screen.\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
