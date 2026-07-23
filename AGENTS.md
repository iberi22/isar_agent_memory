# AGENTS.md — isar_agent_memory

**Repo:** https://github.com/iberi22/isar_agent_memory
**Lenguaje:** Dart | **SDK:** >=3.2.0 <4.0.0
**Versión:** 0.6.0-dev

## Stack

- **DB:** Isar 3.1 (persistencia) + ObjectBox 5.0 (vectores HNSW)
- **Embeddings:** Gemini, ONNX, TFLite, Hash, Resilient
- **Sync:** Firebase Realtime, WebSocket, E2E encryption (AES-256-GCM)
- **LLM:** LangChain 0.8, google_generative_ai

## Comandos

```bash
flutter pub get
dart analyze lib/         # 0 errores reales (Isar codegen esperado)
dart test                 # tests puros Dart pasan sin codegen
```

## Layout

```
lib/
├── isar_agent_memory.dart    # Barrel (51 exports)
├── src/
│   ├── memory_graph.dart     # Core CRUD + búsqueda
│   ├── pipeline_hooks.dart   # RAG pipeline (5 hooks)
│   ├── query_router.dart     # Router agéntico (7 estrategias)
│   ├── session_context.dart  # Aislamiento multi-tenant
│   ├── embeddings_adapter.dart / gemini / on_device / fallback
│   ├── hierarchical_graph.dart / dynamic_layers.dart   # HiRAG
│   ├── reranking_strategy.dart + rerankers/ (5 estrategias)
│   ├── agent_memory_types.dart / consolidation / forgetting / quality
│   ├── multi_modal_adapter.dart / privacy_features.dart
│   ├── sync/ (manager, firebase, websocket, encryption)
│   ├── on_device/ (backends: hash, tflite, onnx, resilient)
│   ├── pipeline/ (legacy streaming + adapter) 
│   ├── embedding_telemetry.dart / telemetry_collector.dart
│   ├── memory_maintenance.dart
│   └── models/ (memory_node, edge, embedding, degree)
└── test/ (14 archivos, 4 requieren Flutter)
```

## Reglas

- NO mezclar lógica de negocio (médico, blockchain, etc.) en el package
- El barrel (`isar_agent_memory.dart`) es la API pública — NO importar `src/` directamente
- Preferir `FutureOr` para interfaces que pueden ser sync o async
- Tests puros Dart deben pasar sin `build_runner`
