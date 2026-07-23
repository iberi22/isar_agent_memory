# API Reference

This document provides a comprehensive API reference for the 51 public exports of the `isar_agent_memory` package, arranged in the order of their appearance in the barrel file `lib/isar_agent_memory.dart`.

## Verification Cross-Reference Checklist

The following table lists all 51 public exports of `isar_agent_memory` to verify completeness against the barrel line count.

| Export # | Source Path | Key Class / Interface / Extension |
|---|---|---|
| 1 | `src/models/memory_node.dart` | `MemoryNode` |
| 2 | `src/models/memory_edge.dart` | `MemoryEdge` |
| 3 | `src/models/memory_embedding.dart` | `MemoryEmbedding` |
| 4 | `src/models/degree.dart` | `Degree` |
| 5 | `src/memory_graph.dart` | `MemoryGraph` |
| 6 | `src/embeddings_adapter.dart` | `EmbeddingsAdapter` |
| 7 | `src/gemini_embeddings_adapter.dart` | `GeminiEmbeddingsAdapter` |
| 8 | `src/fallback_embeddings_adapter.dart` | `FallbackEmbeddingsAdapter` |
| 9 | `src/on_device_embeddings_adapter.dart` | `OnDeviceEmbeddingsAdapter` |
| 10 | `src/vector_index.dart` | `VectorIndex`, `VectorSearchResult`, `VectorMetric` |
| 11 | `src/vector_index_objectbox.dart` | `ObjectBoxVectorIndex`, `ObxVectorDoc`, `ObxVectorDoc384` |
| 12 | `src/hierarchical_graph.dart` | `HierarchicalMemoryGraph` (Extension) |
| 13 | `src/llm_adapter.dart` | `LLMAdapter` |
| 14 | `src/reranking_strategy.dart` | `ReRankingStrategy` |
| 15 | `src/rerankers/bm25_reranker.dart` | `BM25ReRanker` |
| 16 | `src/rerankers/diversity_reranker.dart` | `DiversityReRanker` |
| 17 | `src/rerankers/mmr_reranker.dart` | `MMRReRanker` |
| 18 | `src/rerankers/recency_reranker.dart` | `RecencyReRanker` |
| 19 | `src/rerankers/cross_encoder_reranker.dart` | `CrossEncoderReranker`, `RemoteCrossEncoderAdapter` |
| 20 | `src/sync/sync_manager.dart` | `SyncManager` |
| 21 | `src/sync/sync_backend.dart` | `SyncBackend` |
| 22 | `src/sync/firebase_sync_backend.dart` | `FirebaseSyncBackend` |
| 23 | `src/sync/websocket_sync_backend.dart` | `WebSocketSyncBackend` |
| 24 | `src/sync/cross_device_sync_manager.dart` | `CrossDeviceSyncManager` |
| 25 | `src/memory_consolidation.dart` | `MemoryConsolidation` |
| 26 | `src/embeddings_cache.dart` | `EmbeddingsCache`, `CacheStats` |
| 27 | `src/quality_metrics.dart` | `QualityMetrics` |
| 28 | `src/forgetting_mechanism.dart` | `ForgettingMechanism`, `ForgettingReport` |
| 29 | `src/dynamic_layers.dart` | `DynamicLayerCreation` (Extension) |
| 30 | `src/multi_modal_adapter.dart` | `MultiModalEmbeddingsAdapter`, `StructuredDataProcessor` |
| 31 | `src/agent_memory_types.dart` | `AgentMemoryTypes`, `MemoryTypeStats` |
| 32 | `src/utils/encryption_utils.dart` | `EncryptionUtils` |
| 33 | `src/privacy_features.dart` | `PrivacyFeatures`, `PIIDetector` |
| 34 | `src/pipeline_hooks.dart` | `MemoryPipeline`, `VectorRetrievalHook`, `PipelineContext` |
| 35 | `src/session_context.dart` | `SessionContext` |
| 36 | `src/query_router.dart` | `QueryRouter`, `QueryStrategy`, `RoutingPlan` |
| 37 | `src/on_device/on_device_embedding_backend.dart` | `OnDeviceEmbeddingBackend` |
| 38 | `src/on_device/hash_embedding_backend.dart` | `HashEmbeddingBackend` |
| 39 | `src/on_device/onnx_embedding_backend.dart` | `OnnxEmbeddingBackend` |
| 40 | `src/on_device/onnx_text_embedding_runner.dart` | `OnnxTextEmbeddingRunner` |
| 41 | `src/on_device/tflite_embedding_backend.dart` | `TFLiteEmbeddingBackend` |
| 42 | `src/on_device/tflite_text_embedding_runner.dart` | `TFLiteTextEmbeddingRunner` |
| 43 | `src/on_device/resilient_embedding_backend.dart` | `ResilientEmbeddingBackend` |
| 44 | `src/on_device/tokenizer.dart` | `TextTokenizer`, `WhitespaceHasherTokenizer` |
| 45 | `src/on_device/backend_embeddings_adapter.dart` | `BackendEmbeddingsAdapter` |
| 46 | `src/embedding_telemetry.dart` | `EmbeddingTelemetrySample`, `EmbeddingTelemetryRecorder` |
| 47 | `src/telemetry_collector.dart` | `TelemetryCollector` |
| 48 | `src/pipeline/memory_task.dart` | `MemoryTask`, `CaptureTask`, `EmbedTask` |
| 49 | `src/pipeline/pipeline_runner.dart` | `TaskPipeline` |
| 50 | `src/pipeline/legacy_task.dart` | `LegacyRetrievalTaskAdapter`, `LegacyTaskAdapter` |
| 51 | `src/memory_maintenance.dart` | `MemoryMaintenanceService` |

---

## 1. Models & Core Entities

### Export 1: `src/models/memory_node.dart`
Represents a memory, fact, message, concept, or document node in the cognitive graph.

- **Class**: `MemoryNode`
- **Key Fields**:
  - `id`: `Id` (Isar auto-increment)
  - `uuid`: `String` (Globally unique UUID)
  - `content`: `String` (Textual content of the memory)
  - `type`: `String?` (e.g., 'fact', 'message', 'concept')
  - `createdAt`: `DateTime`
  - `updatedAt`: `DateTime?`
  - `accessCount`: `int`
  - `modifiedAt`: `DateTime?`
  - `layer`: `int` (HiRAG hierarchical layer)
  - `embedding`: `MemoryEmbedding?`
  - `degree`: `Degree?`
  - `metadata`: `Map<String, dynamic>?` (Transient/unpersisted metadata)
- **Signature**:
  ```dart
  MemoryNode({
    required String content,
    String? type,
    DateTime? updatedAt,
    MemoryEmbedding? embedding,
    Degree? degree,
    Map<String, dynamic>? metadata,
    String? version,
    String? deviceId,
    bool isDeleted = false,
    DateTime? modifiedAt,
    int layer = 0,
    String? uuid,
    int accessCount = 0,
    DateTime? createdAt,
  });
  ```
- **Example**:
  ```dart
  final node = MemoryNode(
    content: 'The user resides in Madrid.',
    type: 'fact',
    metadata: {'source': 'user_profile'},
  );
  ```

### Export 2: `src/models/memory_edge.dart`
Represents a semantic relationship (edge) connecting two `MemoryNode`s.

- **Class**: `MemoryEdge`
- **Key Fields**:
  - `id`: `Id` (Isar auto-increment)
  - `fromNodeId`: `int` (ID of parent/source node)
  - `toNodeId`: `int` (ID of child/target node)
  - `relation`: `String` (Semantic relation, e.g. 'part_of', 'knows', 'summary_of')
  - `weight`: `double` (Relationship weight/strength)
  - `metadataJson`: `String?` (Serialized edge-level metadata)
- **Signature**:
  ```dart
  MemoryEdge({
    required int fromNodeId,
    required int toNodeId,
    required String relation,
    double weight = 1.0,
    String? metadataJson,
  });
  ```
- **Example**:
  ```dart
  final edge = MemoryEdge(
    fromNodeId: madridNodeId,
    toNodeId: userNodeId,
    relation: 'located_in',
    weight: 0.95,
  );
  ```

### Export 3: `src/models/memory_embedding.dart`
Encapsulates a generated high-dimensional semantic vector and its associated metadata.

- **Class**: `MemoryEmbedding`
- **Key Fields**:
  - `vector`: `List<double>` (The floating-point array representing the embedding)
  - `provider`: `String` (e.g. 'gemini', 'onnx_local')
  - `dimension`: `int` (Dimensions of the vector)
- **Signature**:
  ```dart
  MemoryEmbedding({
    required List<double> vector,
    required String provider,
    required int dimension,
  });
  ```

### Export 4: `src/models/degree.dart`
Tracks cognitive activation markers (importance, frequency, recency) for a node to support biologically inspired decay and consolidation.

- **Class**: `Degree`
- **Key Fields**:
  - `frequency`: `int` (Access frequency counter)
  - `importance`: `double` (Static/dynamic importance score, default `1.0`)
  - `lastAccessed`: `DateTime?` (Timestamp of last read/write access)
- **Signature**:
  ```dart
  Degree({
    int frequency = 0,
    double importance = 1.0,
    DateTime? lastAccessed,
  });
  ```

---

## 2. Core Memory Interface & Database

### Export 5: `src/memory_graph.dart`
The main Orchestrator API for interacting with the local-first universal agent memory graph. Integrates Isar and ObjectBox vector indexing.

- **Class**: `MemoryGraph`
- **Key Methods**:
  - `initialize()`: `Future<void>` (Indexes pre-existing DB items)
  - `storeNode(MemoryNode node)`: `Future<int>`
  - `storeNodeWithEmbedding(...)`: `Future<int>`
  - `getNode(int id)`: `Future<MemoryNode?>`
  - `deleteNode(int id)`: `Future<bool>`
  - `storeEdge(MemoryEdge edge)`: `Future<int>`
  - `getEdgesForNode(int nodeId)`: `Future<List<MemoryEdge>>`
  - `semanticSearch(...)`: `Future<List<({MemoryNode node, double distance, String provider})>>`
  - `hybridSearch(...)`: `Future<List<({MemoryNode node, double score})>>`
  - `explainRecall(...)`: `Future<String>` (Generates step-by-step recall reasoning)
- **Signature**:
  ```dart
  MemoryGraph(
    Isar isar, {
    required EmbeddingsAdapter embeddingsAdapter,
    VectorIndex? index,
  });
  ```
- **Example**:
  ```dart
  final graph = MemoryGraph(isarInstance, embeddingsAdapter: myEmbeddingsAdapter);
  await graph.initialize();
  final id = await graph.storeNodeWithEmbedding(
    content: "My dog is named Rufus.",
    type: "fact",
  );
  ```

---

## 3. Pluggable Embeddings Adapters

### Export 6: `src/embeddings_adapter.dart`
Contract for mapping content into a semantic vector space.

- **Class**: `EmbeddingsAdapter` (Abstract)
- **Key Members**:
  - `providerName`: `String` (e.g. 'gemini')
  - `dimension`: `int` (e.g., 384, 768)
  - `embed(String text)`: `Future<List<double>>`
  - `medicalNormalized(String text)`: `Future<List<double>>` (Default pre-processes and embeds)

### Export 7: `src/gemini_embeddings_adapter.dart`
Generates semantic embeddings using Google Generative AI (Gemini) cloud models.

- **Class**: `GeminiEmbeddingsAdapter`
- **Signature**:
  ```dart
  GeminiEmbeddingsAdapter({
    required String apiKey,
    String modelName = 'text-embedding-004',
    int dimension = 768,
  });
  ```

### Export 8: `src/fallback_embeddings_adapter.dart`
Combines multiple embeddings adapters. If the primary cloud adapter fails (e.g. due to being offline), it falls back to a secondary, resilient on-device backend.

- **Class**: `FallbackEmbeddingsAdapter`
- **Signature**:
  ```dart
  FallbackEmbeddingsAdapter({
    required EmbeddingsAdapter primary,
    required EmbeddingsAdapter fallback,
  });
  ```

### Export 9: `src/on_device_embeddings_adapter.dart`
An on-device embedding generator that utilizes a specific underlying `OnDeviceEmbeddingBackend`.

- **Class**: `OnDeviceEmbeddingsAdapter`
- **Signature**:
  ```dart
  OnDeviceEmbeddingsAdapter({
    required OnDeviceEmbeddingBackend backend,
    required int dimension,
    String provider = 'on-device-onnx',
  });
  ```

---

## 4. Vector Search & Indexing

### Export 10: `src/vector_index.dart`
Abstract index wrapper for high-performance approximate nearest neighbor (HNSW) search.

- **Class**: `VectorIndex` (Abstract)
- **Enum**: `VectorMetric` (`l2`, `cosine`, `dotProduct`)
- **Key Methods**:
  - `load()`: `Future<void>`
  - `addDocument(String id, String content, Float32List vector)`: `Future<void>`
  - `removeDocument(String id)`: `Future<void>`
  - `search(Float32List query, {required int topK})`: `Future<List<VectorSearchResult>>`
  - `clear()`: `Future<void>`

### Export 11: `src/vector_index_objectbox.dart`
ObjectBox execution of HNSW indexing. Uses explicit compiled vector sub-entities due to static compile-time dimensional constraints.

- **Class**: `ObjectBoxVectorIndex`
- **Key Entities**: `ObxVectorDoc` (768d), `ObxVectorDoc384` (384d)
- **Signature**:
  ```dart
  static VectorIndex open({
    required String namespace,
    required int dimension,
  });
  ```

---

## 5. Hierarchical Graph & HiRAG Extension

### Export 12: `src/hierarchical_graph.dart`
Provides extension methods for Hierarchical RAG (HiRAG) capabilities to form multi-tier abstraction layer graphs (e.g., base layers summarized into higher-order concept clusters).

- **Extension**: `HierarchicalMemoryGraph` on `MemoryGraph`
- **Key Methods**:
  - `autoSummarizeLayer(...)`: `Future<int>`
  - `createSummaryNode(...)`: `Future<int>`
  - `getNodesByLayer(int layer)`: `Future<List<MemoryNode>>`
  - `multiHopSearch(...)`: `Future<List<({MemoryNode node, List<MemoryNode> context})>>`
- **Example**:
  ```dart
  final summaryId = await graph.autoSummarizeLayer(
    layerIndex: 0,
    llmAdapter: myLlm,
  );
  ```

---

## 6. Language Models & Re-ranking Strategies

### Export 13: `src/llm_adapter.dart`
An abstract contract for generating strings from prompt payloads.

- **Class**: `LLMAdapter` (Abstract)
- **Key Methods**:
  - `generate(String prompt)`: `Future<String>`

### Export 14: `src/reranking_strategy.dart`
Defines the interface for sorting, re-scoring, or purging redundant/noisy retrieved node sets.

- **Class**: `ReRankingStrategy` (Abstract)
- **Key Methods**:
  - `reRank(List<({MemoryNode node, double score})> results, {String? query})`: `FutureOr<List<({MemoryNode node, double score})>>`

### Export 15: `src/rerankers/bm25_reranker.dart`
Re-ranks retrieved candidates using the lexical BM25 token-matching scoring algorithm. Excellent for enhancing lexical precision alongside semantic results.

- **Class**: `BM25ReRanker`
- **Signature**:
  ```dart
  BM25ReRanker({
    double k1 = 1.2,
    double b = 0.75,
  });
  ```

### Export 16: `src/rerankers/diversity_reranker.dart`
Penalizes similar results in the retrieval candidate set to maximize coverage over diverse aspects of a query.

- **Class**: `DiversityReRanker`
- **Signature**:
  ```dart
  DiversityReRanker({
    required double similarityThreshold,
  });
  ```

### Export 17: `src/rerankers/mmr_reranker.dart`
Calculates Maximal Marginal Relevance to dynamically balance retrieval precision with redundancy elimination.

- **Class**: `MMRReRanker`
- **Signature**:
  ```dart
  MMRReRanker({
    double lambda = 0.5,
  });
  ```

### Export 18: `src/rerankers/recency_reranker.dart`
Applies an exponential time decay or linear ranking boost based on the creation or modification timestamps of nodes.

- **Class**: `RecencyReRanker`
- **Signature**:
  ```dart
  RecencyReRanker({
    double decayFactor = 0.1,
  });
  ```

### Export 19: `src/rerankers/cross_encoder_reranker.dart`
Advanced neural re-ranking using an integrated or remote deep-learning cross-encoder model.

- **Classes**:
  - `CrossEncoderReranker` (Implements `ReRankingStrategy`)
  - `RemoteCrossEncoderAdapter` (Queries remote Cohere, HuggingFace, or custom API endpoints)
  - `LocalCrossEncoderAdapter` (Abstract for local models)
  - `HybridReranker` (Combines multiple strategies with weighted averages)
- **Signature**:
  ```dart
  CrossEncoderReranker({
    required CrossEncoderAdapter encoder,
    double minScore = 0.0,
    int? topK,
  });
  ```

---

## 7. Synchronization Manager & Backends

### Export 20: `src/sync/sync_manager.dart`
Orchestrates replication state, tracking modified timestamps and performing local changes pull/push tasks.

- **Class**: `SyncManager`
- **Key Methods**:
  - `sync()`: `Future<void>`

### Export 21: `src/sync/sync_backend.dart`
Interface definition for external synchronization backends.

- **Class**: `SyncBackend` (Abstract)
- **Key Methods**:
  - `push(List<Map<String, dynamic>> records)`: `Future<void>`
  - `pull(DateTime since)`: `Future<List<Map<String, dynamic>>>`

### Export 22: `src/sync/firebase_sync_backend.dart`
Replicates encrypted memory payloads to Google Firebase Realtime Database.

- **Class**: `FirebaseSyncBackend`
- **Signature**:
  ```dart
  FirebaseSyncBackend({
    required FirebaseDatabase database,
    required String path,
  });
  ```

### Export 23: `src/sync/websocket_sync_backend.dart`
Replicates encrypted memory payloads to real-time sync systems over standard WebSockets.

- **Class**: `WebSocketSyncBackend`
- **Signature**:
  ```dart
  WebSocketSyncBackend({
    required String url,
  });
  ```

### Export 24: `src/sync/cross_device_sync_manager.dart`
Extends default synchronization with real-time listeners, conflict resolution (LWW), and automatic AES encryption.

- **Class**: `CrossDeviceSyncManager`
- **Signature**:
  ```dart
  CrossDeviceSyncManager({
    required MemoryGraph graph,
    required SyncBackend backend,
    required String encryptionKey,
  });
  ```

---

## 8. Cognitive & Advanced Features (v0.5.0)

### Export 25: `src/memory_consolidation.dart`
Performs semantic clustering over memory segments and consolidates overlapping thoughts using an LLM.

- **Class**: `MemoryConsolidation`
- **Signature**:
  ```dart
  MemoryConsolidation(MemoryGraph graph);
  ```

### Export 26: `src/embeddings_cache.dart`
Maintains an in-memory Least Recently Used (LRU) cache of calculated embeddings to avoid redundant network requests.

- **Class**: `EmbeddingsCache`
- **Signature**:
  ```dart
  EmbeddingsCache({int maxSize = 1000});
  ```

### Export 27: `src/quality_metrics.dart`
Records performance indicators (p95 latency, average cosine distance, coverage) of the RAG retrieval pipeline.

- **Class**: `QualityMetrics`
- **Signature**:
  ```dart
  QualityMetrics(MemoryGraph graph);
  ```

### Export 28: `src/forgetting_mechanism.dart`
Simulates human memory decay by removing old, unimportant, or rarely accessed nodes over time.

- **Class**: `ForgettingMechanism`
- **Key Methods**:
  - `autoForget(...)`: `Future<ForgettingReport>`
  - `calculateImportance(...)`: `Future<double>`

### Export 29: `src/dynamic_layers.dart`
Dynamically clusters concepts into hierarchical HiRAG layers based on custom distance metrics.

- **Extension**: `DynamicLayerCreation` on `MemoryGraph`
- **Classes**: `LayerOrganization`, `LayerAnalysis`

### Export 30: `src/multi_modal_adapter.dart`
Encodes and retrieves diverse information modalities (images, audio, structured records) into the vector space.

- **Classes**:
  - `CLIPAdapter` (Text + Image embeddings)
  - `ImageBindAdapter` (Multi-sensory embeddings)
  - `RemoteMultiModalAdapter` (Queries APIs like Gemini or OpenAI multimodal endpoints)
  - `HybridMultiModalAdapter` (Adapts multimodal capabilities locally/remotely)
  - `StructuredDataProcessor` (Converts tabular datasets or JSON strings to linear text)

### Export 31: `src/agent_memory_types.dart`
Adapts the cognitive graph to segment Episodic (events), Semantic (knowledge), Procedural (instructions), and Working (context) memory.

- **Class**: `AgentMemoryTypes`
- **Signature**:
  ```dart
  AgentMemoryTypes(MemoryGraph graph);
  ```

### Export 32: `src/utils/encryption_utils.dart`
Performs core AES-256-GCM symmetric client-side encryption of serialized node data.

- **Class**: `EncryptionUtils`
- **Key Methods**:
  - `encrypt(String plainText, String key)`: `String`
  - `decrypt(String cipherText, String key)`: `String`

### Export 33: `src/privacy_features.dart`
Protects sensitive information via PII masking, k-anonymity checks, and adding differential privacy noise to vector embeddings.

- **Class**: `PrivacyFeatures`
- **Key Methods**:
  - `maskPII(String text, {String maskChar = '[REDACTED]'})`: `Future<String>`
  - `applyDifferentialPrivacy(...)`: `Future<List<double>>`

---

## 9. Modular RAG Pipeline Hooks (v0.6.0)

### Export 34: `src/pipeline_hooks.dart`
The framework for building composable RAG pipelines with 5 extensible hook stages.

- **Classes**:
  - `MemoryPipeline` (Pipeline orchestrator)
  - `PipelineContext` (Context object passed through hooks)
  - `RetrievedNode` (Candidate returned by retrieval stages)
  - `MemoryPipelineResult` (Final consolidated output)
  - `VectorRetrievalHook` (Built-in semantic lookup)
  - `HybridRetrievalHook` (Built-in hybrid search)
  - `MultiHopEnrichmentHook` (Built-in HiRAG explorer)
- **Interfaces**:
  - `QueryExpansionHook`
  - `RetrievalHook`
  - `ReRankingHook`
  - `EnrichmentHook`
  - `EvaluationHook`
- **Example**:
  ```dart
  final pipeline = MemoryPipeline()
    ..addRetrievalHook(VectorRetrievalHook(graph: graph, embeddings: adapter));
  ```

### Export 35: `src/session_context.dart`
Implements multi-tenant workspace isolation. Automatically filters queries to scope nodes by `sessionId` or `userId`.

- **Class**: `SessionContext`
- **Signature**:
  ```dart
  SessionContext({
    required String tenantId,
    String? userId,
    String? sessionId,
  });
  ```

### Export 36: `src/query_router.dart`
An agentic router that maps incoming queries to the optimal retrieval strategy based on light heuristics (vector, graph, hybrid, or hierarchical).

- **Class**: `QueryRouter`
- **Enum**: `QueryStrategy` (`vector`, `hybrid`, `temporal`, `graph`, `hierarchical`, `multiStrategy`, `clarify`)
- **Key Methods**:
  - `route(String query)`: `RoutingPlan`

---

## 10. On-Device Embeddings Engine

### Export 37: `src/on_device/on_device_embedding_backend.dart`
Contract for executing embedding generation locally on the device.

- **Class**: `OnDeviceEmbeddingBackend` (Abstract)
- **Key Methods**:
  - `embed(String text)`: `Future<List<double>>`

### Export 38: `src/on_device/hash_embedding_backend.dart`
A super fast, zero-dependency on-device backend that generates fixed-size hashed representation vectors for testing or low-resource devices.

- **Class**: `HashEmbeddingBackend`
- **Signature**:
  ```dart
  HashEmbeddingBackend({int dimension = 384});
  ```

### Export 39: `src/on_device/onnx_embedding_backend.dart`
Executes BERT or similar text embeddings locally using the ONNX Runtime library.

- **Class**: `OnnxEmbeddingBackend`
- **Signature**:
  ```dart
  OnnxEmbeddingBackend({
    required String modelPath,
    required String vocabPath,
  });
  ```

### Export 40: `src/on_device/onnx_text_embedding_runner.dart`
Lower-level runner orchestrating ONNX tensor shapes, memory allocation, and session calls.

- **Class**: `OnnxTextEmbeddingRunner`

### Export 41: `src/on_device/tflite_embedding_backend.dart`
Executes local embeddings using TensorFlow Lite models.

- **Class**: `TFLiteEmbeddingBackend`

### Export 42: `src/on_device/tflite_text_embedding_runner.dart`
Manages TensorFlow Lite interpreter sessions and input tensor transformations.

- **Class**: `TFLiteTextEmbeddingRunner`

### Export 43: `src/on_device/resilient_embedding_backend.dart`
Wraps multiple local backends. It falls back to a lightweight Hashing backend if ONNX/TFLite models fail to load or initialize.

- **Class**: `ResilientEmbeddingBackend`

### Export 44: `src/on_device/tokenizer.dart`
Implements tokenization routines, including vocabulary lookups, WordPiece segmentation, and standard whitespace token splitting.

- **Classes**:
  - `TokenizedText`
  - `TextTokenizer` (Abstract)
  - `WhitespaceHasherTokenizer`
  - `VocabularyTokenizer`

### Export 45: `src/on_device/backend_embeddings_adapter.dart`
Bridges on-device execution backends to the standard package-wide `EmbeddingsAdapter` interface.

- **Class**: `BackendEmbeddingsAdapter`

---

## 11. Telemetry & Performance Monitoring

### Export 46: `src/embedding_telemetry.dart`
Records detailed metrics (durations, token counts, error status) for single embedding generations.

- **Classes**:
  - `EmbeddingTelemetrySample`
  - `EmbeddingTelemetryRecorder`

### Export 47: `src/telemetry_collector.dart`
Aggregates telemetry records across pipelines and embeddings to produce comprehensive performance profiles.

- **Class**: `TelemetryCollector`
- **Key Methods**:
  - `record(PerformanceEvent event)`: `void`
  - `generateReport()`: `PerformanceReport`

---

## 12. Legacy Streaming Pipelines

### Export 48: `src/pipeline/memory_task.dart`
The legacy pipeline system where tasks are chained synchronously or asynchronously.

- **Classes**: `MemoryTask` (Abstract), `CaptureTask`, `ChunkTask`, `EmbedTask`, `LoadTask`

### Export 49: `src/pipeline/pipeline_runner.dart`
Executes legacy task chains with full event streaming and error reporting.

- **Class**: `TaskPipeline`

### Export 50: `src/pipeline/legacy_task.dart`
Provides bidirectional compatibility adapters to run legacy `MemoryTask` structures within the new RAG `pipeline_hooks.dart` framework.

- **Classes**: `LegacyRetrievalTaskAdapter`, `LegacyEnrichmentTaskAdapter`
- **Extension**: `LegacyTaskAdapter` on `MemoryTask`

---

## 13. System Maintenance

### Export 51: `src/memory_maintenance.dart`
Performs scheduled global upkeep operations (vector index vacuuming, cleaning up deleted tombstones, and purging orphaned edges).

- **Class**: `MemoryMaintenanceService`
- **Key Methods**:
  - `runMaintenance()`: `Future<MemoryMaintenanceSummary>`
- **Example**:
  ```dart
  final maintenance = MemoryMaintenanceService(graph);
  final summary = await maintenance.runMaintenance();
  print('Removed ${summary.purgedTombstonesCount} tombstones.');
  ```
