import 'dart:async';
import 'package:isar_agent_memory/src/sync/sync_backend.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A [SyncBackend] implementation for WebSockets.
class WebSocketSyncBackend implements SyncBackend {
  late final WebSocketChannel _channel;
  final _controller = StreamController<List<int>>.broadcast();
  Timer? _keepAliveTimer;

  WebSocketSyncBackend({WebSocketChannel? channel}) {
    if (channel != null) {
      _channel = channel;
    }
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    if (!config.containsKey('channel')) {
      _channel = WebSocketChannel.connect(Uri.parse(config['url']));
    }
    _channel.stream.listen((data) {
      if (data == 'pong') return;
      _controller.add(List<int>.from(data));
    });

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _channel.sink.add('ping');
    });
  }

  @override
  Future<void> publishSnapshot(List<int> snapshot) async {
    _channel.sink.add(snapshot);
  }

  @override
  Stream<List<int>> get remoteSnapshotsStream => _controller.stream;

  @override
  Future<void> dispose() async {
    _keepAliveTimer?.cancel();
    await _channel.sink.close();
    await _controller.close();
  }
}
