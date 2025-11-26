---
applyTo: "test/**/*.dart"
---

# Test File Instructions

When working with test files:

## Test Structure

```dart
import 'package:test/test.dart';

void main() {
  late Store store;
  late MemoryGraph graph;

  setUpAll(() async {
    // One-time setup
  });

  setUp(() async {
    // Per-test setup
    store = await openTestStore();
    graph = MemoryGraph(store);
  });

  tearDown(() {
    // Per-test cleanup
    store.close();
  });

  group('ClassName', () {
    test('should do something', () async {
      // Arrange
      final input = createTestInput();

      // Act
      final result = await graph.method(input);

      // Assert
      expect(result, isNotNull);
      expect(result.property, equals(expected));
    });
  });
}
```

## Test Commands

```bash
# Run all tests
dart test

# Run specific file
dart test test/smoke_test.dart

# Run with verbose output
dart test --reporter=expanded

# Run matching pattern
dart test --name="MemoryGraph"
```

## Assertions

Use specific matchers:
```dart
// Good
expect(result, equals(42));
expect(list, hasLength(3));
expect(future, throwsA(isA<ArgumentError>()));

// Avoid
expect(result == 42, isTrue);
```

## Async Tests

```dart
test('async operation', () async {
  // Use async/await
  final result = await asyncMethod();
  expect(result, isNotNull);
});

test('stream test', () async {
  // Use expectLater for streams
  expectLater(stream, emitsInOrder([1, 2, 3]));
});
```

## Best Practices

- One assertion concept per test
- Use descriptive test names: `should [action] when [condition]`
- Clean up resources in tearDown
- Use groups to organize related tests
- Mock external dependencies
