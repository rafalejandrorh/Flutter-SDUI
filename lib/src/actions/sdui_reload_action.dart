import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:stac_framework/stac_framework.dart';

import '../ports/sdui_observer.dart';

class SduiReloadAction {
  const SduiReloadAction({this.screen});

  /// Null reloads the screen that is currently focused.
  final String? screen;

  factory SduiReloadAction.fromJson(Map<String, dynamic> json) {
    final screen = json['screen'];
    return SduiReloadAction(
      screen: screen is String && screen.isNotEmpty ? screen : null,
    );
  }
}

/// Reloads a named screen, skipping the cache hit.
typedef SduiReloadCallback = Future<void> Function({String? screen});

/// Stac `sduiReload` → forced screen reload.
///
/// Returns an empty [Response] so Stac's `RefreshIndicator` completes the
/// refresh future without replacing the child. The screen widget owns the new body.
class SduiReloadActionParser implements StacActionParser<SduiReloadAction> {
  SduiReloadActionParser({required this.onReload, this.observer});

  final SduiReloadCallback onReload;
  final SduiObserver? observer;

  @override
  String get actionType => 'sduiReload';

  @override
  SduiReloadAction getModel(Map<String, dynamic> json) =>
      SduiReloadAction.fromJson(json);

  @override
  Future<Response<dynamic>> onCall(
    BuildContext context,
    SduiReloadAction model,
  ) async {
    observer?.onAction('sduiReload', screen: model.screen);
    await onReload(screen: model.screen);
    return Response<dynamic>(requestOptions: RequestOptions(path: ''));
  }
}
