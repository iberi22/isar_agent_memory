import 'dart:async';
import 'package:isar_agent_memory/isar_agent_memory.dart';

/// Manages cross-device synchronization of the memory graph.
///
/// This class extends [SyncManager] to add support for real-time synchronization
/// using different backends (e.g., Firebase, WebSockets).
class CrossDeviceSyncManager extends SyncManager {
  SyncBackend? _backend;
  StreamSubscription? _subscription;

  /// Creates a [CrossDeviceSyncManager] for the given [memoryGraph].
  CrossDeviceSyncManager(super.memoryGraph);

  /// Initializes the sync manager with a specific backend.
  ///
  /// The backend is chosen by the [SyncBackendFactory].
  Future<void> initializeBackend({
    Map<String, dynamic>? firebaseConfig,
    Map<String, dynamic>? websocketConfig,
    List<int>? encryptionKey,
  }) async {
    await initialize(encryptionKey: encryptionKey);
    _backend = SyncBackendFactory.createBackend(
      firebaseConfig: firebaseConfig,
      websocketConfig: websocketConfig,
    );
    await _backend!.initialize(firebaseConfig ?? websocketConfig ?? {});

    // Start listening for remote changes
    _subscription = _backend!.remoteSnapshotsStream.listen((snapshot) {
      importEncryptedSnapshot(snapshot);
    });
  }

  /// Publishes the current memory state as an encrypted snapshot.
  Future<void> publishSnapshot() async {
    if (_backend == null) {
      throw StateError('Sync backend not initialized.');
    }
    final snapshot = await exportEncryptedSnapshot();
    await _backend!.publishSnapshot(snapshot);
  }

  /// Disposes of the sync manager and its backend.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _backend?.dispose();
  }
}

/// A factory for creating [SyncBackend] instances.
class SyncBackendFactory {
  /// Creates a [SyncBackend] based on the provided configurations.
  ///
  /// If [firebaseConfig] is provided, a [FirebaseSyncBackend] is created.
  /// Otherwise, a [WebSocketSyncBackend] is created as a fallback.
  static SyncBackend createBackend({
    Map<String, dynamic>? firebaseConfig,
    Map<String, dynamic>? websocketConfig,
  }) {
    if (firebaseConfig != null) {
      return FirebaseSyncBackend();
    } else {
      return WebSocketSyncBackend(channel: websocketConfig?['channel']);
    }
  }
}
