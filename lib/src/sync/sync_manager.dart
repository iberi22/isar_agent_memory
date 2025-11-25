import 'dart:convert';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/sync/encryption_service.dart';
import 'package:isar/isar.dart';

class SyncManager {
  final EncryptionService _encryptionService;
  final MemoryGraph _memoryGraph;

  // TODO: Inject SyncBackend (Firebase, WebSocket, etc.)
  SyncManager(this._memoryGraph) : _encryptionService = EncryptionService();

  Future<void> initialize({List<int>? encryptionKey}) async {
    await _encryptionService.initialize(rawKey: encryptionKey);
  }

  /// Exports the entire memory graph as an encrypted blob.
  ///
  /// The format is a JSON string containing:
  /// {
  ///   "nodes": [...],
  ///   "edges": [...]
  /// }
  ///
  /// This JSON is then encrypted using the [EncryptionService].
  /// Returns a list of integers (the encrypted payload).
  Future<List<int>> exportEncryptedSnapshot() async {
    if (!_encryptionService.isInitialized) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }

    // 1. Fetch all data
    final nodes = await _memoryGraph.isar.memoryNodes.where().findAll();
    final edges = await _memoryGraph.isar.memoryEdges.where().findAll();

    // 2. Serialize to JSON
    // We use a custom map structure because we want to handle specific fields
    // or metadata in a standardized way for sync.
    final data = {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0', // Schema version
    };

    final jsonString = jsonEncode(data);

    // 3. Encrypt
    return await _encryptionService.encrypt(jsonString);
  }

  /// Imports an encrypted snapshot and merges it into the local database.
  ///
  /// [encryptedData] is the payload returned by [exportEncryptedSnapshot].
  ///
  /// This implementation uses a basic Last-Write-Wins (LWW) strategy based on `modifiedAt`
  /// and matches records using the `uuid` field.
  Future<void> importEncryptedSnapshot(List<int> encryptedData) async {
    if (!_encryptionService.isInitialized) {
      throw StateError(
          'EncryptionService not initialized. Call initialize() first.');
    }

    // 1. Decrypt
    final jsonString = await _encryptionService.decrypt(encryptedData);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final nodesJson = (data['nodes'] as List).cast<Map<String, dynamic>>();
    final edgesJson = (data['edges'] as List).cast<Map<String, dynamic>>();

    // 2. Merge Nodes (LWW)
    await _memoryGraph.isar.writeTxn(() async {
      for (final nodeMap in nodesJson) {
        final incomingNode = MemoryNode.fromJson(nodeMap);

        // Validate UUID
        if (incomingNode.uuid == null) {
          // Should not happen if schema enforces it, but safeguard.
          continue;
        }

        // Find by UUID
        final existingNode = await _memoryGraph.isar.memoryNodes
            .filter()
            .uuidEqualTo(incomingNode.uuid)
            .findFirst();

        if (existingNode == null) {
          // New node. Ensure ID doesn't conflict (Isar auto-increments, but if we deserialize with ID, we might overwrite)
          // We should let Isar assign a new local ID for the new node, OR force the ID if we want to sync local IDs (bad idea).
          // Best practice: Use UUID for sync, ignore local ID.
          // So we set id to Isar.autoIncrement (or whatever triggers new ID) if it's not already.
          // But MemoryNode.fromJson sets 'id' from JSON.
          // We should RESET the local ID to allow Isar to generate a new one,
          // UNLESS we are restoring a backup to the SAME device.
          // For sync, we want new local ID.
          incomingNode.id = Isar.autoIncrement;
          await _memoryGraph.isar.memoryNodes.put(incomingNode);
        } else {
          // Existing node found by UUID. Update it.
          // LWW Check
          final incomingTime =
              incomingNode.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final existingTime =
              existingNode.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (incomingTime.isAfter(existingTime)) {
            // Preserve local ID to update the correct record
            incomingNode.id = existingNode.id;
            await _memoryGraph.isar.memoryNodes.put(incomingNode);
          }
        }
      }

      // 3. Merge Edges (LWW)
      for (final edgeMap in edgesJson) {
        final incomingEdge = MemoryEdge.fromJson(edgeMap);

        if (incomingEdge.uuid == null) continue;

        final existingEdge = await _memoryGraph.isar.memoryEdges
            .filter()
            .uuidEqualTo(incomingEdge.uuid)
            .findFirst();

        if (existingEdge == null) {
          incomingEdge.id = Isar.autoIncrement;
          await _memoryGraph.isar.memoryEdges.put(incomingEdge);
        } else {
          final incomingTime =
              incomingEdge.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final existingTime =
              existingEdge.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (incomingTime.isAfter(existingTime)) {
            incomingEdge.id = existingEdge.id;
            await _memoryGraph.isar.memoryEdges.put(incomingEdge);
          }
        }
      }
    });

    // Re-index vectors if needed
    await _memoryGraph.initialize();
  }
}
