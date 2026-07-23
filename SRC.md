# SRC — Source Code Reference — isar_agent_memory

> **Protocol:** GitCore 3.8.0
> **Updated:** 2026-07-22
> **Completeness:** structure 100%

## 1. Overview

**isar_agent_memory** — Agentic memory engine for Dart/Flutter.

| Field | Value |
|-------|--------|
| Path | `~/proyectosSWAL/isar_agent_memory` |
| Stack | Dart, Flutter, Isar, ObjectBox |
| Protocol | GitCore 3.8.0 |
| Package | pub.dev (pending v0.6.0) |
| License | MIT |

## 2. Directory structure

```
lib/
  isar_agent_memory.dart    # Barrel (51 exports)
  src/
    memory_graph.dart       # Core CRUD + search
    embeddings_adapter.dart # Provider interface
    gemini_embeddings_adapter.dart
    fallback_embeddings_adapter.dart
    on_device_embeddings_adapter.dart
    vector_index.dart       # Vector search interface
    vector_index_objectbox.dart # ObjectBox HNSW
    hierarchical_graph.dart # HiRAG extension
    dynamic_layers.dart     # Layer organization
    llm_adapter.dart        # LLM interface
    reranking_strategy.dart # Re-ranking interface
    pipeline_hooks.dart     # RAG pipeline (5 hooks)
    session_context.dart    # Multi-tenant isolation
    query_router.dart       # Agentic router (7 strategies)
    agent_memory_types.dart # Episodic/semantic/procedural/working
    memory_consolidation.dart
    forgetting_mechanism.dart
    quality_metrics.dart
    embeddings_cache.dart
    multi_modal_adapter.dart
    privacy_features.dart
    embedding_telemetry.dart
    telemetry_collector.dart
    memory_maintenance.dart
    models/
      memory_node.dart / .g.dart
      memory_edge.dart / .g.dart
      memory_embedding.dart / .g.dart
      degree.dart / .g.dart
    rerankers/
      bm25_reranker.dart
      mmr_reranker.dart
      diversity_reranker.dart
      recency_reranker.dart
      cross_encoder_reranker.dart
    sync/
      sync_manager.dart
      sync_backend.dart
      firebase_sync_backend.dart
      websocket_sync_backend.dart
      cross_device_sync_manager.dart
      encryption_service.dart
    on_device/
      on_device_embedding_backend.dart
      hash_embedding_backend.dart
      onnx_embedding_backend.dart
      onnx_text_embedding_runner.dart
      tflite_embedding_backend.dart
      tflite_text_embedding_runner.dart
      resilient_embedding_backend.dart
      tokenizer.dart
      backend_embeddings_adapter.dart
    pipeline/
      memory_task.dart
      pipeline_runner.dart
      legacy_task.dart
    utils/
      encryption_utils.dart
      word_piece_tokenizer.dart
test/                     # 14 test files
example/                  # Basic usage example
```

## 3. Modules

| Module | File | Status |
|--------|------|--------|
| Core graph | `memory_graph.dart` | ✅ Stable |
| Embeddings | `embeddings_adapter.dart`, gemini, on_device, fallback | ✅ Stable |
| Vector index | `vector_index.dart`, `vector_index_objectbox.dart` | ✅ Stable (384/768) |
| HiRAG | `hierarchical_graph.dart`, `dynamic_layers.dart` | ✅ Stable |
| Re-ranking | `reranking_strategy.dart`, 5 strategies | ✅ Stable |
| Pipeline RAG | `pipeline_hooks.dart` | ✅ New (v0.6.0) |
| Session | `session_context.dart` | ✅ New (v0.6.0) |
| Router | `query_router.dart` | ✅ New (v0.6.0) |
| Cognitive memory | `agent_memory_types.dart`, consolidation, forgetting, quality | ✅ Stable |
| Sync | `sync/` (Firebase, WebSocket, encryption) | ✅ Beta |
| On-device | `on_device/` (Hash, TFLite, ONNX, Resilient) | ✅ Ported |
| Telemetry | `embedding_telemetry.dart`, `telemetry_collector.dart` | ✅ Ported |
| Multi-modal | `multi_modal_adapter.dart` | ✅ Stable |
| Privacy | `privacy_features.dart` | ✅ Stable |
| Legacy pipeline | `pipeline/` (memory_task, pipeline_runner) | ✅ Compat |

## 4. External Dependencies

| Dependency | Version | Purpose |
|-----------|---------|---------|
| isar | ^3.1.0+1 | Embedded DB |
| objectbox | ^5.0.0 | HNSW vector index |
| google_generative_ai | ^0.4.7 | Gemini embeddings |
| onnxruntime | ^1.4.1 | On-device inference |
| langchain | ^0.8.0 | LLM workflows |
| cryptography | ^2.9.0 | AES-256-GCM encryption |
| firebase_core/database | ^2.24.2 | Sync backend |
| web_socket_channel | ^2.4.0 | WebSocket sync |
| http | ^1.1.0 | HTTP APIs |

## 5. GitCore Integration Points

- `.gitcore/features.json` — feature tracking
- `.gitcore/planning/PLANNING.md` — active plan
- `AGENTS.md` — agent instructions
- `docs/SRS/` — requirements
