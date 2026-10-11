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

<!-- SWAL-ROUTING-START -->
## SWAL Routing Minimalista (SDD Hibrido F1)
> Antes de crear `.gitcore/sdd/` aplica routing organico (gentle-ai v2.3.0).
> - **Direct inline**: 1-3 files trivial -> inline sin delegar, sin SDD
> - **Delegated direct**: 4+ files o 2+ non-trivial -> delegate_task con Xavier skill search, sin SDD
> - **Optional SDD**: ambiguedad alta -> proponer SDD opcional, si SI crear `.gitcore/sdd/specs/###-feat/onepage.md` (1 pagina spec P1 + plan HOW minimo + tasks [P])
> Ver skill `sdd-hibrido` (`~/.hermes/skills/sdd-hibrido/references/routing.md`). `rm -rf .gitcore/sdd` limpia sin tocar features.json.
<!-- SWAL-ROUTING-END -->

<!-- SWAL-REGISTRY-START -->
## Skill Registry + Xavier Indexer (F1b)
> Skills viven FUERA de `.gitcore` (global `~/.hermes/skills` + proyecto `.skills/`). GitCore solo referencia via `.atl/skill-registry.md` + cache `.skill-registry.cache.json` y opcional `.gitcore/skill-registry.json`.
> - Refresh: `~/.hermes/scripts/skill-registry-refresh.sh --cwd <proyecto>`
> - Index: `~/.hermes/scripts/xavier-index-skills.sh --cwd <proyecto>` (Xavier tags [skill])
> - Antes de delegar: `xavier_search(tags=[skill]) -> skill_view(paths)`
> Ver skills `skill-registry` y `xavier-skill-indexer`.
<!-- SWAL-REGISTRY-END -->

<!-- SWAL-SDD-START -->
## SDD One-Page + SRS Mapping
> Spec efimero `.gitcore/sdd/specs/###-feat/onepage.md` referencia `REQ-xxx` durable de `docs/SRS/REQUIREMENTS.md` (IEEE 830 reduced). Drift detector `srs-src-drift-detector` mantiene traceabilidad. Docs humanos estables en `docs/`, specs AI en `.gitcore/sdd/` aislado.
<!-- SWAL-SDD-END -->


