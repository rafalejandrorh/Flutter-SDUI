/// Typed SDUI failures. Load/parse problems stay distinct from render ones.
sealed class SduiException implements Exception {
  const SduiException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return message;
    }
    return '$message\nCaused by: $cause';
  }
}

/// A named screen could not be fetched or parsed.
final class SduiLoadFailedException extends SduiException {
  const SduiLoadFailedException(
    super.message, {
    super.cause,
    required this.screen,
  });

  final String screen;
}

/// The payload's [schemaVersion] is newer than this client supports.
final class SduiUnsupportedVersionException extends SduiException {
  SduiUnsupportedVersionException({
    required this.screen,
    required this.schemaVersion,
    required this.maxSupported,
  }) : super(
         'Screen "$screen" requires schemaVersion $schemaVersion; '
         'this client supports up to $maxSupported.',
       );

  final String screen;
  final int schemaVersion;
  final int maxSupported;
}

/// Stac (or another renderer) could not turn the document into widgets.
final class SduiRenderFailedException extends SduiException {
  const SduiRenderFailedException(
    super.message, {
    super.cause,
    required this.screen,
  });

  final String screen;
}
