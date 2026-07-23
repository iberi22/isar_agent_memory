# isar_agent_memory

[![pub package](https://img.shields.io/pub/v/isar_agent_memory.svg)](https://pub.dev/packages/isar_agent_memory)
[![Isar](https://img.shields.io/badge/db-isar-blue?logo=databricks)](https://isar.dev)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

> **Agentic memory engine for Dart/Flutter.** Graph-based, local-first, LLM-agnostic. Inspired by Cognee and Graphiti.

---

## What is it?

`isar_agent_memory` is the **core memory engine for agentic apps** in Dart/Flutter. Persistent storage, semantic search, extensible RAG pipeline, and multi-tenant isolation — all offline-first, no server required.

Used by: **Pocket Cerebro** (SWAL mobile node), **OrionHealth** (clinical assistant).

---

## Features

| Layer | Features |
|-------|----------|
| **Memory** | Graph CRUD (MemoryGraph), pluggable embeddings, semantic/hybrid/multi-hop search |
| **RAG** | 5-hook pipeline (Expansion/Retrieval/ReRank/Enrich/Evaluate), QueryRouter (7 strategies), re-ranking (BM25, MMR, Diversity, Recency, CrossEncoder) |
| **Multi-tenant** | SessionContext for session/user isolation |
| **Cognitive memory** | Episodic/semantic/procedural/working types, consolidation, automatic forgetting |
| **On-device** | Hash, TFLite, ONNX, Resilient backends + universal adapter |
| **Sync** | Firebase/WebSocket encrypted (AES-256-GCM, LWW) + legacy pipeline |
| **Privacy** | PII masking, differential privacy, k-anonymity |
| **Multi-modal** | Remote embeddings via HTTP, hybrid delegation |

---

## Quickstart

```yaml
dependencies:
  isar_agent_memory: ^0.6.0-dev
  isar: ^3.1.0+1
```

```dart
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

final adapter = GeminiEmbeddingsAdapter(apiKey: 'YOUR_API_KEY');
final isar = await Isar.open([], directory: './db');
final graph = MemoryGraph(isar, embeddingsAdapter: adapter);

// Store
final id = await graph.storeNodeWithEmbedding(
  content: 'User prefers dark mode',
);

// Search
final results = await graph.semanticSearch(
  await adapter.embed('UI preferences'),
  topK: 3,
);
```

---

## RAG Pipeline

```dart
final pipeline = MemoryPipeline()
  ..addRetrievalHook(VectorRetrievalHook(graph: graph, embeddings: adapter))
  ..addRetrievalHook(HybridRetrievalHook(graph: graph))
  ..addEnrichmentHook(MultiHopEnrichmentHook(graph: graph));

final result = await pipeline.run('what did we decide about the DB migration?');
```

---

## Multi-tenant Sessions

```dart
final session = SessionContext(
  graph: memoryGraph,
  sessionId: 'user-123',
);
await session.store('context for this session');
final memories = await session.hybridSearch('relevant topic');
```

---

## Query Router

```dart
final router = QueryRouter(graph: graph, embeddings: adapter);
final plan = router.classify('what happened yesterday with the server?');
// plan.strategy → QueryStrategy.temporal
final results = await router.execute(plan);
```

---

## Encrypted Sync

```dart
final syncManager = SyncManager(graph);
await syncManager.initialize(encryptionKey: myKey);
final snapshot = await syncManager.exportEncryptedSnapshot();
await syncManager.importEncryptedSnapshot(snapshot);
```

---

## On-device + Telemetry

```dart
final backend = HashEmbeddingBackend(dimension: 256);
final telemetry = EmbeddingTelemetryRecorder();
final adapter = BackendEmbeddingsAdapter(
  backend: backend,
  telemetry: telemetry,
);
final graph = MemoryGraph(isar, embeddingsAdapter: adapter);
```

---

## Testing

```bash
flutter pub get
dart analyze lib/
flutter test
```

Pure-Dart tests (smoke, encryption, tokenizer, sync_manager) pass without build_runner. Tests requiring Isar codegen need `dart run build_runner build`.

---

## Roadmap

- [x] Graph CRUD + embeddings + vector search
- [x] HiRAG (hierarchical layers, multi-hop)
- [x] Re-ranking (BM25, MMR, Diversity, Recency, CrossEncoder)
- [x] 5-hook RAG pipeline + QueryRouter
- [x] SessionContext multi-tenant
- [x] Encrypted sync (Firebase/WebSocket)
- [x] Cognitive memory (episodic/semantic/procedural/working)
- [x] On-device backends (Hash, TFLite, ONNX, Resilient)
- [x] Embedding telemetry
- [x] Multi-modal remote embeddings
- [x] Privacy features (PII, differential privacy)
- [ ] Local cross-encoder (ONNX)
- [ ] P2P sync via edge-mesh
- [ ] Xavier integration (sync protocol)
- [ ] v0.6.0 release on pub.dev

---

## License

MIT
