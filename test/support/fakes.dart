import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sdui_client/sdui_client.dart';

/// Renders `body.data` as [Text] so widget tests do not need Stac.
class FakeRenderer implements SduiRenderer {
  const FakeRenderer();

  @override
  Widget? render(BuildContext context, ScreenDocument document) {
    final data = document.body['data'];
    if (data is String) {
      return Text(data);
    }
    return const SizedBox.shrink();
  }
}

class ThrowingRenderer implements SduiRenderer {
  const ThrowingRenderer();

  @override
  Widget? render(BuildContext context, ScreenDocument document) {
    throw StateError('Unable to render screen "${document.name}"');
  }
}

class NullRenderer implements SduiRenderer {
  const NullRenderer();

  @override
  Widget? render(BuildContext context, ScreenDocument document) => null;
}

class RecordingObserver extends SduiObserver {
  final List<String> actions = [];
  final List<String> loads = [];
  final List<String> errors = [];
  final List<String> renderFailures = [];

  @override
  void onAction(String actionType, {String? screen}) {
    actions.add(actionType);
  }

  @override
  void onScreenLoad(
    String name,
    Duration latency, {
    required int schemaVersion,
  }) {
    loads.add('$name:$schemaVersion');
  }

  @override
  void onScreenError(String name, Object error) {
    errors.add(name);
  }

  @override
  void onRenderFailed(String name, Object error) {
    renderFailures.add(name);
  }
}

class StreamingRepo extends MemoryScreenRepository
    implements ScreenChangeSource {
  StreamingRepo(super.screens);

  final _controller = StreamController<ScreenDocument>.broadcast(sync: true);

  @override
  Stream<ScreenDocument> watch(String name) => _controller.stream;

  void emit(String name, Map<String, dynamic> json) {
    _controller.add(ScreenDocument.parse(json, name: name));
  }

  Future<void> close() => _controller.close();
}

class PendingScreenRepository implements ScreenRepository {
  PendingScreenRepository(this.completer);

  final Completer<ScreenDocument> completer;

  @override
  Future<ScreenDocument> load(String name) => completer.future;
}
