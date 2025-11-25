import 'dart:async';

/// Abstract interface for a synchronization backend.
///
/// This defines the contract for services that handle the real-time synchronization
/// of memory snapshots between devices (e.g., Firebase, WebSocket).
abstract class SyncBackend {
  /// Initializes the backend and establishes a connection.
  ///
  /// [config] is a map of configuration parameters (e.g., API keys, URLs).
  Future<void> initialize(Map<String, dynamic> config);

  /// Publishes an encrypted snapshot to the remote backend.
  ///
  /// [snapshot] is the encrypted data blob to be sent.
  Future<void> publishSnapshot(List<int> snapshot);

  /// A stream of incoming snapshots from the remote backend.
  ///
  /// Listen to this stream to receive real-time updates from other devices.
  Stream<List<int>> get remoteSnapshotsStream;

  /// Disposes of the backend connection and cleans up resources.
  Future<void> dispose();
}
