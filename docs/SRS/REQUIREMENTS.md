# SRS — isar_agent_memory

> **Software Requirements Specification**
> **Protocol:** GitCore 3.8.0
> **Updated:** 2026-07-22

## 1. Purpose

Provide a universal, local-first cognitive memory engine for Dart/Flutter AI agents. Graph-based, explainable, LLM-agnostic.

## 2. Scope

Mobile/edge memory layer for the SWAL ecosystem. Complement to Xavier (Rust server). Used by Pocket Cerebro and OrionHealth.

## 3. Functional Requirements

| ID | Requirement | Priority | Status |
|----|------------|----------|--------|
| FR-01 | Store/retrieve memory nodes with embeddings | P0 | ✅ |
| FR-02 | Semantic search (ANN via ObjectBox HNSW) | P0 | ✅ |
| FR-03 | Hybrid search (vector + text) | P1 | ✅ |
| FR-04 | Multi-hop retrieval (HiRAG) | P1 | ✅ |
| FR-05 | Pluggable embeddings (Gemini, ONNX, custom) | P0 | ✅ |
| FR-06 | Re-ranking (BM25, MMR, Diversity, Recency, CrossEncoder) | P1 | ✅ |
| FR-07 | Extensible RAG pipeline (5 hook stages) | P1 | ✅ |
| FR-08 | Agentic query router (7 strategies) | P1 | ✅ |
| FR-09 | Multi-tenant session isolation | P1 | ✅ |
| FR-10 | Episodic/semantic/procedural/working memory | P1 | ✅ |
| FR-11 | Memory consolidation and deduplication | P1 | ✅ |
| FR-12 | Automatic forgetting (decay, LRU, importance) | P1 | ✅ |
| FR-13 | Quality metrics (latency, relevance, coverage) | P2 | ✅ |
| FR-14 | Encrypted sync (Firebase/WebSocket, AES-256-GCM) | P1 | ✅ |
| FR-15 | On-device embedding backends (Hash, TFLite, ONNX, Resilient) | P1 | ✅ |
| FR-16 | Embedding telemetry | P2 | ✅ |
| FR-17 | Multi-modal embeddings (remote HTTP) | P2 | ✅ |
| FR-18 | PII masking and differential privacy | P2 | ✅ |
| FR-19 | Memory maintenance (prune by age/count) | P2 | ✅ |
| FR-20 | Local cross-encoder (ONNX) | P2 | ❌ |
| FR-21 | P2P sync via edge-mesh | P2 | ❌ |
| FR-22 | CI/CD pipeline | P1 | ❌ |
| FR-23 | Full test coverage (pipeline, router, session) | P1 | ❌ |

## 4. Non-Functional Requirements

| ID | Requirement | Target |
|----|------------|--------|
| NFR-01 | Offline-first | All features work without network |
| NFR-02 | Local persistence | Isar DB + ObjectBox HNSW |
| NFR-03 | LLM-agnostic | No hard dependency on any LLM provider |
| NFR-04 | Domain-agnostic | No business logic in core package |
| NFR-05 | Backward compatible | Legacy streaming pipeline preserved |

---

## REQ-001: Graph CRUD + search (feature core-graph)

- **Category:** Functional
- **Priority:** P0
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature core-graph)*

*Feature: `core-graph` · status: pending*

## REQ-002: Pluggable embeddings (Gemini, ONNX, Hash) (feature embeddings)

- **Category:** Functional
- **Priority:** P0
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature embeddings)*

*Feature: `embeddings` · status: pending*

## REQ-003: Vector search (ObjectBox HNSW 384/768) (feature vector-index)

- **Category:** Functional
- **Priority:** P0
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature vector-index)*

*Feature: `vector-index` · status: pending*

## REQ-004: HiRAG layers + multi-hop (feature hirag)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature hirag)*

*Feature: `hirag` · status: pending*

## REQ-005: 5 re-ranking strategies (feature reranking)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature reranking)*

*Feature: `reranking` · status: pending*

## REQ-006: Cross-encoder re-ranking (HTTP) (feature cross-encoder)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature cross-encoder)*

*Feature: `cross-encoder` · status: pending*

## REQ-007: Local cross-encoder (ONNX) (feature cross-encoder-local)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature cross-encoder-local)*

*Feature: `cross-encoder-local` · status: pending*

## REQ-008: RAG pipeline (5 hooks) (feature pipeline-hooks)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature pipeline-hooks)*

*Feature: `pipeline-hooks` · status: pending*

## REQ-009: Agentic query router (7 strategies) (feature query-router)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature query-router)*

*Feature: `query-router` · status: pending*

## REQ-010: Multi-tenant session isolation (feature session-context)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature session-context)*

*Feature: `session-context` · status: pending*

## REQ-011: Memory types + consolidation + forgetting (feature cognitive-memory)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature cognitive-memory)*

*Feature: `cognitive-memory` · status: pending*

## REQ-012: Encrypted sync (Firebase/WebSocket) (feature sync)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature sync)*

*Feature: `sync` · status: pending*

## REQ-013: P2P sync via edge-mesh (feature p2p-sync)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature p2p-sync)*

*Feature: `p2p-sync` · status: pending*

## REQ-014: On-device backends (Hash, TFLite, ONNX, Resilient) (feature on-device)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature on-device)*

*Feature: `on-device` · status: pending*

## REQ-015: Embedding telemetry (feature telemetry)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature telemetry)*

*Feature: `telemetry` · status: pending*

## REQ-016: Multi-modal embeddings (HTTP) (feature multi-modal)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature multi-modal)*

*Feature: `multi-modal` · status: pending*

## REQ-017: Privacy features (PII, differential privacy) (feature privacy)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature privacy)*

*Feature: `privacy` · status: pending*

## REQ-018: Legacy streaming pipeline (backward compat) (feature legacy-pipeline)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature legacy-pipeline)*

*Feature: `legacy-pipeline` · status: pending*

## REQ-019: Memory maintenance service (feature maintenance)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature maintenance)*

*Feature: `maintenance` · status: pending*

## REQ-020: CI/CD pipeline (feature ci-cd)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature ci-cd)*

*Feature: `ci-cd` · status: pending*

## REQ-021: Core tests (feature tests-core)

- **Category:** Functional
- **Priority:** P0
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature tests-core)*

*Feature: `tests-core` · status: pending*

## REQ-022: Pipeline/router/session tests (feature tests-pipeline)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature tests-pipeline)*

*Feature: `tests-pipeline` · status: pending*

## REQ-023: SessionContext tests (feature tests-session)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature tests-session)*

*Feature: `tests-session` · status: pending*

## REQ-024: Cross-encoder HTTP tests (feature tests-cross-encoder)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature tests-cross-encoder)*

*Feature: `tests-cross-encoder` · status: pending*

## REQ-025: Multi-modal HTTP tests (feature tests-multi-modal)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature tests-multi-modal)*

*Feature: `tests-multi-modal` · status: pending*

## REQ-026: On-device backend tests (feature tests-on-device)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature tests-on-device)*

*Feature: `tests-on-device` · status: pending*

## REQ-027: Embedding quality benchmarks (feature benchmarks)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature benchmarks)*

*Feature: `benchmarks` · status: pending*

## REQ-028: API documentation (feature docs-api)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature docs-api)*

*Feature: `docs-api` · status: pending*

## REQ-029: Complete demo app (feature example-app)

- **Category:** Functional
- **Priority:** P2
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature example-app)*

*Feature: `example-app` · status: pending*

## REQ-030: v0.6.0 pub.dev release (feature release)

- **Category:** Functional
- **Priority:** P1
- **SRS Status:** `active`
- **Files:** *(see .gitcore/features.json feature release)*

*Feature: `release` · status: pending*
