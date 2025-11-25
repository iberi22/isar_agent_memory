import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:isar_agent_memory/src/sync/sync_backend.dart';

/// A [SyncBackend] implementation for Firebase Realtime Database.
class FirebaseSyncBackend implements SyncBackend {
  late final FirebaseDatabase _database;
  final _controller = StreamController<List<int>>.broadcast();
  StreamSubscription? _subscription;
  DatabaseReference? _userRef;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final String? userId = config['userId'];
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('A valid userId must be provided in the config.');
    }

    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: config['apiKey'],
              appId: config['appId'],
              messagingSenderId: config['messagingSenderId'],
              projectId: config['projectId'],
              databaseURL: config['databaseURL'],
            ),
          )
        : Firebase.app();

    _database = FirebaseDatabase.instanceFor(app: app);
    _userRef = _database.ref('users/$userId');

    _subscription = _userRef!.child('snapshots').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final snapshot = List<int>.from(data['data'] as List);
        _controller.add(snapshot);
      }
    });
  }

  @override
  Future<void> publishSnapshot(List<int> snapshot) async {
    if (_userRef == null) {
      throw StateError('FirebaseSyncBackend not initialized.');
    }
    await _userRef!.child('snapshots').set({
      'data': snapshot,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Stream<List<int>> get remoteSnapshotsStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
