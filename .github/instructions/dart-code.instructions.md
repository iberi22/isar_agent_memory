---
applyTo: "**/*.dart"
---

# Dart Code Instructions

When working with Dart files in this repository:

## Code Style

- Follow Effective Dart guidelines
- Use `final` for variables that won't be reassigned
- Prefer `const` constructors when possible
- Use `late final` for lazy initialization

## Imports

Order imports as:
1. `dart:` SDK imports
2. `package:` external packages
3. Relative imports (for internal files)

Separate groups with blank lines and sort alphabetically within each group.

## Documentation

- Document all public APIs with `///` doc comments
- Include examples in documentation when helpful
- Document thrown exceptions

## Error Handling

- Use specific exception types
- Don't catch and ignore exceptions
- Use `rethrow` to preserve stack traces

## ObjectBox Patterns

This project uses ObjectBox for database:
```dart
// Correct query pattern
final query = box.query(condition).build();
try {
  return query.find();
} finally {
  query.close();
}
```

## Before Committing

- Run `dart analyze` - must pass with 0 issues
- Run `dart format .` to format code
- Ensure tests pass with `dart test`
