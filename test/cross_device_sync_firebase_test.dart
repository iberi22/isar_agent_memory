import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/sync/cross_device_sync_manager.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isarA;
  late Isar isarB;
  late MemoryGraph memoryGraphA;
  late MemoryGraph memoryGraphB;
  late CrossDeviceSyncManager syncManagerA;
  late CrossDeviceSyncManager syncManagerB;
  late MockFirebaseDatabase mockDatabase;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    mockDatabase = MockFirebaseDatabase();

    // Setup for Device A
    isarA = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'device_a_db',
    );
    memoryGraphA =
        MemoryGraph(isarA, embeddingsAdapter: FallbackEmbeddingsAdapter());
    syncManagerA = CrossDeviceSyncManager(memoryGraphA);

    // Setup for Device B
    isarB = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'device_b_db',
    );
    memoryGraphB =
        MemoryGraph(isarB, embeddingsAdapter: FallbackEmbeddingsAdapter());
    syncManagerB = CrossDeviceSyncManager(memoryGraphB);

    await isarA.writeTxn(() async => await isarA.clear());
    await isarB.writeTxn(() async => await isarB.clear());
  });

  tearDown(() async {
    await isarA.close(deleteFromDisk: true);
    await isarB.close(deleteFromDisk: true);
  });

  test('Firebase sync test', () async {
    final config = {
      'apiKey': 'fake-api-key',
      'appId': 'fake-app-id',
      'messagingSenderId': 'fake-sender-id',
      'projectId': 'fake-project-id',
      'databaseURL': mockDatabase.databaseURL,
      'userId': 'user123',
    };
    await syncManagerA.initializeBackend(firebaseConfig: config);
    await syncManagerB.initializeBackend(firebaseConfig: config);

    await memoryGraphA.storeNode(MemoryNode(content: 'Node from A'));
    await syncManagerA.publishSnapshot();

    await Future.delayed(const Duration(milliseconds: 100));
    final nodesOnB = await memoryGraphB.isar.memoryNodes.where().findAll();
    expect(nodesOnB.length, 1);
    expect(nodesOnB.first.content, 'Node from A');
  });
}
