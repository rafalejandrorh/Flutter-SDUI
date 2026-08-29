/// Persistence for the auth bearer token. The host supplies the implementation.
abstract class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// In-memory store for tests and ephemeral sessions.
class MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}
