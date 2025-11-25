---
Description: Implementation plan and priority improvements
---

# Current Status: v0.4.0 In Development

**Release v0.4.0 (2025-11-25)** includes:
- ✅ HiRAG Phase 2 (Automatic LLM-based summarization, multi-hop retrieval)
- ✅ Cross-device sync backends (Firebase/WebSocket integration)
- ✅ Re-ranking strategies (BM25, MMR, Diversity, Recency)
- ✅ Advanced retrieval methods

## Completed Sprint: HiRAG Phase 2 & Advanced Retrieval

### HiRAG Phase 2 - COMPLETED ✅

1. **Automatic Summarization** ✅
   - [x] Integrate LLM-based automatic summarization via `LLMAdapter` interface
   - [x] Configurable prompt templates for custom summarization
   - [x] Automatic relationship creation (`summary_of` and `part_of`)
   - [x] Layer-based aggregation and node grouping

2. **Multi-Hop Retrieval** ✅
   - [x] Layer-aware semantic search with context enrichment
   - [x] Configurable search depth (maxHops parameter)
   - [x] Hierarchical traversal following `summary_of` relationships
   - [x] Result enrichment with parent context nodes

3. **Advanced Relationships** ✅
   - [x] Support for `summary_of` and `part_of` relation types
   - [x] Bidirectional relationship traversal
   - [x] Integration with multi-hop search

### Cross-Device Sync - COMPLETED ✅

1. **Backend Abstraction** ✅
   - [x] `SyncBackend` interface for pluggable backends
   - [x] Factory pattern for backend selection
   - [x] Stream-based real-time synchronization

2. **Firebase Backend** ✅
   - [x] Firebase Realtime Database integration
   - [x] Anonymous and API key authentication
   - [x] Encrypted snapshot publishing
   - [x] Real-time change subscriptions

3. **WebSocket Backend** ✅
   - [x] Custom WebSocket server integration
   - [x] Heartbeat/keep-alive mechanism
   - [x] Bidirectional synchronization
   - [x] Automatic fallback from Firebase

4. **Sync Management** ✅
   - [x] `CrossDeviceSyncManager` extending `SyncManager`
   - [x] Automatic backend initialization
   - [x] LWW (Last-Write-Wins) conflict resolution
   - [x] Encrypted snapshot merge

### Re-ranking & Advanced Retrieval - COMPLETED ✅

1. **Re-ranking Strategies** ✅
   - [x] `ReRankingStrategy` interface
   - [x] BM25 re-ranker (term frequency-based)
   - [x] MMR re-ranker (Maximal Marginal Relevance)
   - [x] Diversity re-ranker (maximize variety)
   - [x] Recency re-ranker (favor recent nodes)

2. **Integration** ✅
   - [x] `semanticSearchWithReRanking()` in `MemoryGraph`
   - [x] `hybridSearchWithReRanking()` in `MemoryGraph`
   - [x] Flexible re-ranker composition

3. **Testing** ✅
   - [x] Unit tests for all re-ranking strategies
   - [x] Integration tests for HiRAG Phase 2
   - [x] Sync conflict resolution tests
   - [x] Multi-hop retrieval tests

## Next Sprint: Production Hardening & Performance

### Priority Tasks

1. **Performance Optimization**
   - [ ] Implement caching for multi-hop search intermediate results
   - [ ] Optimize BM25 IDF calculation with memoization
   - [ ] Add batch operations for large-scale summarization
   - [ ] Profile and optimize vector search performance

2. **Production Sync Server**
   - [ ] Reference WebSocket server implementation
   - [ ] Docker deployment configuration
   - [ ] Load balancing and scaling guidelines
   - [ ] Monitoring and health checks

3. **Enhanced Testing**
   - [ ] Generate mocks for WebSocket tests (build_runner)
   - [ ] Increase test coverage to >80%
   - [ ] Add integration tests for Firebase backend
   - [ ] Performance benchmarks for re-ranking strategies

4. **Documentation**
   - [ ] Migration guide from v0.3.0 to v0.4.0
   - [ ] Best practices for LLM adapter implementation
   - [ ] Sync backend deployment guide
   - [ ] Performance tuning recommendations

## Technical Tasks

1. **On-Device Backend Selection**
   - [x] Evaluate `tflite_flutter` vs `onnxruntime` (Selected `onnxruntime`).
   - [x] Choose a base model (e.g., MiniLM/E5-small) and prepare export (ONNX/TFLite) + INT8 quantization.

2. **Adapter and Utilities**
   - [x] Create `OnDeviceEmbeddingsAdapter` with lazy initialization.
   - [x] Implement WordPiece tokenizer (`WordPieceTokenizer`).
   - [x] Handle versions/dimensions per `namespace` and optional L2 normalization.
   - [ ] Telemetry: p50/p95 latencies, peak memory, errors.

3. **Resource Investigation (Document in README)**
   - [x] Document model download and usage instructions.
   - [ ] Model size (fp32 vs INT8) and RAM required during inference (model + buffers).
   - [ ] Storage cost for N vectors (fp32 vs INT8) and approximate HNSW overhead.
   - [ ] Device/ABI limits (armeabi-v7a, arm64-v8a) and split-ABI policies.

4. **Multi-App Synchronization (Design)**
   - [x] Client-side encryption (user key), versioning, reconciliation (LWW/CRDT), and semantic deduplication.
   - [ ] Background synchronization of embeddings and metadata with quotas/thresholds.

5. **Benchmarks and Quality**
   - [x] Microbenchmarks for embed/search (latency and throughput) via GitHub Actions.
   - [ ] Stress and concurrency tests (ingestion + simultaneous search).

6. **Hybrid and Re-rank (Phase 2)**
   - [x] Add BM25/FTS (Isar Filter) for recall and fusion (RRF/Weighted).
   - [ ] Compact on-device re-ranker over top-K results.

## Deliverables

- [x] Functional on-device adapter + usage example.
- [x] Benchmark automation (GitHub Actions).
- [x] Sync Protocol Design Document (`doc/SYNC_PROTOCOL.md`).
- [x] Semantic Deduplication logic.
- [x] Hybrid Search implementation.
- [x] HiRAG Phase 1 (Layer-based organization, summary nodes, basic queries).

## Completed Releases

### Release 0.3.0 (2024-11-24) ✅

**Major Features:**
- Sync Protocol with AES-256-GCM encryption and LWW conflict resolution
- HiRAG Phase 1: Hierarchical knowledge organization
- Extended data models with UUID-based sync fields
- Integration tests for sync functionality

**Deliverables:**
- [x] `SyncManager` with encrypted export/import
- [x] `EncryptionService` for client-side encryption
- [x] `HierarchicalMemoryGraph` extension
- [x] Layer-based node organization
- [x] Summary node creation and queries
- [x] Documentation: `doc/SYNC_PROTOCOL.md`
- [x] Published to pub.dev

---

### Historical Research Notes

- **Model Memory**:
  - MiniLM/E5-small fp32: ~60–90 MB; INT8: ~15–25 MB.
  - `onnxruntime` AAR: ~7–12 MB (depending on EPs); `tflite_flutter`: ~2–3 MB.
- **Inference RAM**:
  - Peak ≈ model size + intermediate buffers (1.2–2.0× model size) per batch.
  - Small batch size (1–8) recommended for mid-range devices; measure p50/p95.
- **Index Storage**:
  - Vectors: N × d × bytes (fp32: 4B, int8: 1B). Example: 50k × 384 × 4 ≈ 76.8 MB; int8 ≈ 19.2 MB.
  - HNSW overhead approx: ~N × M × 8B (M≈16 default → ~6.4 MB for 50k).
- **Compatibility/ABIs**:
  - Android: arm64-v8a (recommended), armeabi-v7a (limited). Use split-ABI to reduce APK size.
  - Accelerators: NNAPI (variable by OEM), universal CPU fallback.
- **Synchronization (Multi-App)**:
  - Client encryption (user key), LWW/CRDT versioning, semantic deduplication.
  - Upload only metadata + embeddings (possibly int8) with quotas and incremental sync.
  - Optional: ObjectBox Sync if near-real-time and minimal conflict resolution is required.

---

## Release 0.2.3 (Upcoming)

- [ ] New features: Hybrid Search, Semantic Deduplication.
- [ ] Tools: Benchmarking script and workflow.
- [ ] Documentation: Sync Protocol Design.

---

## Release 0.2.3 (Completed - 2024-11-24)

- [x] Fix critical bugs from 0.2.2
- [x] Update CHANGELOG.md with all fixes
- [x] Optimize package size (exclude test_resources/ and tool/)
- [x] Update workflow to use Flutter instead of Dart
- [x] Create tag/release (v0.2.3)
- [x] Publish to pub.dev (isar_agent_memory 0.2.3)

## Release 0.2.2 (Completed - 2025-08-18)

- [x] Clean repo binaries/artifacts: `.dart_tool/`, `isar.dll`, `example/isar.dll`, `*db/`, `isar_agent_memory_tests/testdb/`.
- [x] Confirm `pubspec.yaml` version `0.2.2` and updated `CHANGELOG.md`.
- [x] Implement `OnDeviceEmbeddingsAdapter` using ONNX Runtime.
- [x] Execute manual workflow `.github/workflows/publish-to-pub-dev.yml` on `main`.
- [x] Verify publication on pub.dev (`isar_agent_memory 0.2.2`).
- [x] Create tag/release (`v0.2.2`).

---

## Completed Tasks (Summary)

- [x] Pluggable Vector Backend (`VectorIndex`) and `ObjectBoxVectorIndex` as default.
- [x] Embeddings Fallback (Gemini) and `FallbackEmbeddingsAdapter`.
- [x] `InMemoryVectorIndex` for tests (no natives), cosine/L2/dot metrics.
- [x] DVDB sanitization (code, docs, tests) and updated README/TASKS.
- [x] Version bump 0.2.0, `flat_buffers` and reinforced `.pubignore`.
- [x] Update dependencies to latest stable versions (LangChain 0.8.0, ObjectBox 5.0.0).
- [x] Translate documentation to English.
- [x] Implement On-Device Embeddings with ONNX Runtime.
