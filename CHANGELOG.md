# Changelog

## 0.2.2 - 2025-08-18

- **New Feature**: Added `OnDeviceEmbeddingsAdapter` using `onnxruntime` for privacy-first, local embedding generation.
- **New Feature**: Implemented a basic `WordPieceTokenizer` for BERT-based models.
- **Improvement**: Enhanced `MemoryGraph` robustness with a fallback mechanism (linear scan) when vector index operations fail (e.g., dimension mismatch).
- **Improvement**: Added explicit dimension validation in `ObjectBoxVectorIndex` to prevent native crashes.
- **Documentation**: Translated `README.md` and `TASKS.md` to 100% English. Added instructions for On-Device Embeddings.
- **Dependencies**: Updated `langchain` to `^0.8.0`, `objectbox` to `^5.0.0`, `langchain_google` to `^0.7.0`, and added `onnxruntime` `^1.4.1`.
- **Refactor**: Removed deprecated `vector_index_dvdb.dart`.

## 0.2.1 - 2025-08-17

- CI/CD: Added `publish-to-pub-dev.yml` workflow for automated publishing on release creation or manual dispatch.
- Credentials: Documented usage of `PUB_CREDENTIALS_JSON` secret.
- Maintenance: Minor release preparation and local validation.

## 0.2.0 - 2025-08-17

- **Major Cleanup**: Removed DVDB as a vector backend.
  - Deleted `dvdb` dependency and public export.
  - Retained `vector_index_dvdb.dart` as a deprecated stub (now removed in 0.2.2).
  - Established ObjectBox as the sole supported on-device ANN (HNSW) backend.
- **Testing**:
  - Introduced `InMemoryVectorIndex` for plugin-free unit testing.
  - Removed `isar_flutter_libs` from the test subproject.
  - Fixed similarity metric consistency (cosine/L2/dot) in memory index.
- **Documentation**:
  - Cleaned up references to DVDB in docs.
  - Clarified ObjectBox default usage.
  - Fixed linting issues.

## 0.1.2 - 2025-07-10

- Fix: Resolved JavaScript error in Isar generated files by integrating `build_runner`.

## 0.1.1 - 2025-07-10

- Documentation: Added comprehensive dartdoc comments to public APIs.
- Linting: Fixed various linting and formatting issues.
- Publishing: Corrected pub.dev topics for successful publication.

## 0.1.0 - 2025-07-09

- Initial release: Isar agent memory graph with ANN search, explainability, robust tests, and modern CI/CD automation (Coderabbit, Renovate, Dependabot, Jules).
