import 'sdui_exception.dart';

/// A named screen: either a raw Stac tree or a versioned HTTP envelope.
class ScreenDocument {
  /// Envelope version this client produces and understands.
  static const int currentSchemaVersion = 1;

  /// Raw Stac JSON (a widget tree with `type`, no envelope).
  static const int legacySchemaVersion = 0;

  /// Sent on HTTP requests so the API can negotiate the contract later.
  static const String clientVersionHeader = 'X-SDUI-Client-Version';

  const ScreenDocument({
    required this.name,
    required this.schemaVersion,
    required this.body,
  });

  final String name;
  final int schemaVersion;

  /// Stac widget tree passed to the renderer.
  final Map<String, dynamic> body;

  /// Accepts a Stac root (`type`) or `{ schemaVersion, name?, body }`.
  factory ScreenDocument.parse(
    Map<String, dynamic> json, {
    required String name,
  }) {
    if (json.containsKey('schemaVersion')) {
      return _parseEnvelope(json, requestedName: name);
    }
    if (json['type'] is String) {
      return ScreenDocument(
        name: name,
        schemaVersion: legacySchemaVersion,
        body: Map<String, dynamic>.from(json),
      );
    }
    throw SduiLoadFailedException(
      'Screen "$name" is neither a Stac tree nor a versioned envelope.',
      screen: name,
    );
  }

  static ScreenDocument _parseEnvelope(
    Map<String, dynamic> json, {
    required String requestedName,
  }) {
    final envelopeName = json['name'];
    final name = envelopeName is String && envelopeName.isNotEmpty
        ? envelopeName
        : requestedName;
    final version = _readSchemaVersion(json['schemaVersion'], name: name);
    if (version < 0) {
      throw SduiLoadFailedException(
        'Screen "$name" has an invalid schemaVersion ($version).',
        screen: name,
      );
    }
    if (version > currentSchemaVersion) {
      throw SduiUnsupportedVersionException(
        screen: name,
        schemaVersion: version,
        maxSupported: currentSchemaVersion,
      );
    }
    final rawBody = json['body'];
    if (rawBody is! Map) {
      throw SduiLoadFailedException(
        'Screen "$name" envelope is missing a JSON object body.',
        screen: name,
      );
    }
    final body = Map<String, dynamic>.from(rawBody);
    if (body['type'] is! String) {
      throw SduiLoadFailedException(
        'Screen "$name" body is not a Stac widget tree.',
        screen: name,
      );
    }
    return ScreenDocument(name: name, schemaVersion: version, body: body);
  }

  static int _readSchemaVersion(Object? value, {required String name}) {
    if (value is int) {
      return value;
    }
    if (value is num && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw SduiLoadFailedException(
      'Screen "$name" has an invalid schemaVersion.',
      screen: name,
    );
  }
}
