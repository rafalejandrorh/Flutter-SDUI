import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stac_framework/stac_framework.dart';

import '../ports/sdui_observer.dart';

class SduiShareAction {
  const SduiShareAction({required this.text});

  final String text;

  factory SduiShareAction.fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    return SduiShareAction(text: text is String ? text : '');
  }
}

/// Stac `sduiShare` → system share sheet.
class SduiShareActionParser implements StacActionParser<SduiShareAction> {
  SduiShareActionParser({this.observer});

  final SduiObserver? observer;

  @override
  String get actionType => 'sduiShare';

  @override
  SduiShareAction getModel(Map<String, dynamic> json) =>
      SduiShareAction.fromJson(json);

  @override
  Future<void> onCall(BuildContext context, SduiShareAction model) {
    observer?.onAction('sduiShare');
    return SharePlus.instance.share(ShareParams(text: model.text));
  }
}
