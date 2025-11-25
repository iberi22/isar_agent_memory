import 'dart:collection';
import 'dart:typed_data';

/// LRU (Least Recently Used) cache for embeddings.
///
/// Caches embeddings to avoid recomputation for frequently used content.
class EmbeddingsCache {
  final int maxSize;
  final LinkedHashMap<String, CachedEmbedding> _cache;
  int _hits = 0;
  int _misses = 0;

  EmbeddingsCache({this.maxSize = 1000})
      : _cache = LinkedHashMap<String, CachedEmbedding>();

  /// Gets an embedding from the cache.
  ///
  /// Returns null if not found.
  Float32List? get(String content) {
    final cached = _cache.remove(content);
    if (cached != null) {
      _hits++;
      // Move to end (most recently used)
      _cache[content] = cached;
      cached.lastAccessTime = DateTime.now();
      cached.accessCount++;
      return cached.embedding;
    }
    _misses++;
    return null;
  }

  /// Puts an embedding in the cache.
  void put(String content, Float32List embedding) {
    if (_cache.containsKey(content)) {
      _cache.remove(content);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used
      _cache.remove(_cache.keys.first);
    }

    _cache[content] = CachedEmbedding(
      embedding: embedding,
      cachedAt: DateTime.now(),
      lastAccessTime: DateTime.now(),
    );
  }

  /// Checks if a content key is in the cache.
  bool contains(String content) => _cache.containsKey(content);

  /// Clears the entire cache.
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Gets cache statistics.
  CacheStats getStats() {
    return CacheStats(
      size: _cache.length,
      maxSize: maxSize,
      hits: _hits,
      misses: _misses,
      hitRate: _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0,
    );
  }

  /// Removes expired entries from the cache.
  ///
  /// [maxAge]: Maximum age of cache entries in hours.
  void evictExpired({int maxAge = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: maxAge));
    _cache.removeWhere((key, value) => value.cachedAt.isBefore(cutoff));
  }

  /// Gets the most frequently accessed entries.
  List<MapEntry<String, CachedEmbedding>> getMostAccessed({int limit = 10}) {
    final entries = _cache.entries.toList()
      ..sort((a, b) => b.value.accessCount.compareTo(a.value.accessCount));
    return entries.take(limit).toList();
  }
}

/// Represents a cached embedding with metadata.
class CachedEmbedding {
  final Float32List embedding;
  final DateTime cachedAt;
  DateTime lastAccessTime;
  int accessCount;

  CachedEmbedding({
    required this.embedding,
    required this.cachedAt,
    required this.lastAccessTime,
    this.accessCount = 1,
  });

  /// Age of the cache entry in hours.
  double get ageInHours => DateTime.now().difference(cachedAt).inMinutes / 60.0;

  /// Time since last access in minutes.
  double get minutesSinceLastAccess =>
      DateTime.now().difference(lastAccessTime).inMinutes.toDouble();
}

/// Statistics about cache performance.
class CacheStats {
  final int size;
  final int maxSize;
  final int hits;
  final int misses;
  final double hitRate;

  CacheStats({
    required this.size,
    required this.maxSize,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  @override
  String toString() {
    return 'CacheStats(size: $size/$maxSize, hits: $hits, misses: $misses, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'maxSize': maxSize,
      'hits': hits,
      'misses': misses,
      'hitRate': hitRate,
      'utilization': size / maxSize,
    };
  }
}
