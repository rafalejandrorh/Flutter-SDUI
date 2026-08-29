import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';

import '../sdui.dart';

class SduiNavigateAction {
  const SduiNavigateAction({
    required this.screen,
    this.style = 'push',
  });

  final String screen;
  final String style;

  factory SduiNavigateAction.fromJson(Map<String, dynamic> json) {
    return SduiNavigateAction(
      screen: json['screen'] as String,
      style: json['style'] as String? ?? 'push',
    );
  }
}

class SduiNavigateActionParser implements StacActionParser<SduiNavigateAction> {
  const SduiNavigateActionParser();

  @override
  String get actionType => 'sduiNavigate';

  @override
  SduiNavigateAction getModel(Map<String, dynamic> json) =>
      SduiNavigateAction.fromJson(json);

  @override
  FutureOr<dynamic> onCall(
    BuildContext context,
    SduiNavigateAction model,
  ) {
    final callback = Sdui.config.onNavigateScreen;
    if (callback == null) {
      throw StateError(
        'SduiConfig.onNavigateScreen is required for sduiNavigate actions.',
      );
    }
    callback(context, model.screen, style: model.style);
  }
}
