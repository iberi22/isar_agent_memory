import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/gemini_embeddings_adapter.dart';
import 'dart:io';

Future<void> main() async {
  // Set your Gemini API key here or via environment variable
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '<YOUR_GEMINI_API_KEY>';
  final adapter = GeminiEmbeddingsAdapter(apiKey: apiKey);

  // Initialize Isar Core for pure Dart
  await Isar.initializeIsarCore(download: true);

  // Create the directory for the Isar database
  await Directory('./exampledb').create(recursive: true);

  // Open Isar in a temp directory for demo
  final isar = await Isar.open(
    [MemoryNodeSchema, MemoryEdgeSchema],
    inspector: false,
    directory: './exampledb',
  );
  final graph = MemoryGraph(isar, embeddingsAdapter: adapter);

  // Store a node with embedding
  final nodeId = await graph.storeNodeWithEmbedding(content: 'The quick brown fox jumps over the lazy dog.');
  print('Stored node with id: $nodeId');

  // Query with a similar phrase
  final queryEmbedding = await adapter.embed('A fox jumps over a dog');
  final results = await graph.semanticSearch(queryEmbedding, topK: 3);
  for (final result in results) {
    print('Node: ${result.node.content}, Distance: ${result.distance.toStringAsFixed(3)}, Provider: ${result.provider}');
  }

  // Explain recall for the top result
  if (results.isNotEmpty) {
    final explanation = await graph.explainRecall(results.first.node.id, queryEmbedding: queryEmbedding);
    print('Explain: $explanation');
  }

  await isar.close(deleteFromDisk: true);
}
