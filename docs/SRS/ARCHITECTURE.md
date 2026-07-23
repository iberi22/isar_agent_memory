# Architecture — isar_agent_memory

## Layers

```
┌──────────────────────────────────────────┐
│  MemoryGraph (CRUD + search)             │
├──────────────────────────────────────────┤
│  SessionContext (multi-tenant)           │
├──────────────────────────────────────────┤
│  QueryRouter (7 routing strategies)      │
├──────────────────────────────────────────┤
│  MemoryPipeline (5 hook stages)          │
├──────────────────────────────────────────┤
│  Re-ranking (5 strategies)               │
├──────────────────────────────────────────┤
│  Embeddings (Gemini, ONNX, Hash, etc.)   │
├──────────────────────────────────────────┤
│  Vector Index (ObjectBox HNSW 384/768)   │
├──────────────────────────────────────────┤
│  Persistence (Isar DB)                   │
└──────────────────────────────────────────┘
```

## Data Flow

```
Agent/LLM → MemoryGraph API
  ├─ storeNodeWithEmbedding() → Isar + ObjectBox
  ├─ semanticSearch() → ANN vector search
  ├─ hybridSearch() → vector + text fusion
  └─ memoryPipeline.run() → 5-stage RAG
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Vector DB | ObjectBox HNSW | On-device, fast, cross-platform |
| Graph DB | Isar | Embedded, fast, Dart-native |
| Pipeline | Hook-based | Extensible, single-responsibility |
| Session | Metadata scoped | No separate DB per tenant |
| Public API | Barrel file | Encapsulation, no src/ imports |
