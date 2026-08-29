import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';

import '../sdui.dart';

class SduiLogoutAction {
  const SduiLogoutAction();

  factory SduiLogoutAction.fromJson(Map<String, dynamic> json) {
    return const SduiLogoutAction();
  }
}

class SduiLogoutActionParser implements StacActionParser<SduiLogoutAction> {
  const SduiLogoutActionParser();

  @override
  String get actionType => 'sduiLogout';

  @override
  SduiLogoutAction getModel(Map<String, dynamic> json) =>
      SduiLogoutAction.fromJson(json);

  @override
  FutureOr<dynamic> onCall(BuildContext context, SduiLogoutAction model) {
    Sdui.config.onLogout?.call();
  }
}
