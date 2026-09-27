import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';
import '../ports/sdui_observer.dart';
import '../ports/sdui_renderer.dart';
import '../sdui.dart';
import 'sdui_view_policy.dart';

/// Loads a named SDUI screen and renders it.
class SduiScreen extends StatefulWidget {
  const SduiScreen({
    super.key,
    required this.name,
    this.repository,
    this.renderer,
    this.observer,
    this.viewPolicy,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String name;
  final ScreenRepository? repository;
  final SduiRenderer? renderer;
  final SduiObserver? observer;
  final SduiViewPolicy? viewPolicy;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

/// Back-compat alias for hosts that still construct [DynamicScreen].
typedef DynamicScreen = SduiScreen;

class _SduiScreenState extends State<SduiScreen> {
  ScreenDocument? _document;
  Object? _error;
  bool _loading = true;
  StreamSubscription<ScreenDocument>? _watchSub;
  StreamSubscription<ScreenDocument>? _reloadSub;

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

  SduiViewPolicy get _policy {
    if (widget.viewPolicy != null) {
      return widget.viewPolicy!;
    }
    if (Sdui.isInitialized) {
      return Sdui.client.viewPolicy;
    }
    return SduiViewPolicy.material;
  }

  @override
  void initState() {
    super.initState();
    _subscribe();
    _bindReload();
    unawaited(_load(notify: false));
  }

  @override
  void didUpdateWidget(covariant SduiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name ||
        oldWidget.repository != widget.repository) {
      if (oldWidget.repository == null && Sdui.isInitialized) {
        Sdui.client.unfocusScreen(oldWidget.name);
      }
      _document = null;
      _error = null;
      _subscribe();
      _bindReload();
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _cancelWatch();
    _cancelReload();
    if (widget.repository == null && Sdui.isInitialized) {
      Sdui.client.unfocusScreen(widget.name);
    }
    super.dispose();
  }

  void _bindReload() {
    _cancelReload();
    if (widget.repository != null || !Sdui.isInitialized) {
      return;
    }
    Sdui.client.focusScreen(widget.name);
    _reloadSub = Sdui.client.reloads.listen((document) {
      if (!mounted || document.name != widget.name) {
        return;
      }
      setState(() {
        _document = document;
        _error = null;
        _loading = false;
      });
    });
  }

  void _cancelReload() {
    final sub = _reloadSub;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    _reloadSub = null;
  }

  void _subscribe() {
    _cancelWatch();
    final repository = _repository;
    if (repository is ScreenChangeSource) {
      _watchSub = repository.watch(widget.name).listen((document) {
        if (!mounted) {
          return;
        }
        setState(() {
          _document = document;
          _error = null;
          _loading = false;
        });
      });
      return;
    }
  }

  void _cancelWatch() {
    final sub = _watchSub;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    _watchSub = null;
  }

  Future<void> _load({bool notify = true}) async {
    _loading = true;
    _error = null;
    if (notify && mounted) {
      setState(() {});
    }
    final stopwatch = Stopwatch()..start();
    try {
      final document = await _repository.load(widget.name);
      _observer.onScreenLoad(
        widget.name,
        stopwatch.elapsed,
        schemaVersion: document.schemaVersion,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _document = document;
        _loading = false;
      });
    } catch (error) {
      _observer.onScreenError(widget.name, error);
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _retry() {
    unawaited(_load());
  }

  Widget _errorView(BuildContext context, Object error) {
    return widget.errorBuilder?.call(context, error, _retry) ??
        _policy.buildError(context, error, _retry);
  }

  Widget _loadingView(BuildContext context) {
    return widget.loadingBuilder?.call(context) ??
        _policy.buildLoading(context);
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
    final document = _document;
    if (document != null) {
      return _renderDocument(context, document);
    }
    if (_loading) {
      return _loadingView(context);
    }
    if (_error != null) {
      return _errorView(context, _error!);
    }
    return _errorView(
      context,
      SduiLoadFailedException(
        'Empty screen JSON for ${widget.name}',
        screen: widget.name,
      ),
    );
  }
}
