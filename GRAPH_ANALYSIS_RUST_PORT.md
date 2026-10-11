# isar_agent_memory → Rust Port: Graph Pattern Analysis

**Date:** 2026-07-28  
**Target:** `gestalt_core/src/memory/` (new module)  
**Source:** `isar_agent_memory` v0.6.0-dev (Dart, IsarDB + ObjectBox)

---

## 1. Design Patterns Extracted

### 1.1 Graph Data Model

```
MemoryNode ──→[edge:relation]──→ MemoryNode
     │                                 │
     ├─ content: String                ├─ fromNodeId
     ├─ type: String?                  ├─ toNodeId
     ├─ layer: int                     ├─ relation: String
     ├─ embedding: MemoryEmbedding     ├─ weight: f64?
     ├─ degree: Degree                 ├─ metadata: Map?
     └─ metadata: Map?                 └─ (sync fields)
```

**MemoryNode** — the vertex. Each node carries:
- **Identity:** UUID (global) + auto-increment ID (local). UUID enables multi-device sync.
- **Content:** The actual memory text (can be raw message, summarized fact, concept).
- **Type tag:** `'fact'`, `'message'`, `'goal'`, `'summary'` — used for filtering.
- **Layer (0..N):** HiRAG hierarchy — layer 0 is raw data, higher layers are LLM-generated summaries.
- **Embedding:** A `MemoryEmbedding` struct wrapping `List<double>` + provider string + dimension count. Used for semantic search.
- **Degree:** Activation metrics — `lastAccessed`, `frequency` (count), `importance` (0.0–1.0). Used for relevance scoring and forgetting curves.
- **Metadata:** Extensible `Map<String, dynamic>` for arbitrary tags, session IDs, etc.
- **Sync fields:** `version`, `deviceId`, `isDeleted` (tombstone), `modifiedAt` (LWW timestamp).

**MemoryEdge** — the directed relationship. Each edge stores:
- **fromNodeId / toNodeId:** Int references to the local MemoryNode.id.
- **relation:** Labeled string — `'cause'`, `'context'`, `'response'`, `'similarity'`, `'summary_of'`, `'part_of'`.
- **weight:** Optional `f64` for strength/importance of the connection.
- **Sync fields** (same pattern as node).
- **Metadata** (extensible).

**Degree** — embedded activation model:
```dart
class Degree {
  DateTime? lastAccessed;
  int frequency;        // access count
  double importance;    // 0.0–1.0 intrinsic importance
}
```

### 1.2 Graph CRUD (MemoryGraph)

| Operation | Pattern | Notes |
|-----------|---------|-------|
| `storeNodeWithEmbedding` | content → embed → dedup check → store → vector index | Dedup via cosine distance threshold (default 0.05) |
| `storeNode` | persist node + sync vector index | Two-phase: DB first, index second (best-effort) |
| `storeEdge` | persist edge to DB | Simple Isar write |
| `getNode` / `deleteNode` | read/delete from DB + index | Delete also removes from vector index |
| `getEdgesForNode` | query incoming + outgoing edges | Two filter queries merged |
| `semanticSearch` | vector index → fallback linear scan L2 | Plugged VectorIndex trait; ObjectBox HNSW default |
| `hybridSearch` | vector (α) + text FTS (1-α) weighted fusion | Reciprocal Rank Fusion via simple weighted sum |
| `explainRecall` | distance + activation + BFS path trace | Transparency for LLM agents |
| `BFS from roots` | loads ALL edges into memory, BFS | O(V+E) at query time; OK for moderate graphs |

**Key architectural insight:** The graph is *not* stored as adjacency lists. Edges are independent rows in a separate DB table. Traversals are explicit queries — there is no pointer-chasing. This means the entire graph can be persisted relationally while still supporting graph algorithms.

### 1.3 Vector Index Abstraction

```dart
abstract class VectorIndex {
  Future<void> load();
  Future<void> addDocument(String id, String text, Float32List vector);
  Future<void> removeDocument(String id);
  Future<List<SearchResult>> search(Float32List query, {int topK});
  Future<void> clear();
  String get provider;
}
```

- **Default impl:** ObjectBox (HNSW, local, on-device).
- **Fallback:** Linear scan (L2 distance) when index fails or dims mismatch.
- The `VectorIndex` is a port — can swap to any backend.

### 1.4 HiRAG Pattern (HierarchicalMemoryGraph)

```
Layer 2:  [Summary-of-everything]
             ↑ summary_of
Layer 1:  [Summary-A] ← part_of → [Summary-B]
             ↑ summary_of           ↑ summary_of
Layer 0:  [node1] [node2] [node3]  [node4] [node5]  (raw facts)
```

- Nodes have a `layer` integer field.
- **summary_of** edges: child → parent (child is the *subject*, summary_of points upward).
- **part_of** edges: summary → child (part-of relationship for decomposition).
- `autoSummarizeLayer`: groups all nodes in a layer, calls LLM to summarize, creates summary node one layer up, links via edges.
- `multiHopSearch`: semantic search on layer 0 → traverse `summary_of` edges upward for context.
- Pattern inspired by GraphRAG / Cognee / Microsoft's hierarchical RAG.

### 1.5 Sync-Ready Entity Pattern

Every persisted entity follows this template:
```
- uuid: String?            // globally unique (v4)
- version: String?         // hash or monotonic counter
- deviceId: String?        // origin device
- isDeleted: bool          // tombstone for sync deletion
- modifiedAt: DateTime?    // LWW conflict resolution
```

This is a **CRDT-lite** pattern: offline-first, LWW merge, soft-deletes.

---

## 2. Rust Ecosystem Evaluation

### 2.1 petgraph (v0.6)

**Verdict: YES — use for in-memory graph operations.**

| Feature | petgraph | Isar approach |
|---------|----------|---------------|
| Directed graph | `DiGraph<N, E>` | Manual edge table |
| BFS/DFS | Built-in `Bfs`, `Dfs` | Manual queue BFS |
| Pathfinding | No (no Dijkstra/A* in core) | Manual |
| Persistence | None (in-memory only) | Isar persistence |
| Node weights | `N: Clone` generic | Isar collection |
| Edge weights | `E: Clone` generic | Isar collection |

**Pros:** Zero-cost abstractions, stable, widely used, supports serde, excellent for algorithm-heavy operations (degree calc, centrality, BFS path tracing which the Dart code does manually).

**Cons:** No persistence — you need a separate storage layer. `petgraph` uses `NodeIndex` (internal usize), so you must maintain a `HashMap<ExternalId, NodeIndex>` for lookups. Not great for very large graphs (everything in RAM).

**For Gestalt's scale** (agent memory graphs, not web-scale): petgraph in-memory + SurrealDB for persistence is the right split.

### 2.2 fast-graph (slotmap-based)

An alternative to petgraph using `slotmap` for O(1) removals. Slightly faster for dynamic mutation patterns. Serde support optional. If frequent deletions are a concern, this is worth considering — but petgraph is more battle-tested and has better algorithm support.

### 2.3 CozoDB

**Verdict: Overkill for now, but worth watching.**

- Embeddable (like SQLite), written in Rust, uses Datalog.
- Relational + graph + vector search in one DB.
- Supports recursive graph traversal in the query language itself.
- Backends: In-memory, SQLite, RocksDB, Sled.

**Why not now:** Adds a 3rd DB backend (gestalt_core already has SurrealDB). Datalog, while powerful, is another DSL to learn. CozoDB's vector search is less mature than SurrealDB's.

**When to consider:** If graph traversal complexity grows (e.g., multi-hop KNN, community detection), CozoDB's Datalog makes those queries trivial vs. doing them in application code.

### 2.4 OverGraph (new, 2026)

Marketed as "embedded graph DB with built-in vector search, sub-microsecond reads." Very new — library/API maturity unknown. Could be ideal long-term but risky for production today.

### 2.5 SurrealDB (already in gestalt_core)

gestalt_core already depends on `surrealdb = "2.6.1"` with `kv-mem` feature. It supports:
- Relational tables (for nodes, edges)
- Vector search (`vector::similarity::cosine()`)
- Graph-like queries via `->relation->`
- Embedded (in-memory, rocksdb, surrealkv)

**This is the path of least resistance.** SurrealDB can serve as both the relational store (nodes + edges tables) and the vector index — replacing both Isar and ObjectBox from the Dart original.

### 2.6 Recommendation Matrix

| Layer | Library | Role |
|-------|---------|------|
| **In-memory graph algorithms** | `petgraph` 0.6 | BFS, pathfinding, degree calc, centrality |
| **Graph persistence** | `SurrealDB` (already in deps) | Persistent storage for nodes & edges |
| **Vector search** | `SurrealDB` built-in | Cosine similarity top-K, replacing ObjectBox |
| **Embedding generation** | `EmbeddingModel` trait (already exists) | Text → vector via configurable provider |
| **Serialization** | `serde` + `serde_json` (already in deps) | Node/edge ↔ JSON for API/context |
| **UUID generation** | `uuid` (already in deps, v1.15 with v4) | Global IDs for sync |
| **Async runtime** | `tokio` (already in deps) | All operations async |

---

## 3. Rust Implementation Proposal for gestalt_core

### 3.1 Module Layout

```
gestalt_core/src/memory/
├── mod.rs              # Module declaration + re-exports
├── node.rs             # MemoryNode struct
├── edge.rs             # MemoryEdge struct
├── degree.rs           # Degree activation model
├── graph.rs            # MemoryGraph — CRUD + search + pathfinding
├── hierarchical.rs     # HiRAG: layer summarization, multi-hop search
├── store.rs            # GraphStore trait + SurrealDbGraph impl
└── types.rs            # Relation enum, Layer type, etc.
```

### 3.2 Core Structs

```rust
// === memory/node.rs ===
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryNode {
    pub id: Option<i64>,              // auto-increment local ID (SurrealDB record ID)
    pub uuid: String,                 // global UUID v4 for sync
    pub content: String,
    pub type_: Option<String>,        // 'fact', 'message', 'goal', 'summary', etc.
    pub layer: u32,                   // HiRAG hierarchical layer (0 = base)
    pub embedding: Option<MemoryEmbedding>,
    pub degree: Degree,
    pub metadata: HashMap<String, Value>,
    // Sync
    pub version: Option<String>,
    pub device_id: Option<String>,
    pub is_deleted: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub modified_at: DateTime<Utc>,
}

// === memory/edge.rs ===
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryEdge {
    pub id: Option<i64>,
    pub uuid: String,
    pub from_node_id: i64,
    pub to_node_id: i64,
    pub relation: RelationKind,
    pub weight: Option<f64>,
    pub metadata: HashMap<String, Value>,
    // Sync
    pub version: Option<String>,
    pub device_id: Option<String>,
    pub is_deleted: bool,
    pub created_at: DateTime<Utc>,
    pub modified_at: DateTime<Utc>,
}

// === memory/types.rs ===
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum RelationKind {
    Cause,
    Context,
    Response,
    Similarity,
    SummaryOf,
    PartOf,
    Custom(String),
}

impl RelationKind {
    pub fn as_str(&self) -> &str { /* ... */ }
    pub fn from_str(s: &str) -> Self { /* ... */ }
}

// === memory/degree.rs ===
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Degree {
    pub last_accessed: Option<DateTime<Utc>>,
    pub frequency: u64,
    pub importance: f64,       // 0.0 – 1.0
}

impl Degree {
    pub fn new() -> Self {
        Self {
            last_accessed: None,
            frequency: 0,
            importance: 0.5,
        }
    }

    /// Recency score: decays from 1.0 to 0.0 over time
    pub fn recency_score(&self) -> f64 {
        match self.last_accessed {
            Some(t) => {
                let elapsed = (Utc::now() - t).num_hours() as f64;
                1.0 / (1.0 + elapsed / 24.0)
            }
            None => 0.0,
        }
    }

    /// Combined activation score for relevance ranking
    pub fn activation_score(&self) -> f64 {
        0.4 * self.recency_score()
            + 0.3 * (1.0 - 1.0 / (1.0 + self.frequency as f64))
            + 0.3 * self.importance
    }
}
```

### 3.3 GraphStore Port (Trait + SurrealDB Impl)

```rust
// === memory/store.rs ===
#[async_trait]
pub trait GraphStore: Send + Sync {
    // Node CRUD
    async fn store_node(&self, node: MemoryNode) -> Result<i64>;
    async fn get_node(&self, id: i64) -> Result<Option<MemoryNode>>;
    async fn delete_node(&self, id: i64) -> Result<bool>;
    async fn get_nodes_by_layer(&self, layer: u32) -> Result<Vec<MemoryNode>>;

    // Edge CRUD
    async fn store_edge(&self, edge: MemoryEdge) -> Result<i64>;
    async fn get_edges_for_node(&self, node_id: i64) -> Result<Vec<MemoryEdge>>;
    async fn delete_edge(&self, id: i64) -> Result<bool>;

    // Semantic search
    async fn semantic_search(
        &self,
        embedding: &[f32],
        top_k: usize,
        layer: Option<u32>,
    ) -> Result<Vec<(MemoryNode, f64)>>;

    // Bulk for BFS
    async fn all_nodes(&self) -> Result<Vec<MemoryNode>>;
    async fn all_edges(&self) -> Result<Vec<MemoryEdge>>;
}

// SurrealDB implementation
pub struct SurrealGraphStore {
    db: Surreal<Db>,           // or Any for engine-agnostic
    embedder: Arc<dyn EmbeddingModel>,
}

#[async_trait]
impl GraphStore for SurrealGraphStore {
    async fn store_node(&self, node: MemoryNode) -> Result<i64> {
        // UPSERT INTO memory_node (id, uuid, content, ...)
        // Also store embedding for vector search if present
    }

    async fn semantic_search(&self, embedding: &[f32], top_k: usize, layer: Option<u32>) -> Result<Vec<(MemoryNode, f64)>> {
        // SurrealQL: SELECT *, vector::similarity::cosine(embedding, $query) AS score
        // FROM memory_node WHERE embedding IS NOT NONE
        // (AND layer = $layer) ORDER BY score DESC LIMIT $top_k
    }

    // ... other methods
}
```

### 3.4 MemoryGraph Service (petgraph + GraphStore)

```rust
// === memory/graph.rs ===
pub struct MemoryGraph {
    store: Arc<dyn GraphStore>,
    embedder: Arc<dyn EmbeddingModel>,
}

impl MemoryGraph {
    /// Store a node with auto-generated embedding, with optional dedup
    pub async fn store_node_with_embedding(
        &self,
        content: &str,
        type_: Option<&str>,
        metadata: HashMap<String, Value>,
        deduplicate: bool,
    ) -> Result<i64> { /* embed → check dedup → store */ }

    /// BFS from root nodes to target (like Dart's _findPathsToNode)
    pub async fn find_paths_to_node(
        &self,
        target_id: i64,
        max_depth: usize,
    ) -> Result<Vec<Vec<i64>>> {
        // 1. Load all nodes + edges (via store)
        // 2. Build petgraph DiGraph
        // 3. Find root nodes (no incoming edges)
        // 4. BFS from each root using petgraph::Bfs
        // 5. Return paths
    }

    /// Hybrid search with weighted fusion
    pub async fn hybrid_search(
        &self,
        query: &str,
        top_k: usize,
        alpha: f64,     // 0.0 = text only, 1.0 = vector only
    ) -> Result<Vec<(MemoryNode, f64)>> {
        // 1. Vector search
        // 2. Text search (SurrealQL CONTAINS or FTS)
        // 3. Weighted score fusion
    }

    /// Explain why a node was recalled (transparency)
    pub async fn explain_recall(
        &self,
        node_id: i64,
        query_embedding: Option<&[f32]>,
    ) -> Result<String> {
        // Get node + edges + degree info + BFS paths
    }
}
```

### 3.5 HiRAG Layer (hierarchical.rs)

```rust
// === memory/hierarchical.rs ===
pub struct HierarchicalMemoryGraph {
    graph: Arc<MemoryGraph>,
    llm: Arc<dyn LLMAdapter>,    // or existing LLM provider trait
}

impl HierarchicalMemoryGraph {
    /// Summarize all nodes in a layer using LLM, create summary + edges
    pub async fn auto_summarize_layer(
        &self,
        layer_index: u32,
    ) -> Result<i64> {
        // 1. Fetch all nodes in layer
        // 2. Join content
        // 3. Call LLM
        // 4. Store summary node in layer+1
        // 5. Create summary_of + part_of edges
    }

    /// Multi-hop search: semantic search → traverse summary_of edges
    pub async fn multi_hop_search(
        &self,
        query_embedding: Vec<f32>,
        max_hops: usize,
        top_k: usize,
    ) -> Result<Vec<(MemoryNode, Vec<MemoryNode>)>> {
        // 1. Semantic search on layer 0
        // 2. For each result, follow summary_of edges up to max_hops
        // 3. Return (base_node, [parents]) pairs
    }
}
```

### 3.6 Integration Points with Existing gestalt_core

| Existing Asset | Integration |
|----------------|-------------|
| `domain::rag::embeddings::EmbeddingModel` | Used by MemoryGraph for text→vector |
| `ports::outbound::repo_manager::VectorDb` | SurrealGraphStore implements this for existing consumers |
| `context::memory::MemoryStore` (RwLock<HashMap>) | Upgrade to graph-backed store behind the same Fact API |
| `domain::memory::Fact` | Can be a thin projection over MemoryNode (type = 'fact') |
| `adapters::persistence::surreal_db::SurrealDbAdapter` | Reuse `Surreal<Db>` connection; add graph-specific queries |
| `surrealdb` (already in Cargo.toml) | Zero new top-level dependencies for persistence |

---

## 4. petgraph Sufficiency Analysis

**Is petgraph enough for what the Dart code does? YES.**

The Dart `_findPathsToNode` is a manual BFS that:
1. Loads all nodes + edges into memory
2. Computes roots by set difference (all node IDs − all `toNodeId` IDs)
3. BFS from each root with depth limit

With petgraph:
```rust
use petgraph::graph::DiGraph;
use petgraph::visit::Bfs;
use petgraph::prelude::*;

// Build graph
let mut g = DiGraph::<i64, &str>::new();
let mut indices = HashMap::new();
for node in &all_nodes {
    indices.insert(node.id, g.add_node(node.id));
}
for edge in &all_edges {
    if let (Some(&from), Some(&to)) = (indices.get(&edge.from_node_id), indices.get(&edge.to_node_id)) {
        g.add_edge(from, to, edge.relation.as_str());
    }
}

// Find roots
let roots: Vec<_> = g.node_indices()
    .filter(|&n| g.neighbors_directed(n, Incoming).count() == 0)
    .collect();

// BFS from each root
for root in roots {
    let mut bfs = Bfs::new(&g, root);
    while let Some(nx) = bfs.next(&g) {
        if g[nx] == target_id { /* found */ }
    }
}
```

**What petgraph does NOT cover:**
- Persistence (handled by SurrealDB / GraphStore trait)
- Semantic/vector search (handled by SurrealDB or separate vector index)
- Embedding generation (handled by EmbeddingModel trait)
- Degree activation math (pure computation, no library needed)

**Verdict: petgraph + SurrealDB is the correct split.** petgraph handles the graph algorithms (BFS, degree calculation, centrality) in-memory, while SurrealDB provides persistence and vector search. No need for CozoDB, OverGraph, or any specialized graph database at this scale.

---

## 5. Dependency Additions

Add to `gestalt_core/Cargo.toml`:

```toml
petgraph = "0.6"                    # In-memory graph algorithms
```

That's it. Everything else is already present:
- `serde` / `serde_json` ✅
- `uuid` (v4) ✅
- `chrono` ✅
- `surrealdb` (with `kv-mem`) ✅
- `tokio` ✅
- `async-trait` ✅
- `anyhow` / `thiserror` ✅

No new heavy dependencies. petgraph is a compact, pure-Rust crate with no external C libs.

---

## 6. Migration Path

```
Phase 1 ── Add petgraph + define MemoryNode/MemoryEdge structs
             → New domain types, no existing code changed

Phase 2 ── Implement GraphStore trait on top of SurrealDB
             → Reuse existing Surreal<Db> connection
             → Auto-migrate existing Facts into graph nodes

Phase 3 ── Implement MemoryGraph service with petgraph algorithms
             → BFS, pathfinding, degree calc
             → Replace hand-rolled BFS in domain::memory

Phase 4 ── HiRAG layer (auto-summarize, multi-hop search)
             → New capability, no breaking changes

Phase 5 ── Upgrade context::memory::MemoryStore to use graph backend
             → Backward compatible: Fact API unchanged, backed by graph
```

---

## 7. Risks & Trade-offs

| Risk | Mitigation |
|------|------------|
| petgraph loads entire graph to RAM for BFS | Acceptable at agent-memory scale (<1M nodes); add pagination if needed later |
| SurrealDB vector search is O(n) without ANN index | SurrealDB 2.x adds HNSW; for now linear scan is same as Dart's fallback |
| Sync pattern (UUID + version + LWW) not yet used in Gestalt | Introduce as new capability — existing Facts don't need it |
| petgraph has no built-in pathfinding (Dijkstra, A*) | Not needed for current use case; add `pathfinding` crate if required later |
| Two layers (petgraph in-memory + SurrealDB persistent) could drift | Single-writer pattern: SurrealDB is source of truth, petgraph is ephemeral query cache |

---

## 8. Conclusion

**Use petgraph for in-memory graph algorithms + SurrealDB for persistence.** This two-layer approach maps exactly to what the Dart code does (Isar for persistence + in-memory BFS), and both libraries are already in the Rust ecosystem with gestalt_core already depending on SurrealDB.

The five design patterns extracted from `isar_agent_memory` — (1) labeled directed graph with vector search, (2) sync-ready CRDT-lite entities, (3) hierarchical RAG layers, (4) activation-based relevance, (5) pluggable vector backend — all translate cleanly to Rust using petgraph + SurrealDB + the existing EmbeddingModel trait.

**One new dependency: `petgraph = "0.6"`**. Everything else is already in gestalt_core's Cargo.toml.
