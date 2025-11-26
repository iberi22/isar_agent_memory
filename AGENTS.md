# AGENTS.md - AI Agent Guidelines for isar_agent_memory

This file provides instructions for AI coding agents (GitHub Copilot, Claude, GPT, Cursor, etc.) working on this repository.

## Repository Overview

**isar_agent_memory** is a Dart package providing advanced RAG (Retrieval-Augmented Generation) capabilities with:
- Graph-based memory storage
- Vector similarity search (HNSW via ObjectBox)
- Multiple embedding adapters
- Memory consolidation and forgetting mechanisms
- Cross-device sync capabilities

## Quick Reference

| Item | Value |
|------|-------|
| Language | Dart |
| SDK | `>=3.2.0 <4.0.0` |
| Package Manager | pub (dart pub get) |
| Database | ObjectBox |
| Test Framework | dart test |
| Current Version | See `pubspec.yaml` |

## Essential Commands

```bash
# ALWAYS run these before committing
dart pub get        # Install dependencies
dart analyze        # Must pass with 0 issues
dart format .       # Format code
dart test           # Run tests

# Version management (PowerShell)
.\tool\update_version.ps1 -NewVersion "X.Y.Z"
```

## Project Layout

```
.github/
├── workflows/              # CI/CD automation
│   ├── ci.yml             # Main CI pipeline
│   ├── release-on-merge.yml  # Auto-release on version change
│   ├── publish-to-pub-dev.yml  # Publish to pub.dev
│   └── version-sync.yml   # Version consistency check
├── copilot-instructions.md  # Copilot-specific rules
└── instructions/          # Path-specific instructions
lib/
├── isar_agent_memory.dart  # Main exports (edit to add features)
├── objectbox-model.json   # ObjectBox model definition
├── objectbox.g.dart       # Generated ObjectBox code
└── src/
    ├── memory_graph.dart  # Core: MemoryGraph class
    ├── hierarchical_graph.dart  # HiRAG implementation
    ├── vector_index.dart  # Vector search interface
    ├── vector_index_objectbox.dart  # ObjectBox HNSW impl
    ├── embeddings_adapter.dart  # Embedding interface
    ├── gemini_embeddings_adapter.dart  # Gemini embeddings
    ├── on_device_embeddings_adapter.dart  # Local embeddings
    ├── memory_consolidation.dart  # Memory merging
    ├── forgetting_mechanism.dart  # Memory cleanup
    ├── agent_memory_types.dart  # Episodic/semantic/procedural
    └── ...
test/                      # Tests (mirror lib/src structure)
tool/
├── update_version.ps1     # Version sync script
├── update_release.ps1     # Fix GitHub releases
├── verify_release.ps1     # Verify release success
└── setup_pub_credentials.ps1  # pub.dev auth setup
example/
└── main.dart              # Usage examples
```

## 🚨 CRITICAL: Release Process

**NEVER manually edit version in multiple files. ALWAYS use the script.**

### Standard Release Flow

```powershell
# 1. Update version everywhere
.\tool\update_version.ps1 -NewVersion "0.6.0"

# 2. Edit CHANGELOG.md - add new section at top
# ## [0.6.0] - 2024-XX-XX
# ### Added
# - Feature description

# 3. Commit with conventional message
git add -A
git commit -m "chore: bump version to 0.6.0"
git push origin main

# 4. Automation handles the rest:
#    - Creates git tag v0.6.0
#    - Creates GitHub Release with CHANGELOG content
#    - Publishes to pub.dev (stable only)
```

### Version Formats

| Format | Example | Auto-publish to pub.dev |
|--------|---------|------------------------|
| Stable | `1.0.0` | ✅ Yes |
| Beta | `1.0.0-beta` | ❌ No (manual) |
| Alpha | `1.0.0-alpha` | ❌ No (manual) |
| RC | `1.0.0-rc.1` | ❌ No (manual) |

### Files Updated by Version Script

- `pubspec.yaml` - `version: X.Y.Z`
- `README.md` - `isar_agent_memory: ^X.Y.Z`

### CHANGELOG.md Format

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description

### Breaking Changes
- Breaking change (if any)
```

## Coding Conventions

### Dart Style
- Follow [Effective Dart](https://dart.dev/effective-dart)
- Use `final` for immutable variables
- Use `late final` for lazy initialization
- Prefer `const` constructors when possible

### Imports (in order)
```dart
// 1. Dart SDK
import 'dart:async';

// 2. External packages
import 'package:objectbox/objectbox.dart';

// 3. Internal files (relative)
import 'memory_graph.dart';
```

### Documentation
```dart
/// Brief description of the class.
///
/// Detailed explanation of purpose and usage.
///
/// Example:
/// ```dart
/// final graph = MemoryGraph(store);
/// await graph.addNode(node);
/// ```
class MemoryGraph {
  /// Creates a new memory graph with the given [store].
  ///
  /// Throws [ArgumentError] if store is not initialized.
  MemoryGraph(this.store);
}
```

## Common Patterns

### ObjectBox Operations
```dart
// Correct: Using box properly
final box = store.box<MemoryNode>();
final query = box.query(MemoryNode_.importance.greaterThan(0.5))
    .order(MemoryNode_.timestamp, flags: Order.descending)
    .build();
try {
  return query.find();
} finally {
  query.close();
}
```

### Async Operations
```dart
// Correct: Proper async handling
Future<List<MemoryNode>> searchSimilar(List<double> embedding) async {
  final candidates = await vectorIndex.search(embedding, limit: 100);
  return candidates.whereType<MemoryNode>().toList();
}
```

### Error Handling
```dart
// Correct: Specific error handling
try {
  await store.runInTransaction(TxMode.write, () async {
    // ... operations
  });
} on ObjectBoxException catch (e) {
  _logger.warning('Transaction failed: $e');
  rethrow;
}
```

## Testing Guidelines

```bash
# Run all tests
dart test

# Run specific test file
dart test test/smoke_test.dart

# Run with verbose output
dart test --reporter=expanded

# Run only tests matching pattern
dart test --name="MemoryGraph"
```

### Test Structure
```dart
void main() {
  late MemoryGraph graph;
  late Store store;

  setUp(() async {
    store = await openTestStore();
    graph = MemoryGraph(store);
  });

  tearDown(() {
    store.close();
  });

  group('MemoryGraph', () {
    test('should add node successfully', () async {
      // Arrange
      final node = MemoryNode(content: 'test');

      // Act
      await graph.addNode(node);

      // Assert
      expect(graph.nodeCount, equals(1));
    });
  });
}
```

## Troubleshooting

### Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `searchSimilarNodes is not defined` | Old API name | Use `semanticSearch` instead |
| `isar.collection is not defined` | Wrong database | This package uses ObjectBox, not Isar |
| `@override without parent method` | Invalid annotation | Remove `@override` |
| `Type inference failed` | Generic type needed | Add explicit type: `<int>[]` |

### Build Issues
```bash
# Clean and rebuild
dart pub get
dart run build_runner build --delete-conflicting-outputs

# If ObjectBox model issues
dart run build_runner clean
```

## Automation Workflows

### CI Pipeline (`ci.yml`)
- Runs on every PR and push
- Steps: checkout → pub get → analyze → test

### Release Pipeline (`release-on-merge.yml`)
- Triggers on push to main when pubspec.yaml or CHANGELOG.md change
- Detects version change
- Creates git tag
- Extracts CHANGELOG content
- Creates GitHub Release

### Publish Pipeline (`publish-to-pub-dev.yml`)
- Triggers on GitHub Release published
- Skips prereleases
- Publishes to pub.dev

### Version Sync (`version-sync.yml`)
- Validates version consistency across files
- Fails CI if versions don't match
- Provides fix instructions

## Agent-Specific Notes

### For GitHub Copilot
- Custom instructions in `.github/copilot-instructions.md`
- Path-specific rules in `.github/instructions/`

### For Claude/GPT Agents
- Read `RELEASE_PROCESS.md` for detailed release steps
- Check `AUTOMATION_SUMMARY.md` for workflow overview

### For Cursor/Windsurf
- Project uses Dart, not TypeScript
- ObjectBox for database, not SQLite
- pub.dev for package publishing

## Do NOT

- ❌ Run `dart pub publish` manually without `--dry-run` first
- ❌ Edit version in pubspec.yaml without running update script
- ❌ Skip CHANGELOG.md updates for releases
- ❌ Commit code that fails `dart analyze`
- ❌ Use deprecated Isar APIs (we use ObjectBox)
- ❌ Create releases without testing locally
- ❌ Ignore version-sync CI failures

## Quick Checklist Before Commit

- [ ] `dart analyze` passes with 0 issues
- [ ] `dart format .` applied
- [ ] Tests pass (`dart test`)
- [ ] If version change: used `update_version.ps1`
- [ ] If version change: updated CHANGELOG.md
- [ ] Commit message follows conventional commits

## References

- [RELEASE_PROCESS.md](./RELEASE_PROCESS.md) - Complete release guide
- [AUTOMATION_SUMMARY.md](./AUTOMATION_SUMMARY.md) - Automation overview
- [doc/ADVANCED_FEATURES.md](./doc/ADVANCED_FEATURES.md) - Feature documentation
- [Effective Dart](https://dart.dev/effective-dart) - Dart style guide
- [pub.dev Publishing](https://dart.dev/tools/pub/publishing) - Package publishing

---

**Trust these instructions.** They are validated for this repository. Only search for additional context if specific information is missing.
