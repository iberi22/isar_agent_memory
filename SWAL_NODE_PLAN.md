# isar_agent_memory → Nodo Móvil SWAL
## Plan de Unificación y Estabilización

---

## 1. Diagnóstico

### Problema
Actualmente hay **3 copias divergentes** de `isar_agent_memory`:

| Copia | Versión | Path | Estado |
|-------|---------|------|--------|
| Standalone | v0.5.0-beta | `~/proyectosSWAL/isar_agent_memory/` | ✅ Más avanzado arquitectónicamente |
| Pocket Cerebro | v0.2.2 | `~/proyectosSWAL/pocket_cerebro/packages/isar_agent_memory/` | 🟡 Fork con features únicos (48 exports) |
| OrionHealth (antigua) | v0.5.0-beta | `~/proyectosSWAL/OrionHealth/packages/isar_agent_memory/` (eliminada) | ✅ Ya unificada |

### Gap de APIs
- **55 símbolos compartidos** (core: MemoryGraph, MemoryNode, embeddings, vector index)
- **~55 solo en standalone** (pipeline_hooks, query_router, session_context, cross-encoder, HiRAG, quality, forgetting, agent types, privacy)
- **~55 solo en Pocket Cerebro** (multi-tenant, streaming pipeline, on-device backends, telemetry, maintenance, blockchain types)

---

## 2. Estrategia de Unificación

### Principio
El standalone (`iberi22/isar_agent_memory`) es el **source of truth**. Pocket Cerebro lo consume vía path dependency. NO crear una nueva copia interna.

### Lo que se porta al standalone
De Pocket Cerebro → al standalone:

| Categoría | Clases | Prioridad | Acción |
|-----------|--------|-----------|--------|
| **On-device backends** | HashEmbeddingBackend, TFLiteEmbeddingBackend, ONNXEmbeddingBackend, ResilientEmbeddingBackend, Tokenizer | 🟡 MEDIA | Portar a `lib/src/on_device/` + barrel export |
| **Embedding telemetry** | EmbeddingTelemetryRecorder, TelemetryCollector | 🟢 BAJA | Portar como hook opcional |
| **Pipeline adapters** | MemoryTask → convertidores para pipeline_hooks | 🟡 MEDIA | Crear adaptadores de compatibilidad |
| **Memory maintenance** | MemoryMaintenanceService → ya cubierto por ForgettingMechanism | ✅ YA CUBIERTO | Solo docs |
| **Multi-tenant** | TenantMemoryGraph → reemplazado por SessionContext | ✅ YA CUBIERTO | Solo docs |
| **Blockchain types** | MemoryToken, Vector6D → quedan en cerebro_blockchain_core | ❌ NO PORTAR | Persisten en Pocket Cerebro |

### Lo que se actualiza en Pocket Cerebro
| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | `path: packages/isar_agent_memory` → `path: ../isar_agent_memory` |
| 8 consumer files | Actualizar imports a nuevas APIs |
| Eliminar `packages/isar_agent_memory/` | Backup → eliminar |

---

## 3. Arquitectura Final: isar_agent_memory como Nodo Móvil SWAL

```
┌──────────────────────────────────────────────────────────────┐
│                    isar_agent_memory                          │
│                                                              │
│  CORE:                                                       │
│  ├── MemoryGraph              CRUD + search + graph          │
│  ├── MemoryNode / Edge        Modelos base                   │
│  ├── EmbeddingsAdapter        Interface + Gemini/ONNX/Hash   │
│  ├── VectorIndex              ObjectBox HNSW (384/768)       │
│  └── SessionContext           Aislamiento multi-tenant       │
│                                                              │
│  RAG AVANZADO:                                               │
│  ├── PipelineHooks           5 etapas extensibles            │
│  ├── QueryRouter             7 estrategias de ruteo          │
│  ├── ReRankingStrategies     BM25, MMR, Diversity, Recency   │
│  ├── CrossEncoderReranker    Cohere/HF/Jina HTTP             │
│  └── HiRAG                   Multi-hop, dynamic layers       │
│                                                              │
│  MEMORIA COGNITIVA:                                          │
│  ├── AgentMemoryTypes        Episodic/Semantic/Procedural    │
│  ├── MemoryConsolidation     Clustering + dedup              │
│  ├── ForgettingMechanism     Decay + LRU + importancia       │
│  ├── QualityMetrics          Latencia + relevancia           │
│  └── EmbeddingsCache         LRU cache                       │
│                                                              │
│  SINCRONIZACIÓN:                                             │
│  ├── SyncManager             Export/import cifrado           │
│  ├── CrossDeviceSyncManager  Firebase + WebSocket            │
│  └── Memoria P2P             Via edge-mesh (futuro)          │
│                                                              │
│  PRIVACIDAD:                                                 │
│  ├── PrivacyFeatures         PII masking, diff. privacy     │
│  ├── EncryptionUtils         AES-256-GCM                     │
│  └── EncryptionService       Sync encryption                 │
│                                                              │
│  MULTI-MODAL:                                                │
│  ├── RemoteMultiModalAdapter OpenAI/Gemini HTTP              │
│  └── HybridMultiModalAdapter Delegación por modalidad        │
│                                                              │
│  ON-DEVICE (portado de Pocket Cerebro):                      │
│  ├── OnDeviceEmbeddingBackends  Hash/TFLite/ONNX/Resilient   │
│  ├── EmbeddingTelemetry      Métricas de embedding           │
│  └── Tokenizer               WordPiece + extensible          │
└──────────────────────────────────────────────────────────────┘
         │
         ▼ sync via edge-mesh
┌──────────────────────────────────────────────────────────────┐
│                    XAVIER (Rust)                              │
│           Cognitive Memory Runtime · Server-side             │
│           API REST :8006 · MCP · Agentes · Mesh              │
└──────────────────────────────────────────────────────────────┘
```

### Flujo de un Nodo Móvil SWAL

```
Pocket Cerebro / OrionHealth (Flutter app)
  │
  ├── isar_agent_memory ← local-first, offline-capable
  │     ├── Guarda nodos localmente (Isar DB)
  │     ├── Indexa vectores (ObjectBox HNSW)
  │     ├── Pipeline RAG local
  │     └── SessionContext aisla por usuario
  │
  ├── edge-mesh ← P2P sync cuando hay red
  │     ├── Sincroniza con Xavier (servidor)
  │     ├── Sincroniza con otros nodos (P2P)
  │     └── Resolución de conflictos (LWW)
  │
  └── Xavier (cuando online)
        ├── Memoria compartida multi-dispositivo
        ├── Agentes server-side
        └── Governance (Maloca)
```

---

## 4. Plan de Ejecución

### Fase A: Portar on-device backends de Pocket Cerebro al standalone
1. Copiar `on_device/` directory (hash, TFLite, ONNX backends)
2. Agregar barrel exports
3. Verificar compatibilidad con `OnDeviceEmbeddingsAdapter` existente

### Fase B: Portar embedding telemetry
1. Copiar `EmbeddingTelemetryRecorder`, `TelemetryCollector`
2. Conectar como hook opcional en pipeline

### Fase C: Crear adaptadores de pipeline
1. `MemoryTaskAdapter` que envuelve el nuevo `MemoryPipeline` para compatibilidad
2. Mantener API `MemoryTask` como wrapper sobre hooks

### Fase D: Unificar Pocket Cerebro
1. Backup de la copia actual
2. Eliminar `packages/isar_agent_memory/` del monorepo
3. Actualizar `pubspec.yaml` → `path: ../isar_agent_memory`
4. Actualizar 8 consumer files a las nuevas APIs

### Fase E: Testear integración completa
1. `dart pub get` en Pocket Cerebro
2. Compilar todos los paquetes
3. Ejecutar tests

---

## 5. Resumen de Archivos a Modificar

| Proyecto | Archivos | Acción |
|----------|----------|--------|
| Standalone | `lib/src/on_device/*.dart` (nuevos) | Portar backends |
| Standalone | `lib/src/telemetry/*.dart` (nuevos) | Portar telemetry |
| Standalone | `lib/isar_agent_memory.dart` | + exports |
| Pocket Cerebro | `pubspec.yaml` | path update |
| Pocket Cerebro | `packages/isar_agent_memory/` | eliminar |
| Pocket Cerebro | 8 consumer files | API updates |
