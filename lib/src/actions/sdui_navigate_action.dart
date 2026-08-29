import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stac_framework/stac_framework.dart';

import '../config.dart';
import '../ports/sdui_observer.dart';

class SduiNavigateAction {
  const SduiNavigateAction({required this.screen, this.style = 'push'});

  final String screen;
  final String style;

  factory SduiNavigateAction.fromJson(Map<String, dynamic> json) {
    return SduiNavigateAction(
      screen: json['screen'] as String,
      style: json['style'] as String? ?? 'push',
    );
  }
}

/// Stac `sduiNavigate` → host [SduiNavigateCallback].
class SduiNavigateActionParser implements StacActionParser<SduiNavigateAction> {
  SduiNavigateActionParser({required this.onNavigate, this.observer});

  final SduiNavigateCallback onNavigate;
  final SduiObserver? observer;

  @override
  String get actionType => 'sduiNavigate';

  @override
  SduiNavigateAction getModel(Map<String, dynamic> json) =>
      SduiNavigateAction.fromJson(json);

  @override
  FutureOr<dynamic> onCall(BuildContext context, SduiNavigateAction model) {
    observer?.onAction('sduiNavigate', screen: model.screen);
    onNavigate(context, model.screen, style: model.style);
  }
}
