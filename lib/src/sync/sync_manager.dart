import 'package:isar_agent_memory/src/sync/encryption_service.dart';

class SyncManager {
  final EncryptionService _encryptionService;

  // TODO: Inject SyncBackend (Firebase, WebSocket, etc.)
  SyncManager(this._encryptionService);

  Future<void> initialize({List<int>? encryptionKey}) async {
    await _encryptionService.initialize(rawKey: encryptionKey);
  }

  // Placeholder for future sync logic
  Future<void> sync() async {
    // 1. Pull changes from server
    // 2. Decrypt
    // 3. Merge (LWW)
    // 4. Encrypt local changes
    // 5. Push to server
  }
}
