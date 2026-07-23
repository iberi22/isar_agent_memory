# isar_agent_memory

[![pub package](https://img.shields.io/pub/v/isar_agent_memory.svg)](https://pub.dev/packages/isar_agent_memory)
[![Isar](https://img.shields.io/badge/db-isar-blue?logo=databricks)](https://isar.dev)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

> **Motor de memoria agéntico para Dart/Flutter.** Graph-based, local-first, LLM-agnostic. Inspirado en Cognee y Graphiti.

---

## ¿Qué es?

`isar_agent_memory` es el **core de memoria para apps agentics** en Dart/Flutter. Proporciona almacenamiento persistente, búsqueda semántica, RAG con pipeline extensible, y aislamiento multi-tenant — todo offline-first, sin depender de un servidor.

Usado por: **Pocket Cerebro** (nodo móvil SWAL), **OrionHealth** (asistente clínico).

---

## Features

| Capa | Features |
|------|----------|
| **Memoria** | Graph CRUD (MemoryGraph), embeddings adaptables, búsqueda semántica/híbrida/multi-hop |
| **RAG** | Pipeline de 5 hooks (Expansion/Retrieval/ReRank/Enrich/Evaluate), QueryRouter (7 estrategias), re-ranking (BM25, MMR, Diversity, Recency, CrossEncoder) |
| **Multi-tenant** | SessionContext para aislamiento por sesión/usuario |
| **Memoria cognitiva** | Tipos episódico/semántico/procedural/working, consolidación, olvido automático |
| **On-device** | Backends Hash, TFLite, ONNX, Resilient + adaptador universal |
| **Sync** | Firebase/WebSocket cifrado (AES-256-GCM, LWW) + Pipeline legacy |
| **Privacidad** | PII masking, differential privacy, k-anonymity |
| **Multi-modal** | Embeddings remotos vía HTTP, delegación híbrida |

---

## Empezar

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

// Guardar
final id = await graph.storeNodeWithEmbedding(
  content: 'El usuario prefiere modo oscuro',
);

// Buscar
final results = await graph.semanticSearch(
  await adapter.embed('preferencias de UI'),
  topK: 3,
);
```

---

## Pipeline RAG

```dart
final pipeline = MemoryPipeline()
  ..addRetrievalHook(VectorRetrievalHook(graph: graph, embeddings: adapter))
  ..addRetrievalHook(HybridRetrievalHook(graph: graph))
  ..addEnrichmentHook(MultiHopEnrichmentHook(graph: graph));

final result = await pipeline.run('¿qué decidimos sobre la DB migration?');
```

---

## Sesiones multi-tenant

```dart
final session = SessionContext(
  graph: memoryGraph,
  sessionId: 'user-123',
);
await session.store('contexto de esta sesión');
final memories = await session.hybridSearch('tema relevante');
```

---

## Query Router

```dart
final router = QueryRouter(graph: graph, embeddings: adapter);
final plan = router.classify('¿qué pasó ayer con el servidor?');
// plan.strategy → QueryStrategy.temporal
final results = await router.execute(plan);
```

---

## Sync cifrado

```dart
final syncManager = SyncManager(graph);
await syncManager.initialize(encryptionKey: myKey);
final snapshot = await syncManager.exportEncryptedSnapshot();
await syncManager.importEncryptedSnapshot(snapshot);
```

---

## On-device + Telemetría

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
dart test
```

Nota: algunos tests requieren Isar codegen (`build_runner`). Los tests puros Dart (smoke, encryption, tokenizer, sync_manager) funcionan sin codegen.

---

## Roadmap

- [x] Graph CRUD + embeddings + búsqueda vectorial
- [x] HiRAG (capas jerárquicas, multi-hop)
- [x] Re-ranking (BM25, MMR, Diversity, Recency, CrossEncoder)
- [x] Pipeline RAG de 5 hooks + QueryRouter
- [x] SessionContext multi-tenant
- [x] Sync cifrado (Firebase/WebSocket)
- [x] Memoria cognitiva (episodic/semantic/procedural/working)
- [x] On-device backends (Hash, TFLite, ONNX, Resilient)
- [x] Telemetría de embeddings
- [ ] Cross-encoder local (ONNX)
- [ ] Sync P2P vía edge-mesh
- [ ] Publicación v0.6.0 en pub.dev

---

## Licencia

MIT
