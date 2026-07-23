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
