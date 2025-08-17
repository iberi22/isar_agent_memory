import 'package:test/test.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

class ThrowingAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'throw';

  @override
  int get dimension => 4;

  @override
  Future<List<double>> embed(String text) async {
    throw Exception('Primary failed');
  }
}

class EmptyAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'empty';

  @override
  int get dimension => 4;

  @override
  Future<List<double>> embed(String text) async => <double>[];
}

class FixedAdapter implements EmbeddingsAdapter {
  final List<double> vec;
  final String name;
  FixedAdapter(this.vec, {this.name = 'fixed'});

  @override
  String get providerName => name;

  @override
  int get dimension => vec.length;

  @override
  Future<List<double>> embed(String text) async => vec;
}

void main() {
  group('FallbackEmbeddingsAdapter', () {
    test('falls back when primary throws', () async {
      final fallback = FixedAdapter(
        [1, 2, 3, 4].map((e) => e.toDouble()).toList(),
        name: 'fallback',
      );
      final adapter = FallbackEmbeddingsAdapter(
        primary: ThrowingAdapter(),
        fallback: fallback,
      );
      final v = await adapter.embed('hello');
      expect(v, equals([1.0, 2.0, 3.0, 4.0]));
      expect(adapter.providerName, equals('throw->fallback'));
    });

    test('falls back on empty vector when configured', () async {
      final adapter = FallbackEmbeddingsAdapter(
        primary: EmptyAdapter(),
        fallback: FixedAdapter([0.1, 0.2], name: 'fb'),
        fallbackOnEmpty: true,
      );
      final v = await adapter.embed('hi');
      expect(v, equals([0.1, 0.2]));
      expect(adapter.providerName, equals('empty->fb'));
    });

    test('does not fallback on empty when disabled', () async {
      final adapter = FallbackEmbeddingsAdapter(
        primary: EmptyAdapter(),
        fallback: FixedAdapter([0.1, 0.2]),
        fallbackOnEmpty: false,
      );
      final v = await adapter.embed('hi');
      expect(v, isEmpty);
    });
  });
}
