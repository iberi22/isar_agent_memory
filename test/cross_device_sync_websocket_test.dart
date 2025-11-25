import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/sync/cross_device_sync_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'cross_device_sync_websocket_test.mocks.dart';

@GenerateMocks([WebSocketChannel, WebSocketSink])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isarA;
  late Isar isarB;
  late MemoryGraph memoryGraphA;
  late MemoryGraph memoryGraphB;
  late CrossDeviceSyncManager syncManagerA;
  late CrossDeviceSyncManager syncManagerB;
  late MockWebSocketChannel mockChannelA;
  late MockWebSocketChannel mockChannelB;
  late StreamController<dynamic> controllerA;
  late StreamController<dynamic> controllerB;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);

    isarA = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'device_a_db',
    );
    memoryGraphA =
        MemoryGraph(isarA, embeddingsAdapter: FallbackEmbeddingsAdapter());
    syncManagerA = CrossDeviceSyncManager(memoryGraphA);

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

    mockChannelA = MockWebSocketChannel();
    mockChannelB = MockWebSocketChannel();
    controllerA = StreamController<dynamic>.broadcast();
    controllerB = StreamController<dynamic>.broadcast();

    when(mockChannelA.stream).thenAnswer((_) => controllerA.stream);
    when(mockChannelB.stream).thenAnswer((_) => controllerB.stream);
    when(mockChannelA.sink).thenReturn(MockWebSocketSink());
    when(mockChannelB.sink).thenReturn(MockWebSocketSink());
  });

  tearDown(() async {
    await isarA.close(deleteFromDisk: true);
    await isarB.close(deleteFromDisk: true);
    await controllerA.close();
    await controllerB.close();
  });

  test('WebSocket sync test', () async {
    final configA = {'url': 'ws://localhost:1234', 'channel': mockChannelA};
    final configB = {'url': 'ws://localhost:1234', 'channel': mockChannelB};
    await syncManagerA.initializeBackend(websocketConfig: configA);
    await syncManagerB.initializeBackend(websocketConfig: configB);

    await memoryGraphA.storeNode(MemoryNode(content: 'Node from A'));
    await syncManagerA.publishSnapshot();

    final snapshot = await syncManagerA.exportEncryptedSnapshot();
    controllerB.add(snapshot);

    await Future.delayed(const Duration(milliseconds: 100));
    final nodesOnB = await memoryGraphB.isar.memoryNodes.where().findAll();
    expect(nodesOnB.length, 1);
    expect(nodesOnB.first.content, 'Node from A');
  });
}
