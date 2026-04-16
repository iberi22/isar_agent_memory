import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

class MockLLMAdapter implements LLMAdapter {
  @override
  Future<String> generate(String prompt) async {
    if (prompt.contains('SUB-PREGUNTAS:')) {
      return '¿Qué es la tensión arterial?\n¿Cómo se mide la tensión arterial?';
    }
    if (prompt.contains('CONTEXTO:')) {
      return 'La tensión arterial es la fuerza de la sangre contra las paredes de las arterias [1].';
    }
    return 'Mocked response';
  }
}

class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'mock';
  @override
  int get dimension => 384;
  @override
  Future<List<double>> embed(String text) async {
    return List.generate(384, (i) => (text.length + i) / 1000.0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoryGraph memoryGraph;
  late MockLLMAdapter llm;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'medical_test_db',
    );
    memoryGraph = MemoryGraph(isar, embeddingsAdapter: MockEmbeddingsAdapter());
    llm = MockLLMAdapter();
    await isar.writeTxn(() async => await isar.clear());
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('MedicalRagPipeline Stages', () {
    test('QueryNormalizationStage expands abbreviations', () async {
      final stage = QueryNormalizationStage();
      final context = RagContext(originalQuery: 'Paciente con TA alta y DM');

      final result = await stage.process(context);

      expect(result.currentQuery, contains('tensión arterial'));
      expect(result.currentQuery, contains('diabetes mellitus'));
    });

    test('MedicalQueryDecompositionStage splits queries', () async {
      final stage = MedicalQueryDecompositionStage(llm, MedicalPromptBuilder());
      final context = RagContext(
          originalQuery:
              'Explique qué es la TA y cómo se mide en pacientes con HTA severa');

      final result = await stage.process(context);

      expect(result.decomposedQueries.length, greaterThan(1));
      expect(result.decomposedQueries[0], contains('tensión arterial'));
    });
  });

  test('MedicalRagPipeline full execution', () async {
    // Seed some data
    await memoryGraph.storeNode(MemoryNode(
      content:
          'La tensión arterial es vital para el funcionamiento del cuerpo.',
      type: 'medical',
    ));

    final pipeline = MedicalRagPipeline(
      memoryGraph: memoryGraph,
      llm: llm,
    );

    final result = await pipeline.execute('¿Qué es la TA?');

    expect(result.currentQuery, contains('tensión arterial'));
    expect(result.generatedResponse, contains('tensión arterial'));
    expect(result.generatedResponse, contains('AVISO MÉDICO'));
    expect(result.citedNodes, isNotEmpty);
  });
}
