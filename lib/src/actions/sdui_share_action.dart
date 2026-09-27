import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stac_framework/stac_framework.dart';

import '../ports/sdui_observer.dart';
import '../widgets/bound_value_store.dart';
import 'response_template.dart';

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
  SduiShareActionParser({this.observer, this.readValue});

  final SduiObserver? observer;

  /// Resolves `{{key}}` in [SduiShareAction.text]. Defaults to [BoundValueStore].
  final String? Function(String key)? readValue;

  @override
  String get actionType => 'sduiShare';

  @override
  SduiShareAction getModel(Map<String, dynamic> json) =>
      SduiShareAction.fromJson(json);

  @override
  Future<void> onCall(BuildContext context, SduiShareAction model) {
    observer?.onAction('sduiShare');
    final read = readValue ?? BoundValueStore.instance.read;
    final resolved = resolveBoundText(model.text, read) ?? model.text;
    final text = resolved.isEmpty ? 'Nada para compartir' : resolved;
    return SharePlus.instance.share(ShareParams(text: text));
  }
}
