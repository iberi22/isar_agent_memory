# Changelog

## [0.6.0-dev] — 2026-07-22

### Added
- **RAG Pipeline**: 5-hook composable pipeline (MemoryPipeline with VectorRetrieval/ HybridRetrieval/MultiHopEnrichment hooks)
- **Agentic Query Router**: 7 routing strategies (vector, hybrid, temporal, graph, hierarchical, multiStrategy, clarify)
- **Multi-tenant Sessions**: SessionContext for session/user isolation via metadata scoping
- **Cross-Encoder Re-ranking**: Remote adapter (Cohere, HuggingFace, Jina via HTTP) + Local (ONNX) backends
- **Multi-modal Embeddings**: Remote adapter for OpenAI/Gemini multimodal APIs with MIME detection
- **On-Device Backends**: Hash, TFLite, ONNX, Resilient embedding backends with BackendEmbeddingsAdapter
- **Embedding Telemetry**: TelemetryRecorder + TelemetryCollector for monitoring embedding quality
- **Memory Maintenance**: Prune by sources, age, retention policies, orphan cleanup
- **P2P Sync Stub**: MeshSyncBackend for future edge-mesh integration
- **Encrypted Sync**: Firebase + WebSocket backends with AES-256-GCM (existing, stabilized)
- **Privacy Features**: PII masking, differential privacy, k-anonymity (existing, stabilized)
- **Cognitive Memory**: Episodic/semantic/procedural/working types with consolidation and forgetting (existing, stabilized)

### Fixed
- `MemoryNode` uuid non-nullable to prevent Isar crash
- ObjectBox vector dimension support (384/768/1536)

### Changed
- Removed medical domain contamination (MedicalMetadata, PatientPackage, BackendOperationLog)
- Unified 3 diverging copies (OrionHealth, Pocket Cerebro) into single source of truth
- Renamed old `MemoryPipeline` (streaming) to `TaskPipeline` for backward compat
- AGENTS.md: English documentation with GitCore v3.8.0 alignment
- SRC.md: Complete source code reference with GitCore protocol

## [0.5.0-beta] — 2026-03

### Added
- Initial MemoryGraph with Isar persistence
- ObjectBox HNSW vector index
- Gemini and ONNX embeddings adapters
- HiRAG hierarchical layers and multi-hop retrieval
- BM25, MMR, Diversity, Recency re-ranking
- Cross-device sync (Firebase, WebSocket)
- Explainability (semantic distance, activation, path tracing)
- Hybrid search (vector + text fusion)
