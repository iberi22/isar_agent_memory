# AGENTS.md — isar_agent_memory

**Repo:** https://github.com/iberi22/isar_agent_memory
**Language:** Dart | **SDK:** >=3.2.0 <4.0.0
**Version:** 0.6.0-dev

## Stack

- **DB:** Isar 3.1 (persistence) + ObjectBox 5.0 (HNSW vector index)
- **Embeddings:** Gemini, ONNX, TFLite, Hash, Resilient
- **Sync:** Firebase Realtime, WebSocket, E2E encryption (AES-256-GCM)
- **LLM:** LangChain 0.8, google_generative_ai

## Commands

```bash
flutter pub get
dart analyze lib/         # 0 real errors (Isar codegen expected)
flutter test              # pure-Dart tests pass without codegen
```

## Layout

```
lib/
├── isar_agent_memory.dart    # Barrel (51 exports)
├── src/
│   ├── memory_graph.dart     # Core CRUD + search
│   ├── pipeline_hooks.dart   # RAG pipeline (5 hooks)
│   ├── query_router.dart     # Agentic router (7 strategies)
│   ├── session_context.dart  # Multi-tenant isolation
│   ├── embeddings_adapter.dart / gemini / on_device / fallback
│   ├── hierarchical_graph.dart / dynamic_layers.dart   # HiRAG
│   ├── reranking_strategy.dart + rerankers/ (5 strategies)
│   ├── agent_memory_types.dart / consolidation / forgetting / quality
│   ├── multi_modal_adapter.dart / privacy_features.dart
│   ├── sync/ (manager, firebase, websocket, encryption)
│   ├── on_device/ (backends: hash, tflite, onnx, resilient)
│   ├── pipeline/ (legacy streaming + adapter) 
│   ├── embedding_telemetry.dart / telemetry_collector.dart
│   ├── memory_maintenance.dart
│   └── models/ (memory_node, edge, embedding, degree)
└── test/ (14 files, 4 require Flutter)
```

## Rules

- DO NOT mix business logic (medical, blockchain, etc.) into this package
- The barrel (`isar_agent_memory.dart`) is the public API — do NOT import `src/` directly
- Use `FutureOr` for interfaces that may be sync or async
- Pure-Dart tests must pass without `build_runner`
