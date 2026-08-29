import 'package:flutter/services.dart';

import '../config.dart';
import '../domain/screen_document.dart';
import '../domain/sdui_exception.dart';
import '../ports/screen_repository.dart';
import 'json_object.dart';

/// Loads Stac JSON from the host asset bundle.
class AssetScreenRepository implements ScreenRepository {
  AssetScreenRepository(this.config, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final SduiConfig config;
  final AssetBundle _bundle;

  @override
  Future<ScreenDocument> load(String name) async {
    try {
      final path = config.resolveAssetPath(name);
      final raw = await _bundle.loadString(path);
      return ScreenDocument.parse(asJsonObject(raw, source: path), name: name);
    } on SduiException {
      rethrow;
    } catch (error) {
      throw SduiLoadFailedException(
        'Failed to load screen "$name".',
        cause: error,
        screen: name,
      );
    }
  }
}
