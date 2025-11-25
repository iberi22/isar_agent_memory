# Advanced Features Guide

This guide covers the advanced features added in v0.5.0 that significantly enhance the RAG capabilities of isar_agent_memory.

## Table of Contents

1. [Memory Consolidation](#memory-consolidation)
2. [Embeddings Cache](#embeddings-cache)
3. [Quality Metrics](#quality-metrics)
4. [Cross-Encoder Re-ranking](#cross-encoder-re-ranking)
5. [Forgetting Mechanism](#forgetting-mechanism)
6. [Dynamic Layer Creation](#dynamic-layer-creation)
7. [Multi-Modal Support](#multi-modal-support)
8. [Agent Memory Types](#agent-memory-types)
9. [Privacy Features](#privacy-features)

---

## Memory Consolidation

Automatically merge similar memories to reduce redundancy and improve memory quality.

### Basic Usage

```dart
import 'package:isar_agent_memory/isar_agent_memory.dart';

final consolidation = MemoryConsolidation(memoryGraph);

// Find similar memory clusters
final clusters = await consolidation.findSimilarMemoryClusters(
  maxClusters: 10,
);

// Consolidate a cluster
final consolidatedId = await consolidation.consolidateCluster(
  nodeIds: clusters.first,
  llmAdapter: yourLLMAdapter,
  keepOriginals: true,
);

// Auto-consolidate entire graph
final count = await consolidation.autoConsolidate(
  llmAdapter: yourLLMAdapter,
  maxClusters: 20,
);
```

### Features

- **Similarity-based clustering**: Groups related memories
- **LLM-powered consolidation**: Uses LLM to merge content intelligently
- **Deduplication**: Removes exact or near-exact duplicates
- **Configurable thresholds**: Control similarity and cluster size

---

## Embeddings Cache

LRU cache for embeddings to dramatically improve performance.

### Basic Usage

```dart
final cache = EmbeddingsCache(maxSize: 1000);

// Check cache before embedding
final cached = cache.get(content);
if (cached != null) {
  return cached;
}

// Compute and cache
final embedding = await adapter.embed(content);
cache.put(content, Float32List.fromList(embedding));

// Get statistics
final stats = cache.getStats();
print(stats); // CacheStats(hits: 450, misses: 50, hitRate: 90.0%)
```

### Features

- **LRU eviction**: Automatically removes least recently used entries
- **Hit rate tracking**: Monitor cache performance
- **Expiration support**: Automatic cleanup of old entries
- **Access analytics**: Track most frequently accessed embeddings

---

## Quality Metrics

Comprehensive metrics for monitoring RAG performance.

### Basic Usage

```dart
final metrics = QualityMetrics(memoryGraph);

// Record each search
final stopwatch = Stopwatch()..start();
final results = await memoryGraph.searchSimilarNodes(query, topK: 10);
stopwatch.stop();

metrics.recordQuery(
  query: 'user query',
  resultsReturned: results.length,
  latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
  averageDistance: calculateAverage(results.map((r) => r.distance)),
);

// Generate report
final report = await metrics.generateReport(
  period: Duration(days: 7),
);
print(report);
```

### Metrics Tracked

- **Latency**: Average, p95, p99
- **Relevance**: Distance-based scoring
- **Coverage**: What % of memory was accessed
- **Quality over time**: Trends and patterns

---

## Cross-Encoder Re-ranking

Advanced re-ranking using query-document pair scoring.

### Basic Usage

```dart
// Remote API-based (recommended for production)
final encoder = RemoteCrossEncoderAdapter(
  apiUrl: 'https://api.example.com/rerank',
  apiKey: 'your-api-key',
);

final reranker = CrossEncoderReranker(
  encoder: encoder,
  minScore: 0.5,
);

// Re-rank results
final reranked = await reranker.rerank(
  query: 'user query',
  candidates: initialResults,
  topK: 5,
);
```

### Advanced: Hybrid Re-ranking

```dart
final hybrid = HybridReranker(
  rerankers: [
    WeightedReranker(reranker: crossEncoder, weight: 0.5),
    WeightedReranker(reranker: bm25Reranker, weight: 0.3),
    WeightedReranker(reranker: recencyReranker, weight: 0.2),
  ],
);
```

### Advanced: MMR for Diversity

```dart
final mmr = MMRReranker(
  lambda: 0.7, // Balance relevance (1.0) vs diversity (0.0)
);

final diverse = await mmr.rerank(
  query: query,
  candidates: results,
  topK: 10,
);
```

---

## Forgetting Mechanism

Intelligent memory cleanup based on importance, age, and usage.

### Basic Usage

```dart
final forgetting = ForgettingMechanism(memoryGraph);

// Auto-forget with multiple strategies
final report = await forgetting.autoForget(
  maxNodes: 10000,
  maxAgeDays: 90,
  minImportance: 0.3,
  applyDecay: true,
);

print(report); // Shows what was forgotten and why
```

### Importance-based Forgetting

```dart
// Check importance score
final importance = await forgetting.calculateImportance(node);

// Forget low-importance memories
final forgotten = await forgetting.forgetByImportance(
  threshold: 0.4,
  dryRun: false,
);
```

### Protection

```dart
// Protect important memories
await forgetting.protect(nodeId);

// Record access for LRU tracking
await forgetting.recordAccess(nodeId);
```

### Importance Factors

1. **Recency**: Newer memories are more important
2. **Access frequency**: Frequently retrieved = important
3. **Connection strength**: Well-connected nodes = important
4. **Explicit importance**: Manual importance flags

---

## Dynamic Layer Creation

Automatically organize memories into hierarchical layers.

### Basic Usage

```dart
// Organize entire graph into layers
final organization = await memoryGraph.organizeIntoLayers(
  llmAdapter: yourLLMAdapter,
  maxNodesPerLayer: 20,
  similarityThreshold: 0.3,
  maxLayers: 5,
);

print(organization);
// Layer Organization:
//   Layer 0: 100 nodes
//   Layer 1: 20 nodes
//   Layer 2: 4 nodes
```

### Layer Analysis

```dart
final analysis = await memoryGraph.analyzeLayerStructure();
print(analysis);
// Shows distribution and recommendations
```

### Optimize Structure

```dart
await memoryGraph.optimizeLayerStructure(
  llmAdapter: yourLLMAdapter,
  frequentlyAccessedNodes: accessLog,
);
```

---

## Multi-Modal Support

Embed and search across text, images, audio, and structured data.

### CLIP Adapter (Text + Image)

```dart
final clip = CLIPAdapter(
  modelPath: 'path/to/clip/model',
  dimensions: 512,
);

// Embed text
final textEmbedding = await clip.embedText('a photo of a cat');

// Embed image
final imageBytes = await File('cat.jpg').readAsBytes();
final imageEmbedding = await clip.embedImage(imageBytes);

// They're in the same space - can compare directly!
```

### Structured Data

```dart
final processor = StructuredDataProcessor();

// Convert table to text
final tableText = StructuredDataProcessor.tableToText([
  {'name': 'Alice', 'age': 30},
  {'name': 'Bob', 'age': 25},
]);

// Extract key phrases
final phrases = StructuredDataProcessor.extractKeyPhrases({
  'user': {'name': 'Alice', 'email': 'alice@example.com'},
  'preferences': {'theme': 'dark', 'language': 'en'},
});
```

### Hybrid Multi-Modal

```dart
final hybrid = HybridMultiModalAdapter(
  textAdapter: geminiAdapter,
  imageAdapter: clipAdapter,
  dimensions: 512,
);

// Use appropriate adapter for each type
final embedding = await hybrid.embedText('hello');
final imageEmb = await hybrid.embedImage(imageBytes);
```

---

## Agent Memory Types

Cognitive-inspired memory system with episodic, semantic, and procedural memory.

### Episodic Memory (Events/Experiences)

```dart
final agentMemory = AgentMemoryTypes(memoryGraph);

// Store an event
final id = await agentMemory.storeEpisodicMemory(
  content: 'User asked about weather in Paris',
  timestamp: DateTime.now(),
  location: 'Paris',
  participants: ['User', 'Agent'],
  emotionalValence: 0.8, // Positive interaction
);

// Retrieve by time
final memories = await agentMemory.getEpisodicMemories(
  startTime: DateTime.now().subtract(Duration(days: 7)),
  endTime: DateTime.now(),
);
```

### Semantic Memory (Facts/Knowledge)

```dart
// Store a fact
await agentMemory.storeSemanticMemory(
  content: 'The capital of France is Paris',
  category: 'geography',
  tags: ['france', 'capital', 'europe'],
  confidence: 0.95,
  source: 'Wikipedia',
);

// Query by category
final facts = await agentMemory.getSemanticMemories(
  category: 'geography',
  minConfidence: 0.9,
);
```

### Procedural Memory (Skills/Procedures)

```dart
// Store a procedure
final procId = await agentMemory.storeProceduralMemory(
  procedure: 'How to make coffee',
  steps: [
    '1. Boil water',
    '2. Add coffee grounds',
    '3. Pour water over grounds',
    '4. Wait 4 minutes',
    '5. Press plunger',
  ],
  skill: 'coffee_making',
);

// Update based on execution
await agentMemory.updateProceduralProficiency(
  memoryId: procId,
  success: true, // Execution was successful
);
```

### Working Memory (Temporary)

```dart
// Store temporary context
await agentMemory.storeWorkingMemory(
  content: 'Current conversation context',
  ttl: Duration(hours: 1),
  priority: 8,
);

// Clean up expired
final expired = await agentMemory.cleanupWorkingMemory();
```

### Memory Statistics

```dart
final stats = await agentMemory.getStats();
print(stats);
// Memory Type Statistics:
//   Episodic: 150
//   Semantic: 500
//   Procedural: 30
//   Working: 5
//   Total: 685
```

---

## Privacy Features

Advanced privacy protection with PII detection, anonymization, and differential privacy.

### PII Detection and Masking

```dart
final privacy = PrivacyFeatures(memoryGraph);

// Detect PII
final detected = await privacy.piiDetector.detectPII(
  'Contact john@example.com or call 555-123-4567',
);
// Found: email, phone

// Mask PII
final masked = await privacy.maskPII(
  'My SSN is 123-45-6789',
  maskChar: '[REDACTED]',
);
// Result: "My SSN is [REDACTED]"

// Store with automatic masking
final id = await privacy.storeWithPIIMasking(
  content: 'Email me at alice@example.com',
  type: 'user_request',
);
```

### Anonymization

```dart
// Anonymize a specific node
await privacy.anonymizeNode(nodeId);

// Apply k-anonymity
await privacy.applyKAnonymity(
  k: 5,
  quasiIdentifiers: ['type', 'location', 'age_group'],
);
```

### Differential Privacy

```dart
// Add noise to embeddings for privacy
final noisyEmbedding = await privacy.applyDifferentialPrivacy(
  embedding: originalEmbedding,
  epsilon: 1.0, // Privacy budget
  sensitivity: 1.0,
);
```

### Privacy Audit

```dart
final report = await privacy.generateAuditReport();
print(report);
// Privacy Audit Report:
//   Total Nodes: 1000
//   Anonymized: 150 (15.0%)
//   With PII: 45 (4.5%)
//   Encrypted: 800 (80.0%)
```

### GDPR Compliance

```dart
// Right to be forgotten
final deleted = await privacy.rightToBeForgotten(
  userId: 'user123',
  includeRelated: true,
);
print('Deleted $deleted records');
```

---

## Best Practices

### 1. Performance Optimization

```dart
// Use caching
final cache = EmbeddingsCache(maxSize: 1000);

// Record metrics
final metrics = QualityMetrics(memoryGraph);

// Monitor performance
final report = await metrics.generateReport();
if (report.p95LatencyMs > 100) {
  // Investigate slow queries
}
```

### 2. Memory Management

```dart
// Periodic maintenance
final forgetting = ForgettingMechanism(memoryGraph);

// Run daily/weekly
await forgetting.autoForget(
  maxNodes: 50000,
  maxAgeDays: 180,
  minImportance: 0.2,
);
```

### 3. Privacy-First

```dart
// Always mask PII before storing
final privacy = PrivacyFeatures(memoryGraph);
final masked = await privacy.maskPII(userInput);

// Regular audits
final audit = await privacy.generateAuditReport();
if (audit.piiExposureRate > 0.05) {
  // Take action
}
```

### 4. Quality Monitoring

```dart
// Track every search
metrics.recordQuery(
  query: query,
  resultsReturned: results.length,
  latencyMs: latency,
);

// Weekly reports
final weekly = await metrics.generateReport(
  period: Duration(days: 7),
);
```

---

## Migration from v0.4.0

All new features are opt-in and don't break existing code:

```dart
// Existing code works unchanged
final memoryGraph = MemoryGraph(isar, embeddingsAdapter: adapter);

// Gradually adopt new features
final consolidation = MemoryConsolidation(memoryGraph);
final metrics = QualityMetrics(memoryGraph);
final cache = EmbeddingsCache();
```

---

## Examples

See the `example/` directory for complete working examples of each feature.

---

## Performance Tips

1. **Cache embeddings**: Can improve performance by 10-100x
2. **Use forgetting**: Keep memory size manageable (< 100k nodes recommended)
3. **Monitor metrics**: Identify slow queries and optimize
4. **Consolidate periodically**: Reduce redundancy by 20-40%
5. **Use appropriate re-rankers**: Cross-encoder for precision, BM25 for speed

---

## Support

For issues or questions about advanced features:
- GitHub Issues: https://github.com/iberi22/isar_agent_memory/issues
- Documentation: https://pub.dev/packages/isar_agent_memory
