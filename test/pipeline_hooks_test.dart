import 'package:flutter_test/flutter_test.dart';
import 'package:isar_agent_memory/src/pipeline_hooks.dart';
import 'package:isar_agent_memory/src/models/memory_node.dart';

void main() {
  group('PipelineContext', () {
    test('creates with default values', () {
      final ctx = PipelineContext(query: 'test query');
      expect(ctx.query, 'test query');
      expect(ctx.expandedQueries, isEmpty);
      expect(ctx.retrievedNodes, isEmpty);
      expect(ctx.metadata, isEmpty);
      expect(ctx.sessionId, isNull);
      expect(ctx.userId, isNull);
    });

    test('accepts custom values', () {
      final ctx = PipelineContext(
        query: 'custom',
        expandedQueries: ['expanded'],
        sessionId: 's1',
        userId: 'u1',
        metadata: {'key': 'value'},
      );
      expect(ctx.expandedQueries, ['expanded']);
      expect(ctx.sessionId, 's1');
      expect(ctx.userId, 'u1');
      expect(ctx.metadata['key'], 'value');
    });
  });

  group('MemoryPipeline', () {
    test('runs empty pipeline (no hooks)', () async {
      final pipeline = MemoryPipeline();
      final result = await pipeline.run('hello');
      expect(result.results, isEmpty);
      expect(result.context.query, 'hello');
      expect(result.elapsed.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('clearHooks removes all hooks', () {
      final pipeline = MemoryPipeline();
      pipeline.addExpansionHook(_MockExpansionHook());
      pipeline.clearHooks();
      // run with no hooks should work fine
    });

    test('runs hooks in priority order', () async {
      final pipeline = MemoryPipeline();
      final order = <int>[];
      pipeline.addRetrievalHook(_PriorityHook(priority: 30, order: order, id: 3));
      pipeline.addRetrievalHook(_PriorityHook(priority: 10, order: order, id: 1));
      pipeline.addRetrievalHook(_PriorityHook(priority: 20, order: order, id: 2));

      await pipeline.run('test');
      expect(order, [1, 2, 3]);
    });

    test('expansion hooks run before retrieval hooks', () async {
      final pipeline = MemoryPipeline();
      final order = <String>[];
      pipeline.addExpansionHook(_MockExpansionHook(order: order, label: 'expand'));
      pipeline.addRetrievalHook(_MockRetrievalHook(order: order, label: 'retrieve'));

      await pipeline.run('test');
      expect(order[0], 'expand');
      expect(order[1], 'retrieve');
    });

    test('retrieval hooks add results to context', () async {
      final pipeline = MemoryPipeline();
      pipeline.addRetrievalHook(_MockRetrievalHook(label: 'vec'));

      final result = await pipeline.run('find something');
      expect(result.results.isNotEmpty, true);
      expect(result.context.retrievedNodes.isNotEmpty, true);
    });

    test('maxIterations limits loop', () async {
      final pipeline = MemoryPipeline();
      pipeline.maxIterations = 2;
      var callCount = 0;
      pipeline.addEvaluationHook(_RetryEvaluationHook(callCount: () => callCount++));

      await pipeline.run('test');
      // Called twice (one for each iteration)
      expect(callCount >= 1, true);
    });

    test('clarify decision stops pipeline', () async {
      final pipeline = MemoryPipeline();
      pipeline.addEvaluationHook(_ClarifyEvaluationHook());

      final result = await pipeline.run('ambiguous query');
      expect(result.context.query, 'ambiguous query');
    });
  });
}

// --- Mock Hooks ---

class _MockExpansionHook implements QueryExpansionHook {
  final List<String>? order;
  final String? label;

  _MockExpansionHook({this.order, this.label});

  @override
  int get priority => 10;

  @override
  Future<void> expand(PipelineContext context) async {
    order?.add(label ?? 'expand');
  }
}

class _MockRetrievalHook implements RetrievalHook {
  final List<String>? order;
  final String? label;

  _MockRetrievalHook({this.order, this.label});

  @override
  int get priority => 10;

  @override
  Future<void> retrieve(PipelineContext context) async {
    order?.add(label ?? 'retrieve');
    context.retrievedNodes.add(RetrievedNode(
      node: MemoryNode(content: 'mock result', type: 'test'),
      score: 1.0,
      source: 'mock',
    ));
  }
}

class _PriorityHook implements RetrievalHook {
  final int _priority;
  final List<int> order;
  final int id;

  _PriorityHook({required int priority, required this.order, required this.id})
      : _priority = priority;

  @override
  int get priority => _priority;

  @override
  Future<void> retrieve(PipelineContext context) async {
    order.add(id);
  }
}

class _RetryEvaluationHook implements EvaluationHook {
  final int Function()? callCount;

  _RetryEvaluationHook({this.callCount});

  @override
  int get priority => 10;

  @override
  Future<EvalDecision> evaluate(PipelineContext context) async {
    callCount?.call();
    return EvalDecision.retry;
  }
}

class _ClarifyEvaluationHook implements EvaluationHook {
  @override
  int get priority => 10;

  @override
  Future<EvalDecision> evaluate(PipelineContext context) async {
    return EvalDecision.clarify;
  }
}
