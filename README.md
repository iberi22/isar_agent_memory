# 🧠 isar_agent_memory

[![pub package](https://img.shields.io/pub/v/isar_agent_memory.svg)](https://pub.dev/packages/isar_agent_memory)
[![Build Status](https://github.com/iberi22/isar_agent_memory/actions/workflows/dart.yml/badge.svg)](https://github.com/iberi22/isar_agent_memory/actions)
[![Isar](https://img.shields.io/badge/db-isar-blue?logo=databricks)](https://isar.dev)
[![dvdb](https://img.shields.io/badge/ANN-dvdb-green?logo=databricks)](https://pub.dev/packages/dvdb)
[![LangChain](https://img.shields.io/badge/llm-langchain-yellow?logo=python)](https://pub.dev/packages/langchain)

> 🚧 **BETA**: This package is in active development. API may change. Feedback and PRs are welcome!

---

## 🚀 Quickstart

### 1. Add to your `pubspec.yaml`

```yaml
isar_agent_memory: ^0.1.0
```

### 2. Basic Usage

```dart
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/gemini_embeddings_adapter.dart';

final adapter = GeminiEmbeddingsAdapter(apiKey: '<YOUR_GEMINI_API_KEY>');
final isar = await Isar.open([
  MemoryNodeSchema, MemoryEdgeSchema
], directory: './exampledb');
final graph = MemoryGraph(isar, embeddingsAdapter: adapter);

// Store a node with embedding
final nodeId = await graph.storeNodeWithEmbedding(content: 'The quick brown fox jumps over the lazy dog.');

// Semantic search
final queryEmbedding = await adapter.embed('A fox jumps over a dog');
final results = await graph.semanticSearch(queryEmbedding, topK: 3);
for (final result in results) {
  print('Node: ${result.node.content}, Distance: ${result.distance.toStringAsFixed(3)}, Provider: ${result.provider}');
}

// Explain recall
if (results.isNotEmpty) {
  final explanation = await graph.explainRecall(results.first.node.id, queryEmbedding: queryEmbedding);
  print('Explain: $explanation');
}
```

---

## 🧬 Features

- Universal graph API: store, recall, relate, search, explain.
- Fast ANN search via dvdb (HNSW).
- Pluggable embeddings (Gemini, OpenAI, custom).
- Explainability: semantic distance, activation, path tracing.
- Robust tests and real-world example.
- Extensible: add metadata, new adapters, sync/export (planned).

---

## 🛠️ Integrations

- [Isar](https://isar.dev): Local, fast NoSQL DB for Dart/Flutter.
- [dvdb](https://pub.dev/packages/dvdb): ANN (HNSW) for fast vector search.
- [LangChain](https://pub.dev/packages/langchain): LLM/agent workflows.
- [Gemini](https://pub.dev/packages/google_generative_ai): Embeddings provider.

---

## 🛠️ Troubleshooting

### Isar Native Library (`isar.dll`) Loading Failure in Tests

**Problem:**
When running `flutter test` within the `isar_agent_memory_tests` subproject on a Windows environment (both locally and in GitHub Actions), the tests may fail with an error similar to `Invalid argument(s): Failed to load dynamic library '...\isar.dll'`.

This occurs because the standard Flutter test runner sometimes fails to automatically locate and load the native Isar binary provided by the `isar_flutter_libs` package.

**Solution:**
A robust, programmatic workaround has been implemented directly within the `test/memory_graph_test.dart` file. The `setUpAll` block for these tests now includes logic that:
1. Attempts to initialize Isar normally.
2. If it catches a `Failed to load dynamic library` error, it automatically...
3. Locates the `package_config.json` file to find the exact path of the `isar_flutter_libs` package in the local system's pub cache.
4. Copies the correct `isar.dll` from the package's `windows` directory into the root of the test project.
5. Retries the Isar initialization, which now succeeds.

This ensures that the tests are self-contained and run reliably across different Windows machines and in the CI/CD pipeline without requiring manual configuration.

---

## ⚠️ Known Issues

- The `dvdb` package currently contains a typo (`searchineSimilarity`) that can cause ANN searches to return no results. `MemoryGraph.semanticSearch` now falls back to a brute-force L2 scan until the library is fixed.
- Before running the tests locally you must expose your Gemini API key:

```bash
export GEMINI_API_KEY=<YOUR_KEY>
dart test
```

---

## 🧪 Testing

- Run unit tests:

```sh
dart test
```

- Run example integration:

```sh
dart run example/main.dart
```

---

## 📦 Publishing

- This package is **BETA** and API may change.
- To publish, run:

```sh
dart pub publish --dry-run
```

---

## 🤝 Contributing

PRs, issues, and feedback are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) when available.

---

## ⚖️ License

MIT

---

> **isar_agent_memory** is not affiliated with Isar, dvdb, LangChain, Gemini, or OpenAI. Names/logos are for reference only.

---

### 🏷️ Tags

`isar` `dvdb` `langchain` `embeddings` `memory` `agents` `llm` `flutter` `dart`

---

### 🚧 BETA Notice

This package is under active development. Expect breaking changes before v1.0.0. Use in production at your own risk. Feedback is highly appreciated!

A universal, local-first cognitive memory package for LLMs and AI agents in Dart/Flutter. Inspired by [Cognee](https://github.com/topoteretes/cognee) and [Graphiti](https://github.com/getzep/graphiti), but portable, explainable, and LLM-agnostic.

---

## Overview

**isar_agent_memory** provides a robust, explainable, and extensible memory system for agents and LLMs. It combines a universal graph (nodes, edges, metadata) with efficient vector search (ANN via [dvdb](https://pub.dev/packages/dvdb)), pluggable embeddings, and advanced explainability for agent reasoning.

- **Universal graph**: Store facts, messages, concepts, and relations.
- **Efficient semantic search**: ANN (HNSW) for context retrieval and recall.
- **Pluggable embeddings**: Gemini, OpenAI, or your own.
- **Explainability**: Trace why a memory was recalled (semantic distance, activation, paths).
- **LLM-agnostic**: Use with any agent, chatbot, or LLM workflow.

```mermaid
+-------------------+
|   Agent / LLM     |
+-------------------+
         |
         v
+-------------------+
|  MemoryGraph API  |
+-------------------+
         |
         v
+-------------------+         +----------------------+
|  Isar (Graph DB)  | <-----> |  dvdb (ANN Vector DB)|
+-------------------+         +----------------------+
         |                               |
         v                               v
   Nodes, Edges,                 Embeddings, Index
   Metadata                      (HNSW, fast search)
```

- **MemoryGraph** is the main API: store, recall, relate, search, explain.
- **Isar** stores nodes, edges, metadata, activation info.
- **dvdb** provides fast semantic search via ANN (HNSW index).
- **EmbeddingsAdapter** lets you plug in Gemini, OpenAI, or custom providers.

---

## Quickstart

### 1. Add to your `pubspec.yaml`

```yaml
isar_agent_memory:
  path: ./packages/isar_agent_memory # or use from pub.dev when published
isar: ^3.1.0
isar_flutter_libs: ^3.1.0
# dvdb and your embedding provider as needed
```

### 2. Initialize and use

```dart
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/gemini_embeddings_adapter.dart';

final adapter = GeminiEmbeddingsAdapter(apiKey: '<YOUR_GEMINI_API_KEY>');
final isar = await Isar.open([
  MemoryNodeSchema, MemoryEdgeSchema
], directory: './exampledb');
final graph = MemoryGraph(isar, embeddingsAdapter: adapter);

// Store a node with embedding
final nodeId = await graph.storeNodeWithEmbedding(content: 'The quick brown fox jumps over the lazy dog.');

// Semantic search
final queryEmbedding = await adapter.embed('A fox jumps over a dog');
final results = await graph.semanticSearch(queryEmbedding, topK: 3);
for (final result in results) {
  print('Node: ${result.node.content}, Distance: ${result.distance.toStringAsFixed(3)}, Provider: ${result.provider}');
}

// Explain recall
if (results.isNotEmpty) {
  final explanation = await graph.explainRecall(results.first.node.id, queryEmbedding: queryEmbedding);
  print('Explain: $explanation');
}
```

---

## Embeddings: Pluggable Providers

- Use the built-in `GeminiEmbeddingsAdapter` or implement your own via the `EmbeddingsAdapter` interface.
- Example for Gemini (Google):

```dart
final adapter = GeminiEmbeddingsAdapter(apiKey: '<YOUR_GEMINI_API_KEY>');
```

- To use OpenAI or custom providers, create your own adapter:

```dart
class MyEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'my_provider';
  @override
  Future<List<double>> embed(String text) async {
    // Call your embedding API here
  }
}
```

---

## Semantic Search (ANN)

- Uses [dvdb](https://pub.dev/packages/dvdb) for fast Approximate Nearest Neighbor search (HNSW index).
- Store nodes with embeddings, then retrieve relevant memories via ANN:

```dart
final queryEmbedding = await adapter.embed('search phrase');
final results = await graph.semanticSearch(queryEmbedding, topK: 5);
for (final result in results) {
  print('Node: ${result.node.content}, Distance: ${result.distance}, Provider: ${result.provider}');
}
```

---

## Explainability

- Every recall/search result can be explained:
  - **Semantic distance** (how close to the query?)
  - **Embedding provider** (which model was used)
  - **Activation** (recency, frequency, importance)
  - **Path tracing** (graph traversal: why did this memory surface?)

```dart
final explanation = await graph.explainRecall(nodeId, queryEmbedding: queryEmbedding);
print(explanation);
```

---

## Extensibility

- Add new embedding providers by implementing `EmbeddingsAdapter`.
- Store arbitrary metadata with nodes for advanced context.
- Sync/export (Firestore, JSON) planned for future releases.
- Designed for modular, clean integration in any Dart/Flutter app or agent.

---

## Testing

- Run all tests:

```bash
dart test
```

- Coverage includes:
  - Node/edge CRUD
  - ANN storage and search
  - Explainability (activation, semantic distance, error cases)
  - Embeddings adapters (mocked and real)

---

## Roadmap

- [x] Gemini embeddings adapter (real, pluggable)
- [x] Graph CRUD, semantic search, explainability
- [x] Example integration and documentation
- [x] Robust ANN and explainability tests
- [ ] UI for API key management (Flutter)
- [ ] Advanced explainability (reasoning paths, activation)
- [ ] More tests and edge cases
- [ ] Export/sync (Firestore/JSON)
- [ ] Community adapters (OpenAI, local, etc.)

---

## Contributing

---

## ⚙️ Dependency Management & Testing Strategy

Due to complex dependency conflicts between `isar_generator` (for code generation) and `flutter_test` (for testing, which pins several core Dart packages like `analyzer`, `matcher`, `test_api`, and `vm_service`), this repository now employs a separated project architecture for testing.

- **`isar_agent_memory` (Main Project)**: This project focuses solely on the library's core logic and code generation. It contains `isar_generator` and its compatible dependencies. It **does not** include `flutter_test` or `test` in its `dev_dependencies` to avoid conflicts.

- **`isar_agent_memory_tests` (Dedicated Test Project)**: A separate Flutter project located at the root level (`../isar_agent_memory_tests`) is now responsible for running all unit and integration tests. This project includes `flutter_test`, `test`, and other testing-related dependencies, and it imports `isar_agent_memory` as a local path dependency.

### Running Tests

To run the tests for `isar_agent_memory`, navigate to the `isar_agent_memory_tests` directory and execute the `flutter test` command:

```bash
cd ../isar_agent_memory_tests
flutter test
```

This separation ensures that both code generation and testing environments can maintain their required dependency versions without conflict, providing a stable and reliable development experience.

---

## 🔄 Continuous Dependency Updates & Auto-Merge

This repository uses **Dependabot** to automatically detect and propose updates to all dependencies declared in `pubspec.yaml`. When a new version of a dependency is released, Dependabot creates a Pull Request (PR) with the update.

- **Auto-merge workflow:** Any PR with the `automerge` label will be automatically merged into `main` if all CI checks pass.
- **CI enforcement:** All merges to `main` require passing tests and formatting/lint checks, ensuring stability.
- **Bot integration:** You can extend this setup with bots like Renovate, Jules, or Coderabbit for advanced review, feature tracking, or semantic PRs.

**How to keep your project always up to date:**

1. Dependabot creates PRs for new dependency versions.
2. The PR runs all tests and checks.
3. If everything passes and the PR has the `automerge` label, it is merged automatically.

This guarantees your package always benefits from the latest features and security updates in its dependencies.

---

## 🤖 Advanced AI & Multi-Bot DevOps Strategy

This repository leverages a robust, modern, and fully-automated DevOps approach to ensure all dependencies, features, and the Flutter SDK itself remain up-to-date and secure:

- **Coderabbit**: AI-powered bot for code review, auto-approval, auto-merge, and refactor suggestions. Auto-merges PRs from trusted bots (Dependabot, Renovate) and those with the `automerge` label if CI passes.
- **Dependabot**: Native GitHub bot that opens PRs for new versions of Dart/Flutter dependencies. PRs are auto-labeled and merged if checks pass.
- **Renovate**: Advanced bot for dependency upgrades, monorepos, and workflows. Monitors not only Dart/Flutter packages but also GitHub Actions, Docker, and the Flutter SDK version. Auto-merges safe updates.
- **Jules (Google Labs)**: Can be triggered via GitHub Issues to research, recommend, or execute the best bot or workflow for upgrades, refactors, or dependency management. Ensures the most effective tool is always used for each update.

**How it works:**

1. Dependabot and Renovate monitor all dependencies and the Flutter SDK, opening PRs for any new version or update.
2. Coderabbit reviews, approves, and merges PRs from trusted bots or with the `automerge` label if CI passes.
3. Jules can be triggered via Issues to research and select the best bot or run custom upgrade/refactor tasks.
4. All merges to `main` require passing CI (tests, lint, format) for maximum stability.

This setup guarantees:

- Always using the latest secure and feature-rich versions of dependencies and Flutter.
- Zero manual intervention for routine upgrades.
- AI-assisted code quality, refactoring, and review.
- Rapid adoption of new features and best practices from the Dart/Flutter ecosystem.

**You can customize or extend this workflow via `.github/coderabbit.yml`, `.github/renovate.json`, and `.github/dependabot.yml` as your needs evolve.**

---

PRs, issues, and feedback are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) when available.

---

## License

MIT
