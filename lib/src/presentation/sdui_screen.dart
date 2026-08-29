import 'package:flutter/material.dart';

import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';
import '../ports/sdui_observer.dart';
import '../ports/sdui_renderer.dart';
import '../sdui.dart';

/// Loads a named SDUI screen and renders it.
class SduiScreen extends StatefulWidget {
  const SduiScreen({
    super.key,
    required this.name,
    this.repository,
    this.renderer,
    this.observer,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String name;
  final ScreenRepository? repository;
  final SduiRenderer? renderer;
  final SduiObserver? observer;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

/// Back-compat alias for hosts that still construct [DynamicScreen].
typedef DynamicScreen = SduiScreen;

class _SduiScreenState extends State<SduiScreen> {
  late Future<ScreenDocument> _future;

  ScreenRepository get _repository =>
      widget.repository ?? Sdui.client.repository;

  SduiRenderer get _renderer => widget.renderer ?? Sdui.client.renderer;

  SduiObserver get _observer {
    if (widget.observer != null) {
      return widget.observer!;
    }
    if (Sdui.isInitialized) {
      return Sdui.client.observer;
    }
    return const NoOpSduiObserver();
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant SduiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name ||
        oldWidget.repository != widget.repository) {
      _future = _load();
    }
  }

  Future<ScreenDocument> _load() async {
    final watch = Stopwatch()..start();
    try {
      final document = await _repository.load(widget.name);
      _observer.onScreenLoad(
        widget.name,
        watch.elapsed,
        schemaVersion: document.schemaVersion,
      );
      return document;
    } catch (error) {
      _observer.onScreenError(widget.name, error);
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  Widget _errorView(BuildContext context, Object error) {
    return widget.errorBuilder?.call(context, error, _retry) ??
        _DefaultError(error: error, onRetry: _retry);
  }

  Widget _renderDocument(BuildContext context, ScreenDocument document) {
    try {
      final rendered = _renderer.render(context, document);
      if (rendered != null) {
        return rendered;
      }
      final error = SduiRenderFailedException(
        'Unable to render screen "${document.name}".',
        screen: document.name,
      );
      _observer.onRenderFailed(document.name, error);
      return _errorView(context, error);
    } catch (error) {
      _observer.onRenderFailed(document.name, error);
      return _errorView(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScreenDocument>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingBuilder?.call(context) ??
              const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return _errorView(context, snapshot.error!);
        }
        final document = snapshot.data;
        if (document == null) {
          final error = SduiLoadFailedException(
            'Empty screen JSON for ${widget.name}',
            screen: widget.name,
          );
          return _errorView(context, error);
        }
        return _renderDocument(context, document);
      },
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error, required this.onRetry});

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
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
