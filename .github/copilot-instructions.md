# Copilot Instructions for isar_agent_memory

This repository contains `isar_agent_memory`, a Dart/Flutter package for advanced RAG (Retrieval-Augmented Generation) capabilities with local-first storage.

## Project Overview

- **Language**: Dart
- **SDK**: Dart `>=3.2.0 <4.0.0`
- **Database**: ObjectBox for vector storage (HNSW index)
- **Package Type**: pub.dev package for Flutter/Dart projects
- **Current Version**: Check `pubspec.yaml` for the current version

## Project Structure

```
lib/
├── isar_agent_memory.dart    # Main export file
└── src/
    ├── memory_graph.dart     # Core graph-based memory
    ├── vector_index*.dart    # Vector search implementations
    ├── embeddings_*.dart     # Embedding adapters
    └── ...                   # Advanced features
test/                         # Unit and integration tests
tool/                         # Release automation scripts
example/                      # Usage examples
```

## Coding Standards

### Dart Conventions
- Follow [Effective Dart](https://dart.dev/effective-dart) guidelines
- Use `dart format` before committing
- Run `dart analyze` to ensure no errors or warnings
- Prefer `final` for variables that don't change
- Use descriptive names for classes, methods, and variables
- Document public APIs with `///` doc comments

### Imports
- Use relative imports for internal files: `import 'memory_graph.dart'`
- Use package imports for external dependencies
- Group imports: dart, package, relative (separated by blank lines)
- Sort imports alphabetically within groups

### Error Handling
- Use specific exception types over generic `Exception`
- Document exceptions in method documentation
- Prefer `try-catch` for recoverable errors
- Never catch and ignore exceptions silently

## Build and Test Commands

```bash
# Install dependencies
dart pub get

# Analyze code (MUST pass before committing)
dart analyze

# Format code
dart format .

# Run all tests
dart test

# Run specific test file
dart test test/smoke_test.dart

# Dry-run publish check
dart pub publish --dry-run
```

## ⚠️ RELEASE PROCESS - CRITICAL

**ALWAYS follow this process when making version changes:**

### 1. Update Version
Use the automated script to ensure version consistency:
```powershell
.\tool\update_version.ps1 -NewVersion "X.Y.Z"
```

This script updates:
- `pubspec.yaml` version
- `README.md` installation example

### 2. Update CHANGELOG.md
Add a new section at the top of CHANGELOG.md:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Modified behaviors

### Fixed
- Bug fixes
```

### 3. Commit Convention
Use conventional commits:
```bash
# For version bumps
git commit -m "chore: bump version to X.Y.Z"

# For features
git commit -m "feat: add new memory consolidation feature"

# For fixes
git commit -m "fix: resolve Isar collection access error"
```

### 4. Automated Release Flow
After pushing to main:
1. `version-sync.yml` - Validates version consistency
2. `release-on-merge.yml` - Creates tag and GitHub Release
3. `publish-to-pub-dev.yml` - Publishes stable releases to pub.dev

**Prereleases** (beta/alpha/rc) are NOT automatically published to pub.dev.

### Important Release Files
- `RELEASE_PROCESS.md` - Complete release documentation
- `CHANGELOG.md` - Version history (extracted for release notes)
- `tool/update_version.ps1` - Version sync script
- `.github/workflows/` - CI/CD automation

## Dependencies

### Core Dependencies
- `objectbox: ^5.0.0` - Vector storage with HNSW
- `crypto: ^3.0.5` - Encryption
- `uuid: ^4.5.1` - Unique identifiers

### Dev Dependencies
- `test: ^1.24.0` - Testing framework
- `build_runner: ^2.4.0` - Code generation

## Common Patterns

### Adding a New Feature
1. Create implementation in `lib/src/`
2. Export from `lib/isar_agent_memory.dart`
3. Add tests in `test/`
4. Document in relevant `.md` files
5. Update CHANGELOG.md

### Fixing Compilation Errors
- Check imports are correct
- Verify ObjectBox collection access patterns
- Ensure method signatures match interfaces
- Run `dart analyze` frequently during development

### Working with ObjectBox
```dart
// Correct collection access
final box = store.box<MemoryNode>();
final query = box.query(condition).build();

// Always close queries
try {
  final results = query.find();
  return results;
} finally {
  query.close();
}
```

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR/Push | Lint, analyze, test |
| `version-sync.yml` | PR/Push | Validate version consistency |
| `release-on-merge.yml` | Push to main | Create tags and releases |
| `publish-to-pub-dev.yml` | Release published | Publish to pub.dev |

## Documentation Files

- `README.md` - Package documentation and quickstart
- `CHANGELOG.md` - Version history
- `RELEASE_PROCESS.md` - Release workflow guide
- `AUTOMATION_SUMMARY.md` - Automation overview
- `doc/ADVANCED_FEATURES.md` - Advanced features guide
- `doc/SYNC_PROTOCOL.md` - Sync documentation

## Do NOT

- ❌ Manually edit version in multiple files (use `update_version.ps1`)
- ❌ Skip CHANGELOG.md when releasing
- ❌ Commit code that fails `dart analyze`
- ❌ Use `@override` on methods not from parent class
- ❌ Leave unused imports or variables
- ❌ Catch exceptions without handling them

## Trust These Instructions

The information above is validated and accurate for this repository. Only search for additional context if these instructions are incomplete for your specific task.
