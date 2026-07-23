# isar_agent_memory — Documentación de Arquitectura y Cambios

## Estado Actual (v0.5.0-beta → v0.6.0-dev)

---

## 1. Unificación Repos (Paso 0)

### Problema
`isar_agent_memory` existía en dos copias divergentes:
- **Standalone** (`~/proyectosSWAL/isar_agent_memory/` → `iberi22/isar_agent_memory`)
- **Copia en monorepo** (`~/proyectosSWAL/OrionHealth/packages/isar_agent_memory/` → dentro de `iberi22/core-swal-pwa`)

Cada archivo `.dart` era diferente entre las dos copias. Los cambios en el standalone no llegaban a OrionHealth y viceversa.

### Solución
1. Backup de la copia → `/tmp/isar_agent_memory_backup`
2. Eliminación de `packages/isar_agent_memory/` del monorepo
3. `pubspec.yaml` actualizado: `path: packages/isar_agent_memory` → `path: ../isar_agent_memory`
4. 8 archivos Dart importan `package:isar_agent_memory` — resuelven igual con path al standalone

### Archivos modificados
- `OrionHealth/pubspec.yaml` — solo este archivo

---

## 2. Limpieza de Contaminación Médica (Fase 1)

### Problema
`isar_agent_memory` es un paquete **genérico** de memoria para agentes, pero contenía código específico del dominio médico de OrionHealth.

### Archivos eliminados (3)
| Archivo | Contenido |
|---------|-----------|
| `lib/src/models/medical_constants.dart` | Constantes de tipos médicos (kMedicalDiagnosis, kLabResult, etc.) |
| `lib/src/models/patient_package.dart` | Modelo PatientPackage con datos de paciente cifrados |
| `lib/src/models/backend_operation_log.dart` | Logs de operaciones con tenantId/patientId |

### Archivos modificados (4)
| Archivo | Cambio |
|---------|--------|
| `lib/src/models/memory_node.dart` | Eliminada clase `MedicalMetadata` y campo `medicalMetadata` |
| `lib/src/models/memory_node.g.dart` | Eliminada serialización de `MedicalMetadata` |
| `lib/src/memory_graph.dart` | Eliminados métodos: `storeMedicalNode()`, `storePatientPackage()`, `getPatientPackage()`, `logBackendOperation()` |
| `lib/isar_agent_memory.dart` | Eliminados 3 exports médicos |

### ⚠️ Datos médicos ahora en backup
Todo el código médico eliminado está disponible en:
```
/tmp/isar_agent_memory_backup/
```
Si OrionHealth necesita estos modelos, moverlos al proyecto OrionHealth directamente (no al package genérico).

---

## 3. Mejoras de Arquitectura (Fase 2)

### 3.1 Pipeline Hooks Genérico (`lib/src/pipeline_hooks.dart`) — NUEVO

**Inspiración**: Modular RAG patterns 2025-2026 (Hindsight, LangChain, Cognee)

**Arquitectura de 5 etapas**:

```
Query → [QueryExpansionHook] → [RetrievalHook] → [ReRankingHook] → [EnrichmentHook] → [EvaluationHook] → Result
```

| Hook | Propósito | Built-ins incluidos |
|------|-----------|-------------------|
| `QueryExpansionHook` | Expandir/descomponer/reescribir query | — |
| `RetrievalHook` | Fetch desde vector, BM25, graph, temporal | `VectorRetrievalHook`, `HybridRetrievalHook` |
| `ReRankingHook` | Re-score, filtrar, diversificar | (usar `ReRankingStrategy` existente) |
| `EnrichmentHook` | Añadir contexto, citas, explicaciones | `MultiHopEnrichmentHook` (HiRAG) |
| `EvaluationHook` | Decidir si aceptar, reintentar o pedir clarificación | — |

**Ejemplo de uso**:
```dart
final pipeline = MemoryPipeline()
  ..addHook(VectorRetrievalHook(graph: graph, embeddings: adapter))
  ..addHook(HybridRetrievalHook(graph: graph))
  ..addHook(MultiHopEnrichmentHook(graph: graph));

final result = await pipeline.run('user query', sessionId: 'session-1');
```

### 3.2 CrossEncoderReRanker exportado
Antes: existía en `lib/src/rerankers/cross_encoder_reranker.dart` pero no se exportaba.
Ahora: exportado en el barrel (`isar_agent_memory.dart`).

### 3.3 PrivacyFeatures exportado
Antes: comentado con TODO.
Ahora: exportado activamente. El código compila — no hay razón para ocultarlo.

---

## 4. Issues Médicos — Plan de Redirect

| Issue | Título | Estado | Acción |
|-------|--------|--------|--------|
| #39 | Medical RAG Pipeline | Open → **Close** | Ya existe en OrionHealth como `RagLlmService` + `IsarVectorStoreService`. Crear issue en OrionHealth si se necesita refactor. |
| #40 | Embedding Benchmark for Medical QA | Open → **Close** | No existe en OrionHealth. Crear issue allá si se necesita. |
| #42 | OrionHealth RAG integration path | Open → **Close** | Ya existe el path directo. Documentar la inconsistencia de re-ranking duplicado. |

---

## 5. Estado Actual de Pendientes

### ✅ Completado en Fase 3
- **ObjectBox dimension dinámica** — ✅ PR #46 merged. Factory pattern con `ObxVectorDoc` (768) y `ObxVectorDoc384` (384). Tests en `vector_dimension_test.dart`.
- **Session/user scoping** — ✅ `SessionContext` en `lib/src/session_context.dart`. Aislamiento multi-tenant por `sessionId`/`userId` via metadata filtering.
- **Query Router** — ✅ `QueryRouter` en `lib/src/query_router.dart`. 7 estrategias: vector, hybrid, temporal, graph, hierarchical, multiStrategy, clarify. Heurísticas ligeras sin dependencia LLM.

### ✅ Completado en Fase 4
- **ReRankingStrategy async-compatible** — ✅ Cambiado a `FutureOr<List<...>>`. Estrategias síncronas existentes siguen funcionando sin cambios. `memory_graph.dart` usa `await`.
- **Cross-Encoder re-ranking real** — ✅ `RemoteCrossEncoderAdapter` con soporte Cohere, HuggingFace, Jina. HTTP inyectable para testing. Retry con backoff. Sigmoid opcional para logits crudos.
- **CrossEncoderReranker** — ✅ Implementa `ReRankingStrategy` con `FutureOr`. Usa `scoreBatch` (1 llamada HTTP en vez de N).
- **HybridReranker** — ✅ Tipado correcto, normalización de scores, fusión ponderada.
- **Multi-modal remoto** — ✅ `RemoteMultiModalAdapter` con HTTP real (OpenAI/Gemini). Detección MIME por magic bytes. `embedStructured` usa `StructuredDataProcessor.jsonToText`.
- **HybridMultiModalAdapter.embedStructured** — ✅ Usa `jsonToText` en vez de `data.toString()`.

### Pendiente (próxima)
- **LocalCrossEncoderAdapter con ONNX** — Actualmente `UnimplementedError`. Requiere integración ONNX Runtime.
- **CLIPAdapter / ImageBindAdapter funcionales** — Actualmente `UnimplementedError`. Requieren descarga de modelos ONNX. Alternativa: `RemoteMultiModalAdapter`.
- **README duplicado** — Sección "Features" aparece dos veces.

---

## 6. Mapa de Dependencias Final

```
iberi22/isar_agent_memory (standalone)   ← SOURCE OF TRUTH
  └─ usado por iberi22/core-swal-pwa vía path: ../isar_agent_memory
  
iberi22/core-swal-pwa (monorepo)
  ├─ OrionHealth app
  ├─ packages/health_wallet/
  ├─ packages/medical_standards/
  └─ depende de isar_agent_memory vía path
```

**No más duplicación.** Un solo `isar_agent_memory`, un solo source of truth.
