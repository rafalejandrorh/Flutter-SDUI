# Changelog

All notable changes to this package are documented here.

## 0.0.1

SDK foundation: injectable runtime, versioned screen contract, cache, and tests
against PHP Core snapshots.

### Added

- Ports for `ScreenRepository`, `SduiRenderer`, and `SduiObserver`, composed by
  `SduiClient` / `Sdui.initialize`.
- `SduiScreen` (alias `DynamicScreen`) with typed load/render errors, retry,
  and host-replaceable `SduiViewPolicy` (loading/error copies, semantics, l10n).
- Dual screen contract: raw Stac JSON (`schemaVersion` 0) or
  `{ schemaVersion, name, body }` envelope (`schemaVersion` 1). Newer versions
  fail with `SduiUnsupportedVersionException`.
- `CachedScreenRepository` (stale-while-revalidate + ETag / `If-None-Match`).
- Widget tests for loading, error, retry, and render fallback.
- Contract tests and goldens for the PHP Core `home` / `details` snapshots
  (`tests/ScreenSnapshotTest.php`).
- Strict analyzer settings (`strict-casts`, `strict-inference`, `strict-raw-types`).

### Changed

- Hosts talk to `sdui_client`; Stac stays behind `SduiRenderer`.
- `SduiRoutes` only builds `/sdui/{name}` (login/register belong to the host).
