import 'package:test/test.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  String lastText = '';

  @override
  int get dimension => 3;

  @override
  String get providerName => 'mock';

  @override
  Future<List<double>> embed(String text) async {
    lastText = text;
    return [1.0, 2.0, 3.0];
  }

  @override
  Future<List<double>> medicalNormalized(String text) async {
    lastText = 'normalized:$text';
    return [1.0, 2.0, 3.0];
  }
}

void main() {
  group('MedicalTokenizer', () {
    final tokenizer = MedicalTokenizer();

    test('expands Spanish abbreviations', () {
      expect(tokenizer.expandAbbreviations('El paciente tiene TA alta'),
          contains('tensión arterial'));
      expect(tokenizer.expandAbbreviations('FC: 80 lpm'),
          contains('frecuencia cardíaca'));
      expect(tokenizer.expandAbbreviations('SpO2 al 98%'),
          contains('saturación de oxígeno'));
      expect(tokenizer.expandAbbreviations('Se solicita TAC de tórax'),
          contains('tomografía axial computarizada'));
    });

    test('expands English abbreviations', () {
      expect(tokenizer.expandAbbreviations('Patient BP is normal'),
          contains('blood pressure'));
      expect(tokenizer.expandAbbreviations('HR: 72 bpm'),
          contains('heart rate'));
      expect(tokenizer.expandAbbreviations('Admitted to ICU'),
          contains('intensive care unit'));
    });

    test('handles case insensitivity', () {
      expect(tokenizer.expandAbbreviations('ta'), contains('tensión arterial'));
      expect(tokenizer.expandAbbreviations('TA'), contains('tensión arterial'));
    });

    test('uses word boundaries to avoid partial matches', () {
      // 'ta' is an abbreviation, but 'taza' contains 'ta'. It should not be expanded.
      expect(tokenizer.expandAbbreviations('taza'), equals('taza'));
      expect(tokenizer.expandAbbreviations('estadio'), equals('estadio'));
    });

    test('handles special character Tª', () {
      expect(tokenizer.expandAbbreviations('Tª de 38ºC'),
          contains('temperatura'));
    });
  });

  group('MedicalEmbeddingsAdapter', () {
    test('expands text before calling inner adapter', () async {
      final mock = MockEmbeddingsAdapter();
      final adapter = MedicalEmbeddingsAdapter(mock);

      await adapter.embed('Paciente con HTA');
      expect(mock.lastText, contains('hipertensión arterial'));

      await adapter.medicalNormalized('TA normal');
      expect(mock.lastText, contains('normalized:tensión arterial normal'));
    });

    test('preserves dimension and provider name', () {
      final mock = MockEmbeddingsAdapter();
      final adapter = MedicalEmbeddingsAdapter(mock);

      expect(adapter.dimension, equals(3));
      expect(adapter.providerName, contains('medical_enhanced(mock)'));
    });
  });
}
