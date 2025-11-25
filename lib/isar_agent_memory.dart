// isar_agent_memory
//
// Universal, local-first cognitive memory package for LLMs and AI agents.
// Graph-based, explainable, LLM-agnostic. Inspired by Cognee/Graphiti.

export 'src/models/memory_node.dart';
export 'src/models/memory_edge.dart';
export 'src/models/memory_embedding.dart';
export 'src/models/degree.dart';
export 'src/memory_graph.dart';
export 'src/embeddings_adapter.dart';
export 'src/gemini_embeddings_adapter.dart';
export 'src/fallback_embeddings_adapter.dart';
export 'src/on_device_embeddings_adapter.dart';
export 'src/vector_index.dart';
export 'src/vector_index_objectbox.dart';
export 'src/hierarchical_graph.dart';
export 'src/llm_adapter.dart';
export 'src/reranking_strategy.dart';
export 'src/rerankers/bm25_reranker.dart';
export 'src/rerankers/diversity_reranker.dart';
export 'src/rerankers/mmr_reranker.dart';
export 'src/rerankers/recency_reranker.dart';
export 'src/rerankers/cross_encoder_reranker.dart';
export 'src/sync/sync_manager.dart';
export 'src/sync/sync_backend.dart';
export 'src/sync/firebase_sync_backend.dart';
export 'src/sync/websocket_sync_backend.dart';
export 'src/sync/cross_device_sync_manager.dart';

// Advanced features (v0.5.0)
export 'src/memory_consolidation.dart';
export 'src/embeddings_cache.dart';
export 'src/quality_metrics.dart';
export 'src/forgetting_mechanism.dart';
export 'src/dynamic_layers.dart';
export 'src/multi_modal_adapter.dart';
export 'src/agent_memory_types.dart';
// export 'src/privacy_features.dart'; // TODO: Depends on other implementations
