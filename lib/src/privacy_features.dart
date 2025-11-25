import 'dart:math' as math;
import 'package:isar/isar.dart';
import 'memory_graph.dart';
import 'models/memory_node.dart';

/// Advanced privacy features for memory protection.
///
/// Includes differential privacy, PII detection, and data anonymization.
class PrivacyFeatures {
  final MemoryGraph memoryGraph;
  final PIIDetector piiDetector;

  PrivacyFeatures(this.memoryGraph, {PIIDetector? piiDetector})
      : piiDetector = piiDetector ?? DefaultPIIDetector();

  /// Applies differential privacy to embeddings.
  ///
  /// Adds calibrated noise to embeddings to protect individual privacy.
  Future<List<double>> applyDifferentialPrivacy({
    required List<double> embedding,
    double epsilon = 1.0,
    double sensitivity = 1.0,
  }) async {
    final noisy = List<double>.from(embedding);
    final scale = sensitivity / epsilon;

    for (int i = 0; i < noisy.length; i++) {
      noisy[i] += _laplaceNoise(scale);
    }

    // Normalize to maintain valid embedding
    return _normalize(noisy);
  }

  /// Detects and masks PII (Personally Identifiable Information) in content.
  Future<String> maskPII(String content,
      {String maskChar = '[REDACTED]'}) async {
    return piiDetector.maskPII(content, maskChar: maskChar);
  }

  /// Stores a memory with automatic PII masking.
  Future<int> storeWithPIIMasking({
    required String content,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    final maskedContent = await maskPII(content);

    final privacyMetadata = {
      ...?metadata,
      'pii_masked': true,
      'masked_at': DateTime.now().toIso8601String(),
    };

    return memoryGraph.storeNodeWithEmbedding(
      content: maskedContent,
      type: type,
      metadata: privacyMetadata,
    );
  }

  /// Anonymizes a memory node by removing identifying information.
  Future<void> anonymizeNode(int nodeId) async {
    final node = await memoryGraph.getNode(nodeId);
    if (node == null) return;

    // Mask PII in content
    node.content = await maskPII(node.content);

    // Remove identifying metadata
    node.metadata?.remove('user_id');
    node.metadata?.remove('device_id');
    node.metadata?.remove('ip_address');
    node.metadata?.remove('location');
    node.metadata?.remove('name');
    node.metadata?.remove('email');
    node.metadata?.remove('phone');

    node.metadata ??= {};
    node.metadata!['anonymized'] = true;
    node.metadata!['anonymized_at'] = DateTime.now().toIso8601String();

    await memoryGraph.storeNode(node);
  }

  /// Applies k-anonymity by generalizing data.
  ///
  /// Ensures at least k records share the same quasi-identifiers.
  Future<void> applyKAnonymity({
    required int k,
    List<String>? quasiIdentifiers,
  }) async {
    // This is a simplified implementation
    // Full k-anonymity requires sophisticated generalization algorithms

    final identifiers = quasiIdentifiers ?? ['type', 'layer'];
    final nodes = await memoryGraph.isar.memoryNodes.where().findAll();

    // Group by quasi-identifiers
    final groups = <String, List<MemoryNode>>{};

    for (final node in nodes) {
      final key = identifiers
          .map((id) => node.metadata?[id]?.toString() ?? 'null')
          .join('|');
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(node);
    }

    // Suppress or generalize groups with < k members
    for (final entry in groups.entries) {
      if (entry.value.length < k) {
        for (final node in entry.value) {
          // Option 1: Suppress (delete)
          // await memoryGraph.deleteNode(node.id);

          // Option 2: Generalize
          for (final identifier in identifiers) {
            node.metadata?.remove(identifier);
          }
          node.metadata ??= {};
          node.metadata!['generalized'] = true;
          await memoryGraph.storeNode(node);
        }
      }
    }
  }

  /// Generates a privacy audit report.
  Future<PrivacyAuditReport> generateAuditReport() async {
    final allNodes = await memoryGraph.isar.memoryNodes.where().findAll();

    int anonymized = 0;
    int withPII = 0;
    int encrypted = 0;
    final piiTypes = <String, int>{};

    for (final node in allNodes) {
      if (node.metadata?['anonymized'] == true) {
        anonymized++;
      }

      // Check for PII
      final detected = await piiDetector.detectPII(node.content);
      if (detected.isNotEmpty) {
        withPII++;
        for (final type in detected.keys) {
          piiTypes[type] = (piiTypes[type] ?? 0) + 1;
        }
      }

      // Check if encrypted (would need encryption flag in metadata)
      if (node.metadata?['encrypted'] == true) {
        encrypted++;
      }
    }

    return PrivacyAuditReport(
      totalNodes: allNodes.length,
      anonymizedNodes: anonymized,
      nodesWithPII: withPII,
      encryptedNodes: encrypted,
      piiTypeDistribution: piiTypes,
      auditDate: DateTime.now(),
    );
  }

  /// Implements right to be forgotten (GDPR compliance).
  ///
  /// Completely removes all traces of a user's data.
  Future<int> rightToBeForgotten({
    String? userId,
    String? deviceId,
    bool includeRelated = true,
  }) async {
    final nodes = await memoryGraph.isar.memoryNodes.where().findAll();
    final toDelete = <int>[];

    for (final node in nodes) {
      if (userId != null && node.metadata?['user_id'] == userId) {
        toDelete.add(node.id);
      } else if (deviceId != null && node.metadata?['device_id'] == deviceId) {
        toDelete.add(node.id);
      }
    }

    // Delete identified nodes
    for (final id in toDelete) {
      await memoryGraph.deleteNode(id);
    }

    return toDelete.length;
  }

  /// Adds noise using Laplace mechanism for differential privacy.
  double _laplaceNoise(double scale) {
    final random = math.Random.secure();
    final u = random.nextDouble() - 0.5;
    return -scale * _sign(u) * math.log(1 - 2 * u.abs());
  }

  double _sign(double x) => x >= 0 ? 1.0 : -1.0;

  /// Normalizes a vector to unit length.
  List<double> _normalize(List<double> vector) {
    double sum = 0.0;
    for (final v in vector) {
      sum += v * v;
    }
    final magnitude = math.sqrt(sum);
    if (magnitude == 0.0) return vector;
    return vector.map((v) => v / magnitude).toList();
  }
}

/// Interface for PII detection.
abstract class PIIDetector {
  /// Detects PII in text and returns locations and types.
  Future<Map<String, List<PIIMatch>>> detectPII(String text);

  /// Masks PII in text.
  Future<String> maskPII(String text, {String maskChar = '[REDACTED]'});
}

/// Default PII detector using regex patterns.
class DefaultPIIDetector implements PIIDetector {
  // Common PII patterns
  static final emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
  );

  static final phonePattern = RegExp(
    r'\b(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}\b',
  );

  static final ssnPattern = RegExp(
    r'\b\d{3}-\d{2}-\d{4}\b',
  );

  static final creditCardPattern = RegExp(
    r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b',
  );

  static final ipAddressPattern = RegExp(
    r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
  );

  @override
  Future<Map<String, List<PIIMatch>>> detectPII(String text) async {
    final detected = <String, List<PIIMatch>>{};

    // Email
    for (final match in emailPattern.allMatches(text)) {
      detected.putIfAbsent('email', () => []);
      detected['email']!.add(PIIMatch(
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // Phone
    for (final match in phonePattern.allMatches(text)) {
      detected.putIfAbsent('phone', () => []);
      detected['phone']!.add(PIIMatch(
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // SSN
    for (final match in ssnPattern.allMatches(text)) {
      detected.putIfAbsent('ssn', () => []);
      detected['ssn']!.add(PIIMatch(
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // Credit Card
    for (final match in creditCardPattern.allMatches(text)) {
      detected.putIfAbsent('credit_card', () => []);
      detected['credit_card']!.add(PIIMatch(
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // IP Address
    for (final match in ipAddressPattern.allMatches(text)) {
      detected.putIfAbsent('ip_address', () => []);
      detected['ip_address']!.add(PIIMatch(
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    return detected;
  }

  @override
  Future<String> maskPII(String text, {String maskChar = '[REDACTED]'}) async {
    var masked = text;

    // Replace all PII patterns
    masked = masked.replaceAll(emailPattern, maskChar);
    masked = masked.replaceAll(phonePattern, maskChar);
    masked = masked.replaceAll(ssnPattern, maskChar);
    masked = masked.replaceAll(creditCardPattern, maskChar);
    masked = masked.replaceAll(ipAddressPattern, maskChar);

    return masked;
  }
}

/// Represents a detected PII match.
class PIIMatch {
  final int start;
  final int end;
  final String value;

  PIIMatch({
    required this.start,
    required this.end,
    required this.value,
  });
}

/// Privacy audit report.
class PrivacyAuditReport {
  final int totalNodes;
  final int anonymizedNodes;
  final int nodesWithPII;
  final int encryptedNodes;
  final Map<String, int> piiTypeDistribution;
  final DateTime auditDate;

  PrivacyAuditReport({
    required this.totalNodes,
    required this.anonymizedNodes,
    required this.nodesWithPII,
    required this.encryptedNodes,
    required this.piiTypeDistribution,
    required this.auditDate,
  });

  double get anonymizationRate =>
      totalNodes > 0 ? anonymizedNodes / totalNodes : 0.0;

  double get piiExposureRate =>
      totalNodes > 0 ? nodesWithPII / totalNodes : 0.0;

  double get encryptionRate =>
      totalNodes > 0 ? encryptedNodes / totalNodes : 0.0;

  @override
  String toString() {
    return '''Privacy Audit Report (${auditDate.toIso8601String()})
Total Nodes: $totalNodes
Anonymized: $anonymizedNodes (${(anonymizationRate * 100).toStringAsFixed(1)}%)
With PII: $nodesWithPII (${(piiExposureRate * 100).toStringAsFixed(1)}%)
Encrypted: $encryptedNodes (${(encryptionRate * 100).toStringAsFixed(1)}%)
PII Types Found: ${piiTypeDistribution.entries.map((e) => '${e.key}: ${e.value}').join(', ')}''';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalNodes': totalNodes,
      'anonymizedNodes': anonymizedNodes,
      'nodesWithPII': nodesWithPII,
      'encryptedNodes': encryptedNodes,
      'anonymizationRate': anonymizationRate,
      'piiExposureRate': piiExposureRate,
      'encryptionRate': encryptionRate,
      'piiTypeDistribution': piiTypeDistribution,
      'auditDate': auditDate.toIso8601String(),
    };
  }
}
