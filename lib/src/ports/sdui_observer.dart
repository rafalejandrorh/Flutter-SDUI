/// Host hook for analytics and diagnostics. Default is a no-op.
abstract class SduiObserver {
  const SduiObserver();

  void onScreenLoad(
    String name,
    Duration latency, {
    required int schemaVersion,
  }) {}

  void onScreenError(String name, Object error) {}

  void onAction(String actionType, {String? screen}) {}

  void onUnknownWidget(String type) {}

  void onRenderFailed(String name, Object error) {}
}

/// Default observer that ignores every event.
final class NoOpSduiObserver extends SduiObserver {
  const NoOpSduiObserver();
}
