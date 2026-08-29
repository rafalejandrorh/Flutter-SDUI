import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stac_framework/stac_framework.dart';

import '../ports/sdui_observer.dart';

class SduiLogoutAction {
  const SduiLogoutAction();

  factory SduiLogoutAction.fromJson(Map<String, dynamic> json) {
    return const SduiLogoutAction();
  }
}

/// Stac `sduiLogout` → host logout callback.
class SduiLogoutActionParser implements StacActionParser<SduiLogoutAction> {
  SduiLogoutActionParser({this.onLogout, this.observer});

  final VoidCallback? onLogout;
  final SduiObserver? observer;

  @override
  String get actionType => 'sduiLogout';

  @override
  SduiLogoutAction getModel(Map<String, dynamic> json) =>
      SduiLogoutAction.fromJson(json);

  @override
  FutureOr<dynamic> onCall(BuildContext context, SduiLogoutAction model) {
    observer?.onAction('sduiLogout');
    onLogout?.call();
  }
}
