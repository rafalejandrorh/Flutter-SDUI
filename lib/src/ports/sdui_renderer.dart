import 'package:flutter/widgets.dart';

import '../domain/screen_document.dart';

/// Turns a [ScreenDocument] into widgets. Stac is one implementation.
abstract class SduiRenderer {
  Widget? render(BuildContext context, ScreenDocument document);
}
