import 'dart:async';
import 'package:isar_agent_memory/src/sync/sync_backend.dart';

/// A P2P mesh [SyncBackend] implementation using edge-mesh.
class MeshSyncBackend implements SyncBackend {
  /// The unique identifier of this node in the peer-to-peer network.
  final String nodeId;

  /// The list of known peer node IDs in the peer-to-peer network.
  final List<String> peers;

  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();

  /// Creates a new [MeshSyncBackend] with the given [nodeId] and [peers].
  MeshSyncBackend({
    required this.nodeId,
    required this.peers,
  });

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    print(
        'MeshSyncBackend ($nodeId): Initializing with config: $config, peers: $peers');
  }

  @override
  Future<void> publishSnapshot(List<int> snapshot) async {
    print(
        'MeshSyncBackend ($nodeId): Publishing snapshot of length ${snapshot.length} to peers: $peers');
  }

  @override
  Stream<List<int>> get remoteSnapshotsStream => _controller.stream;

  @override
  Future<void> dispose() async {
    print('MeshSyncBackend ($nodeId): Disposing resources');
    await _controller.close();
  }
}
