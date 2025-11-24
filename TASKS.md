---
Description: Implementation plan and priority improvements
---

# Current Sprint: 100% On-Device Embeddings Adapter (Top Priority)

General Status: On-device first. Cloud (Gemini) only as fallback.

## Sprint Objectives

- Implement `OnDeviceEmbeddingsAdapter` (TFLite or ONNX Runtime) with a compact model (256–384 dims) and INT8 support.
- Investigate and document: memory consumption, inference times, compatibility by device/ABI, and multi-app synchronization.
- Maintain ObjectBox Vector Search (HNSW) as the ANN backend and validate end-to-end performance.

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
   - Client-side encryption (user key), versioning, reconciliation (LWW/CRDT), and semantic deduplication.
   - Background synchronization of embeddings and metadata with quotas/thresholds.

5. **Benchmarks and Quality**
   - Microbenchmarks for embed/search (latency and throughput) and accuracy sanity checks (semantic pairs).
   - Stress and concurrency tests (ingestion + simultaneous search).

6. **Hybrid and Re-rank (Phase 2)**
   - Add BM25/FTS (SQLite) for recall and MMR fusion.
   - Compact on-device re-ranker over top-K results.

## Deliverables

- [x] Functional on-device adapter + usage example.
- Resource guide and limits, TFLite vs ONNX comparison table.
- Reproducible benchmarks and report.
- Synchronization design and implementation plan.

## Initial Research Notes

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

## Release 0.2.2 (In Progress)

- [x] Clean repo binaries/artifacts: `.dart_tool/`, `isar.dll`, `example/isar.dll`, `*db/`, `isar_agent_memory_tests/testdb/`.
- [x] Confirm `pubspec.yaml` version `0.2.2` and updated `CHANGELOG.md`.
- [x] Implement `OnDeviceEmbeddingsAdapter` using ONNX Runtime.
- [ ] Execute manual workflow `.github/workflows/publish-to-pub-dev.yml` on `main`.
- [ ] Verify publication on pub.dev (`isar_agent_memory 0.2.2`).
- [ ] Create tag/release (`v0.2.2`).

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
