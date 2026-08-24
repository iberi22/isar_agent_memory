# isar_agent_memory

[![pub package](https://img.shields.io/pub/v/isar_agent_memory.svg)](https://pub.dev/packages/isar_agent_memory)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.2.0-0175C2.svg)](https://dart.dev)

A universal, local-first semantic memory engine for Flutter/Dart apps. `isar_agent_memory` provides graph node persistence, vector embedding indexing, memory degree management, explainable retrieval, and an extensible 5-stage RAG pipeline — all powered by Isar database for high-performance offline storage.

---

## Features

- **Local-First Graph Persistence**: Fast, offline-first graph CRUD powered by Isar DB with edge relations and hierarchical layer support.
- **Pluggable Vector Search**: Seamless integration with on-device (Hash, TFLite, ONNX) and remote (Gemini, REST) embedding backends.
- **Memory Degree Management**: Built-in activation tracking for recency, retrieval frequency, and importance scoring to enable cognitive forgetting and consolidation.
- **5-Stage RAG Pipeline**: Pluggable hooks for Query Expansion, Retrieval (Vector/Hybrid), Re-Ranking (BM25, MMR, Diversity, Recency, CrossEncoder), Enrichment, and Evaluation.
- **Multi-Tenant Isolation**: `SessionContext` wrapper to isolate memories per user or per session while sharing underlying persistence.
- **End-to-End Encrypted Sync**: AES-256-GCM encrypted snapshot exports/imports with Last-Write-Wins (LWW) conflict resolution for multi-device sync.
- **Privacy Controls**: Automatic PII masking, differential privacy, and k-anonymity for safe client-side agent execution.

---

## Installation

Add `isar_agent_memory` to your Flutter or Dart project using `pub`:

```bash
flutter pub add isar_agent_memory
```

Or add it directly to your `pubspec.yaml`:

```yaml
dependencies:
  isar_agent_memory: ^0.6.0-dev
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1 # If building for Flutter platforms
```

---

## Quickstart

Below is a minimal, runnable Dart snippet demonstrating how to initialize an on-device embedding backend, open an Isar instance, store a memory node with automatic embedding generation, perform a semantic similarity search, and properly close resources.

```dart
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

Future<void> main() async {
  // 1. Initialize an on-device deterministic hash embedding backend
  final backend = HashEmbeddingBackend(dimension: 256);
  final adapter = BackendEmbeddingsAdapter(backend: backend);

  // 2. Open an Isar database instance with the required memory schemas
  final isar = await Isar.open(
    [MemoryNodeSchema, MemoryEdgeSchema],
    directory: './isar_memory_db',
  );

  // 3. Initialize the MemoryGraph
  final graph = MemoryGraph(isar, embeddingsAdapter: adapter);
  await graph.initialize();

  // 4. Store a memory node (embedding is generated automatically)
  final nodeId = await graph.storeNodeWithEmbedding(
    content: 'User prefers dark mode UI and high-contrast accessibility settings.',
    type: 'user_preference',
  );
  print('Stored memory node ID: $nodeId');

  // 5. Query memories using semantic similarity search
  final queryVector = await adapter.embed('dark mode settings');
  final searchResults = await graph.semanticSearch(queryVector, topK: 3);

  for (final result in searchResults) {
    print('Recalled memory: "${result.node.content}" (distance: ${result.distance.toStringAsFixed(4)})');
  }

  // 6. Close the Isar database connection
  await isar.close();
}
```

---

## Core Concepts

- **MemoryNode**: Represents a fundamental unit of knowledge, fact, or interaction in the agent memory graph. It contains textual content, optional node types, hierarchical layer designations, timestamps, vector embeddings, and activation metrics.
- **Degree**: Tracks cognitive activation metrics for each `MemoryNode`, including `lastAccessed` timestamp, retrieval `frequency`, and relative `importance` score. These metrics guide explainable retrieval (`explainRecall`), memory consolidation, and forgetting algorithms.
- **Embedding Search**: Vector similarity search integrated directly into the `MemoryGraph`. Supports pure semantic vector search as well as hybrid search combining Isar full-text filtering with vector distance scoring via Reciprocal Rank Fusion.

---

## API Overview

| Class / Utility | Description | Key Methods / Properties |
| :--- | :--- | :--- |
| `MemoryGraph` | Main memory engine coordinating Isar DB persistence and vector index operations. | `storeNodeWithEmbedding`, `storeNode`, `getNode`, `deleteNode`, `semanticSearch`, `hybridSearch`, `explainRecall` |
| `EmbeddingsAdapter` | Abstract base class for converting text strings into numeric vector representations. | `embed(String text)`, `dimension`, `providerName` |
| `MemoryNode` | Isar entity class representing a graph memory node. | `content`, `type`, `layer`, `embedding`, `degree`, `uuid`, `toJson()`, `fromJson()` |
| `MemoryEdge` | Isar entity class representing directed relationships between memory nodes. | `fromNodeId`, `toNodeId`, `relation`, `weight` |
| `Degree` | Entity for tracking memory activation, frequency, importance, and decay metrics. | `lastAccessed`, `frequency`, `importance` |
| `SessionContext` | Multi-tenant scope manager isolating memories by `sessionId` or `userId`. | `store`, `semanticSearch`, `hybridSearch`, `getAll`, `count`, `clear` |
| `MemoryPipeline` | Extensible 5-stage RAG execution pipeline. | `addRetrievalHook`, `addReRankingHook`, `addEnrichmentHook`, `run` |
| `SyncManager` | Manager for encrypted exports/imports and cross-device synchronization. | `exportEncryptedSnapshot`, `importEncryptedSnapshot`, `initialize` |
| `BackendEmbeddingsAdapter` | Universal adapter wrapping on-device inference engines (Hash, TFLite, ONNX). | `embed(String text)`, `backend`, `telemetry` |
| `GeminiEmbeddingsAdapter` | Embeddings adapter for Google Gemini API models. | `embed(String text)` |

---

## RAG Pipeline Architecture

`isar_agent_memory` provides an extensible 5-hook RAG (Retrieval-Augmented Generation) pipeline architecture:

```dart
final pipeline = MemoryPipeline()
  ..addRetrievalHook(VectorRetrievalHook(graph: graph, embeddings: adapter))
  ..addRetrievalHook(HybridRetrievalHook(graph: graph))
  ..addEnrichmentHook(MultiHopEnrichmentHook(graph: graph));

final result = await pipeline.run('What are the user\'s UI preferences?');
print('Retrieved ${result.nodes.length} relevant memory nodes.');
```

### Supported Re-Rankers

- **BM25ReRanker**: Term-frequency and inverse document frequency scoring.
- **MMRReRanker**: Maximal Marginal Relevance balancing similarity with result diversity.
- **DiversityReRanker**: Reduces redundant results by penalizing pair-wise vector closeness.
- **RecencyReRanker**: Boosts recently created or updated memories.
- **CrossEncoderReranker**: Deep neural re-ranking via remote HTTP or local ONNX inference.

---

## Multi-Tenant Session Isolation

Isolate memories for specific user sessions or agent threads without instantiating separate database files using `SessionContext`:

```dart
final userSession = SessionContext(
  graph: memoryGraph,
  sessionId: 'session-user-42',
  userId: 'user-42',
);

// Store memory scoped strictly to this session
await userSession.store('User prefers Spanish language responses.');

// Queries will automatically filter out memories from other sessions
final memories = await userSession.hybridSearch('language preference');
```

---

## On-Device Embedding Backends

For completely offline or privacy-preserving applications, `isar_agent_memory` supports on-device embedding generation:

- **HashEmbeddingBackend**: Ultra-fast, zero-dependency deterministic hash backend ideal for testing and lightweight local execution.
- **TFLiteEmbeddingBackend**: Native TensorFlow Lite execution for quantised mobile embedding models.
- **OnnxEmbeddingBackend**: ONNX Runtime execution for modern Transformer models (e.g., All-MiniLM-L6-v2).
- **ResilientEmbeddingBackend**: Primary/fallback chaining mechanism (e.g., ONNX primary with Hash fallback).

```dart
final hashBackend = HashEmbeddingBackend(dimension: 256);
final adapter = BackendEmbeddingsAdapter(backend: hashBackend);
```

---

## Encrypted Cross-Device Sync

Synchronize local memory graphs securely across devices using AES-256-GCM encryption:

```dart
final syncManager = SyncManager(memoryGraph);
await syncManager.initialize(encryptionKey: 'your-secure-256-bit-key');

// Export encrypted payload for transport
final snapshotBytes = await syncManager.exportEncryptedSnapshot();

// Import snapshot on remote device
await syncManager.importEncryptedSnapshot(snapshotBytes);
```

---

## Testing & Quality Assurance

Run pure Dart static analysis and unit tests:

```bash
flutter pub get
dart analyze lib/
flutter test
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
